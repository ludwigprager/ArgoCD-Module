#!/usr/bin/env bash

export GITEA=$(hostname)
export KUBECONFIG=${BASEDIR:-$(pwd)}/kubeconfig

export GITEA_LP_USER=lp
export GITEA_LP_PASSWORD=geheim


export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${BASEDIR:-$(pwd)}/key" 



# from kcp-pot
export ARGOCD_MOD_ROOT=${ARGOCD_MOD_ROOT}


PATH=${ARGOCD_MOD_ROOT}/bin:${ARGOCD_MOD_ROOT}/bin/.krew/bin:${PATH}

alias k=$ARGOCD_MOD_ROOT/bin/kubectl

# from set-env.sh

export GITEA=$(hostname)
export KUBECONFIG=${BASEDIR:-$(pwd)}/kubeconfig

export GITEA_LP_USER=lp
export GITEA_LP_PASSWORD=geheim

export GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -i ${BASEDIR:-$(pwd)}/key" 

export INGRESS_PORT="8123"

export CLUSTERS=""
export CLUSTER_PREFIX="argo-"
CLUSTERS="${CLUSTERS} ${CLUSTER_PREFIX}intern"
CLUSTERS="argo-intern"

APPS="guestbook helm-guestbook kustomize-guestbook podinfo"

### Db2 LUW (Community Edition) ###########################################
# Server image and CLI driver are a matched pair: icr.io tag 12.1.4.0 is the
# newest server that has a pinnable clidriver (v12.1.4) on IBM's download site.
export DB2=db2server
export DB2_VERSION=12.1.4.0
export CLIDRIVER_VERSION=v12.1.4

# Starting the container means accepting the IBM Db2 Community Edition licence
# (C-EULA). CE is capped at 4 cores / 16 GB RAM / 100 GB user data.
export DB2_LICENSE=accept

export DB2_INSTANCE=db2inst1
export DB2_PASSWORD=geheim
export DB2_DBNAME=TESTDB          # Db2 database names are max 8 characters
export DB2_PORT=50000

# cgo build environment for github.com/ibmdb/go_ibm_db.
# go_ibm_db downloads clidriver from an UNVERSIONED url by default; setting
# IBM_DB_HOME makes it use ours instead, which is what keeps the pin real.
export IBM_DB_HOME=${ARGOCD_MOD_ROOT}/bin/clidriver
export CGO_CFLAGS="-I${ARGOCD_MOD_ROOT}/bin/clidriver/include"
export CGO_LDFLAGS="-L${ARGOCD_MOD_ROOT}/bin/clidriver/lib"
# LD_LIBRARY_PATH is set in misc/utils.sh - see the note there.

export http_proxy=""

## Use GNU's gsed when on macOS
## If missing, you may want to install it with brew install gnu-sed
#export SED=sed
#if [[ "$(uname -o)" == "Darwin" ]]; then
#SED=gsed
#fi

export GOOS=${GOOS}
GOARCH=${GOARCH}
