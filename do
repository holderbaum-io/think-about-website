#!/bin/bash

function task_prepare_ci {
  openssl aes-256-cbc \
    -K "$encrypted_9e05e58bd4ea_key" \
    -iv "$encrypted_9e05e58bd4ea_iv" \
    -in deploy/id_rsa.enc \
    -out deploy/id_rsa \
    -d
  chmod 600 deploy/id_rsa
}

task_run() {
  local port="${1:-9090}"
  python server.py "$port"
}

task_deploy() {
  if [[ -f deploy/id_rsa ]];
  then
    eval "$(ssh-agent -s)"
    ssh-add deploy/id_rsa
  fi

  rsync \
    -ruvc \
    --delete \
    de \
    en \
    css \
    assets \
    deploy-think-about@turing.holderbaum.me:www/

  rsync \
    -ruvc \
    --delete \
    conf.d/* \
    deploy-think-about@turing.holderbaum.me:conf.d/
}

usage() {
  echo "$0 run"
  exit 1
}

cmd="${1:-}"
shift || true
case "$cmd" in
  prepare-ci) task_prepare_ci ;;
  run) task_run "${1:-}" ;;
  deploy) task_deploy ;;
  *) usage ;;
esac
