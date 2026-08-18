#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR

source ./.env

if [[ ! -d bin/clidriver ]]; then
  echo "bin/clidriver is missing - run ./15-install.sh first" 1>&2
  exit 1
fi

write-container-env

docker compose --project-directory container up -d db2

# First start creates the instance and the database and takes several minutes;
# the port listens long before either exists, so poll the log line instead.
start=$(date +%s)
TIMEOUT=900
while ! db2-is-ready; do
  elapsed=$(( $(date +%s) - start ))
  if [[ ${elapsed} -gt ${TIMEOUT} ]]; then
    echo "db2 did not finish setup within ${TIMEOUT}s - check: docker logs ${DB2}" 1>&2
    exit 1
  fi
  echo "waiting for db2 setup to complete (${elapsed}s)"
  sleep 10
done

# prove the database actually answers, not just that setup printed a line
db2-clp "connect to ${DB2_DBNAME}"

PRIMARY_IP=$(get-primary-ip)
echo
echo "db2 ${DB2_VERSION} ready: ${DB2_DBNAME} on port ${DB2_PORT}"
echo "dsn:      DATABASE=${DB2_DBNAME};HOSTNAME=${PRIMARY_IP};PORT=${DB2_PORT};PROTOCOL=TCPIP;UID=${DB2_INSTANCE};PWD=${DB2_PASSWORD};"
echo "clp:      docker exec -it ${DB2} su - ${DB2_INSTANCE}"
echo "clidriver: ${IBM_DB_HOME}"
