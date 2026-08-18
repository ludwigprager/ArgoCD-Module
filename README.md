# ArgoCD Module

## Description

This project is an ArgoCD playground to install, configure and run ArgoCD
in a matter of minutes without affecting running installations.  
It is self-contained and has a small footprint. The [tear-down script](./90-teardown.sh) will
remove most traces when applied after use.

## TL;DR
Clone this repo and run the start script:

```
git clone https://github.com/ludwigprager/ArgoCD-Module.git
./ArgoCD-Module/10-deploy.sh
```

Display URL endpoints created by this poc:
```
./ArgoCD-Module/print-console-links.sh 
```

## Prerequisites
- a linux machine. Any distribution should work fine. Or macOS with Darwin.   
- docker, jq, yq, wget installed

## How this Module works

ArgoCD surveys a git repository outside of the cluster.
In regular intervals, it tests for a drift in configuration
and attempt a reconciliation if found.

The [launcher script](./10-deploy.sh) will
- start a local git-server (gitea) in `docker compose`
- start a local Db2 LUW server in `docker compose`
- start a local kubernetes cluster (k3d)
- install ArgoCD

ArgoCD in turn installs the example applications that are referenced in [the manifest](./manifest/application.yaml.tpl)

Open the ArgoCD ui and the example applications in your browser.
Call the [provided script](./print-console-links.sh) to see the URLs and the argocd admin password.

The applications were copied from the [argocd example repo](https://github.com/argoproj/argocd-example-apps) and the
[FluxCD example app](https://github.com/stefanprodan/podinfo).

## Db2 LUW

[25-start-db2.sh](./25-start-db2.sh) starts IBM Db2 Community Edition next to gitea in the
same compose project, and [15-install.sh](./15-install.sh) downloads the matching IBM CLI
driver into `./bin/clidriver` for Go clients that bind Db2 through cgo
([go_ibm_db](https://github.com/ibmdb/go_ibm_db)).

Server image and driver are pinned as a matched pair: `icr.io/db2_community/db2:12.1.4.0`
is the newest server tag that has a pinnable clidriver (`v12.1.4`) on IBM's download site.
`go_ibm_db` otherwise fetches clidriver from an unversioned URL, i.e. whatever IBM ships
that day; `source ./.env` exports `IBM_DB_HOME` so it uses the pinned copy instead, along
with `CGO_CFLAGS`, `CGO_LDFLAGS` and `LD_LIBRARY_PATH`:

```
source ./.env
go build ./...
```

Connection details come from [print-console-links.sh](./print-console-links.sh); a CLP
shell is `docker exec -it db2server su - db2inst1`.

Notes and limitations:
- **amd64 only.** IBM publishes the server image for amd64, ppc64le and s390x - there is
  no arm64 build, so the server does not run on Apple Silicon. The clidriver *does* ship
  for macarm64, so Go clients still build there against a remote server.
- **privileged.** Db2 sets kernel and IPC parameters when creating the instance, so the
  container runs with `privileged: true`.
- **licence.** Starting the container accepts the IBM Db2 Community Edition licence
  (`DB2_LICENSE=accept` in [misc/env.tpl](./misc/env.tpl)). CE is limited to 4 cores,
  16 GB RAM and 100 GB of user data.
- **first start takes minutes.** The instance and database are created on first boot; the
  port listens long before either exists, so the stage waits for the `Setup has completed`
  log line and then proves the database answers a `connect`.
- **disk.** The image is ~2.5 GiB compressed, ~6 GiB unpacked.
- Database state lives in `container/db2-data`, inside the clone, like every other piece
  of state this module creates. Db2 writes it as root, so `./90-teardown.sh` deletes it
  from inside a container rather than asking for sudo. A named volume would have been
  easier, but it survives `rm -rf` of the clone as orphaned residue and its docker-global
  name collides between two clones.

# Possible Applications
- resiliency tests: ArgoCD autorepairs a number of properties, but details are hard to determine without practical usage.
- promotion from pre-prod to prod: you can start a prod and pre-prod cluster with k3d and test your promotion code.
- behaviour of ArgoCD in various circumstances, e.g. network failures, already present objects in kubernetes, RBAC properties et.al.
- test the management of multiple clusters with a single argocd server instance
- develop and verify your scripts by frequently applying the cycle of quick tear down and rebuild.

# Script Properties

The bash scripts adhere to the following principles:
- dedicated versions. As opposed to implicit version number, leading to recommended or 'latest'.
- idempotent
- exit on first error
- independent of the caller's working directory


## List k3s images

```
curl -s https://registry.hub.docker.com/v2/repositories/rancher/k3s/tags?page_size=100 | jq -r '.results[].name'
```

# References
https://github.com/argoproj/argocd-example-apps/  
https://github.com/stefanprodan/podinfo  
https://hub.docker.com/r/rancher/k3s/tags  
https://github.com/ibmdb/go_ibm_db  
https://www.ibm.com/docs/en/db2/12.1.0?topic=system-db2-community-edition-linux  
