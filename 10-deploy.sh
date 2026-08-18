#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR

start=$(date +%s.%N)

./14-env.sh
./15-install.sh

./20-start-gitea.sh
./25-start-db2.sh
./27-start-mssql.sh
./30-create-environment-repositories.sh
./40-start-a-k8s-cluster.sh
./50-install-argocd-k8s.sh
./60-register-applications.sh

# ./test-ingress.sh

end=$(date +%s.%N)

# Calculate elapsed time in seconds with fractions
elapsed=$(echo "$end - $start" | bc)

# Convert to minutes and seconds
minutes=$(echo "$elapsed/60" | bc)
seconds=$(echo "$elapsed - $minutes*60" | bc)

printf "Execution time: %d minutes %.3f seconds\n" "$minutes" "$seconds"
