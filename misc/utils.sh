#!/usr/bin/env bash


function get-a-token() {
  local response=$(curl -s -H "Content-Type: application/json" \
  -d "{\"name\":\"${RANDOM}\"}" \
  -u ${GITEA_LP_USER}:${GITEA_LP_PASSWORD} http://$GITEA:3000/api/v1/users/lp/tokens)

  local token=$(echo $response | jq -r .sha1)
  printf ${token}
}

function repo-exists() {
  local token=$1
  local repo_name=$2

  result=$(
    curl -s -X 'GET' \
    "http://${GITEA}:3000/api/v1/repos/search?q=${repo_name}" \
    -H 'accept: application/json'
  )

  data=$(echo $result | yq -r '.data[]')

  [[ ! -z "$data"  ]]

}

function create-repo() {
  local token=$1
  local repo_name=$2

  #curl -X POST "http://${GITEA}:3000/api/v1/user/repos?access_token=$token" \
  curl -X POST "http://${GITEA}:3000/api/v1/user/repos" \
    -u ${GITEA_LP_USER}:${GITEA_LP_PASSWORD} \
    -H "accept: application/json" \
    -H "content-type: application/json" \
    -d "{\"name\":\"$repo_name\" }"
}

#function kf() {
#  k get $(kubectl api-resources | grep -i flux | cut -d' ' -f1 | tr '\n' ',' | sed 's/,$//g') -A;
#}
#export -f kf

get-primary-ip() {
  # no hostname -I on macOS
  if [ "$(uname -o)" == Darwin ]; then
    local PRIMARY_IP=$(ifconfig en0 | awk '/inet / {print $2; }' | egrep -v 127.0.0.1 | head -1)
  else
    local PRIMARY_IP=$(hostname -I | cut -d " " -f1)
  fi
  printf ${PRIMARY_IP}
}

function cluster-exists() {
  local cluster_name=$1
  #local K3D=$(get-k3d-path)
  # ARGOCD_MOD_ROOT, not BASEDIR: .env carries it as an absolute path, so the
  # helper also works when .env is sourced from an interactive shell.
  local K3D=${ARGOCD_MOD_ROOT}/bin/k3d

  # need a blank after name. Else prefix would work, too.
  COUNT=$(${K3D} cluster list | grep ^${cluster_name}\  | wc -l)
  if [[ $COUNT -eq 0 ]]; then
    # 1 = false
    return 1
  else
    # 0 = true
    return 0
  fi
}

export -f cluster-exists


### Db2 ###################################################################

# LD_LIBRARY_PATH lives here rather than in misc/env.tpl because envsubst
# mangles the ${VAR:+...} guard: it substitutes the inner reference away and
# leaves `${LD_LIBRARY_PATH:+:}` behind. utils.sh is appended to .env verbatim,
# so the guard survives. The case block keeps re-sourcing .env idempotent.
case ":${LD_LIBRARY_PATH:-}:" in
  *":${ARGOCD_MOD_ROOT}/bin/clidriver/lib:"*) ;;
  *) export LD_LIBRARY_PATH="${ARGOCD_MOD_ROOT}/bin/clidriver/lib${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}" ;;
esac

# container/.env feeds docker compose. Both 20-start-gitea.sh and
# 25-start-db2.sh write it in full, so either stage runs standalone: compose
# interpolates the whole file even when only one service is targeted.
function write-container-env() {
  cat << INNER > ${ARGOCD_MOD_ROOT}/container/.env
GITEA=${GITEA}
USER_UID=$(id -u)
USER_GID=$(id -g)
DB2=${DB2}
DB2_VERSION=${DB2_VERSION}
DB2_LICENSE=${DB2_LICENSE}
DB2_INSTANCE=${DB2_INSTANCE}
DB2_PASSWORD=${DB2_PASSWORD}
DB2_DBNAME=${DB2_DBNAME}
DB2_PORT=${DB2_PORT}
MSSQL=${MSSQL}
MSSQL_VERSION=${MSSQL_VERSION}
MSSQL_EULA=${MSSQL_EULA}
MSSQL_PID=${MSSQL_PID}
MSSQL_SA_PASSWORD=${MSSQL_SA_PASSWORD}
MSSQL_PORT=${MSSQL_PORT}
INNER
}
export -f write-container-env

# The Db2 entrypoint prints this once the instance and DBNAME are both up.
# It is the only reliable readiness signal - the port listens minutes earlier.
function db2-is-ready() {
  docker logs ${DB2} 2>&1 | grep -q 'Setup has completed'
}
export -f db2-is-ready

# Run a db2 CLP command as the instance owner.
function db2-clp() {
  docker exec ${DB2} su - ${DB2_INSTANCE} -c "db2 $*"
}
export -f db2-clp

### Microsoft SQL Server ##################################################

# Readiness is a successful login, not a log line: SQL Server prints "ready
# for client connections" while still applying the SA password, so a query
# issued on that signal fails with "Login failed for user 'sa'".
function mssql-is-ready() {
  docker exec ${MSSQL} /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -Q "SELECT 1" > /dev/null 2>&1
}
export -f mssql-is-ready

# Run a T-SQL batch as sa. The image ships sqlcmd under mssql-tools18, which
# defaults to an encrypted connection against a self-signed cert, hence -C.
function mssql-q() {
  docker exec ${MSSQL} /opt/mssql-tools18/bin/sqlcmd \
    -S localhost -U sa -P "${MSSQL_SA_PASSWORD}" -C -Q "$*"
}
export -f mssql-q
