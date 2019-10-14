#!/bin/bash

set -eu

ensure_ruby() {
  local bundler_version
  bundler_version="$(tail -n1 Gemfile.lock |tr -d ' ')"
  if ! gem list -q bundler |grep -q "$bundler_version" >/dev/null;
  then
    export BUNDLER_VERSION=2.0.1
    gem install "bundler:$bundler_version"
  fi
  bundle install --path vendor/bundle --binstubs vendor/bin
}

ensure_node() {
  local node_version="10.16.3"

  if [ ! -e "bin/vendor/node-v${node_version}-linux-x64/bin/npm" ];
  then
    mkdir -p bin/vendor
    wget "https://nodejs.org/dist/v${node_version}/node-v${node_version}-linux-x64.tar.xz"
    (cd bin/vendor; tar xf "../../node-v${node_version}-linux-x64.tar.xz")
    rm -f node-*-linux-x64.tar.xz
  fi

  PATH="$(pwd)/node_modules/.bin:${PATH}"
  PATH="$(pwd)/bin/vendor/node-v${node_version}-linux-x64/bin:${PATH}"
  export PATH

  npm install
}

function prepare_ci {
  if [[ -z "${CI:=}" ]]; then return 0; fi

  mkdir -p ~/.ssh
  chmod 700 ~/.ssh

  eval $(ssh-agent -s)
  echo "$SSH_PRIVATE_KEY" | tr -d '\r' | ssh-add -

  echo "$SSH_KNOWN_HOSTS" > ~/.ssh/known_hosts
  chmod 644 ~/.ssh/known_hosts
}

task_serve() {
  ensure_node
  ensure_ruby

  local port="${1:-9090}"
  ./vendor/bin/middleman serve -p "$port" --bind-address=127.0.0.1
}

task_build() {
  ensure_node
  ensure_ruby

  ./vendor/bin/middleman build
}

task_clean() {
  rm -rf build/
}

task_deploy() {
  prepare_ci

  rsync \
    --rsh "ssh -p $SSH_PORT" \
    --archive \
    --checksum \
    --verbose \
    build/ \
    "$SSH_USER@$SSH_HOST:"

}

usage() {
  echo "$0 serve | build | deploy | clean"
  exit 1
}

cmd="${1:-}"
shift || true
case "$cmd" in
  clean) task_clean ;;
  serve) task_serve "$@" ;;
  build) task_build ;;
  deploy) task_deploy "$@" ;;
  *) usage ;;
esac
