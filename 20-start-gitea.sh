#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR

source ./.env


write-container-env

# scoped to gitea: db2 is a service in the same compose project, started by
# ./25-start-db2.sh
docker compose --project-directory container up -d gitea

is_healthy() {
    service="$1"
    container_id="$(docker compose   --project-directory container ps -q "$service")"
    health_status="$(docker inspect -f "{{.State.Health.Status}}" "$container_id")"

    if [ "$health_status" = "healthy" ]; then
        return 0
    else
        return 1
    fi
}

while ! is_healthy gitea; do sleep 1; done

count=$(docker exec -it ${GITEA} su git bash -c "gitea admin user list" | grep 'lp.*test@lp.com' | wc -l)

echo count: $count
if [[ $count -ne 1 ]]; then
  docker exec -it ${GITEA} su git bash -c \
	  "gitea admin user create --username ${GITEA_LP_USER} --password ${GITEA_LP_PASSWORD} --email test@lp.com"

fi


if [[ ! -f key ]]; then
  ssh-keygen -t rsa -N '' -f key <<< y
fi

# upload the ssh public key
key=$(cat key.pub)
curl -X 'POST' \
  "http://$GITEA:3000/api/v1/user/keys" \
  -u ${GITEA_LP_USER}:${GITEA_LP_PASSWORD} \
  -H 'accept: application/json' \
  -H 'Content-Type: application/json' \
  -d "{
  \"key\": \"$key\",
  \"read_only\": true,
 \"title\": \"key1\"
}"

#sensible-browser http://$GITEA:3000/explore/repos/  &
