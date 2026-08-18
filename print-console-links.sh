#!/usr/bin/env bash

set -eu
BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $BASEDIR

source ./.env

password=$(kubectl get -n argocd secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d)

PRIMARY_IP=$(get-primary-ip)

echo
echo "argocd:              http://${PRIMARY_IP}:${INGRESS_PORT}/argocd/"
echo "argocd login:        admin : ${password}"
echo
echo "guestbook:           http://${PRIMARY_IP}:${INGRESS_PORT}/guestbook"
echo "helm-guestbook:      http://${PRIMARY_IP}:${INGRESS_PORT}/helm-guestbook/"
echo "kustomize-guestbook: http://${PRIMARY_IP}:${INGRESS_PORT}/kustomize-guestbook/"
echo "podinfo              http://${PRIMARY_IP}:${INGRESS_PORT}/podinfo/"
echo
echo "gitea:               http://$PRIMARY_IP:3000/explore/repos/"
echo "gitea swagger:       http://${PRIMARY_IP}:3000/api/swagger#"
echo

