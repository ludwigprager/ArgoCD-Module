#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR

set +e

source ./.env

k3d cluster delete $CLUSTERS || true

MY_RANDOM=$RANDOM
mv kubeconfig kubeconfig.${MY_RANDOM}

for app in ${APPS}; do
  mv ${app} ${app}.${MY_RANDOM}
done
mv container/gitea-data/ container/gitea-data.${MY_RANDOM}/

# -v is for the anonymous volume the db2 image declares for /hadr, not for
# module state: state lives in container/db2-data inside the clone. Without -v
# every db2 container leaks one orphaned volume.
docker compose --project-directory container down -v

# Db2 writes container/db2-data as root. Delete it from inside a container so
# no sudo is needed and `rm -rf` of the clone is enough to finish the job.
# The db2 image is already local at this point, so teardown stays offline.
if [[ -d container/db2-data ]]; then
  docker run --rm --entrypoint /bin/rm \
    -v ${BASEDIR}/container:/work \
    icr.io/db2_community/db2:${DB2_VERSION} -rf /work/db2-data || true
  rm -rf container/db2-data || true
fi


