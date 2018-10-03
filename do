#!/bin/bash

ensure_ruby() {
  bundle install --path vendor/bundle --binstubs vendor/bin
}

function task_prepare_ci {
  openssl aes-256-cbc \
    -K "$encrypted_9e05e58bd4ea_key" \
    -iv "$encrypted_9e05e58bd4ea_iv" \
    -in deploy/id_rsa.enc \
    -out deploy/id_rsa \
    -d
  chmod 600 deploy/id_rsa
}

task_serve() {
  ensure_ruby

  local port="${1:-9090}"
  ./vendor/bin/rackup -p "$port" -o 0.0.0.0
}

task_build() {
  ensure_ruby

  bundle exec ruby ./bin/build.rb
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
  echo "$0 serve | build"
  exit 1
}

cmd="${1:-}"
shift || true
case "$cmd" in
  prepare-ci) task_prepare_ci ;;
  serve) task_serve "${1:-}" ;;
  build) task_build ;;
  deploy) task_deploy ;;
  *) usage ;;
esac
