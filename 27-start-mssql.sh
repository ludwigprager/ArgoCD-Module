#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR

source ./.env

write-container-env

# Create the data dir as the host user before compose does. Docker would
# create a missing bind-mount source as root, which the container - running as
# the host user - could not write to.
mkdir -p container/mssql-data

docker compose --project-directory container up -d mssql

start=$(date +%s)
TIMEOUT=300
while ! mssql-is-ready; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${MSSQL}$"; then
    echo "${MSSQL} stopped during setup - check: docker logs ${MSSQL}" 1>&2
    exit 1
  fi
  elapsed=$(( $(date +%s) - start ))
  if [[ ${elapsed} -gt ${TIMEOUT} ]]; then
    echo "mssql not ready within ${TIMEOUT}s - check: docker logs ${MSSQL}" 1>&2
    exit 1
  fi
  echo "waiting for mssql to accept connections (${elapsed}s)"
  sleep 5
done

# create the database, and prove the server answers a real query
mssql-q "IF DB_ID('${MSSQL_DBNAME}') IS NULL CREATE DATABASE [${MSSQL_DBNAME}];"
mssql-q "SELECT @@VERSION;"

PRIMARY_IP=$(get-primary-ip)
echo
echo "mssql ready: ${MSSQL_DBNAME} on port ${MSSQL_PORT}"
echo "dsn:      sqlserver://sa:${MSSQL_SA_PASSWORD}@${PRIMARY_IP}:${MSSQL_PORT}?database=${MSSQL_DBNAME}"
echo "sqlcmd:   docker exec -it ${MSSQL} /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P '${MSSQL_SA_PASSWORD}' -C"
