#!/bin/bash

set -eu

ensure_ruby() {
  local bundler_version="$(tail -n1 Gemfile.lock |tr -d ' ')"
  if ! gem list -q bundler |grep -q "$bundler_version" >/dev/null;
  then
    gem install "bundler:$bundler_version"
  fi
  bundle install --path vendor/bundle --binstubs vendor/bin
}

function task_prepare_ci {
  git checkout -qf master

  openssl aes-256-cbc \
    -K "$encrypted_9e05e58bd4ea_key" \
    -iv "$encrypted_9e05e58bd4ea_iv" \
    -in deploy/ssh.enc \
    -out deploy/ssh \
    -d
  chmod 600 deploy/ssh
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

task_clean() {
  rm -rf result/
}

task_update_event_data() {
  ensure_ruby

  local url='https://orga.hrx.events/en/thinkabout2019/public/events.json'
  curl \
    -L \
    "$url" \
      |ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(STDIN.read))' \
      >data/events-new.json
  if [ -s data/events-new.json ];
  then
    mv data/events-new.json data/events.json
    bundle exec ruby bin/schedule.rb
  else
    rm -f data/events-new.json
  fi
}

task_deploy() {
  local user="${1:-deploy-think-about}"

  if [[ -f deploy/ssh ]];
  then
    eval "$(ssh-agent -s)"
    ssh-add deploy/ssh
  fi

  rsync \
    -ruvc \
    --delete \
    result/* \
    "${user}@turing.holderbaum.me:www/"

  rsync \
    -ruvc \
    root/* \
    "${user}@turing.holderbaum.me:www/"

  rsync \
    -ruvc \
    --delete \
    deploy/conf.d/* \
    "${user}@turing.holderbaum.me:conf.d/"
}

usage() {
  echo "$0 serve | build | update_event_data | deploy | clean"
  exit 1
}

cmd="${1:-}"
shift || true
case "$cmd" in
  prepare-ci) task_prepare_ci ;;
  clean) task_clean ;;
  serve) task_serve "$@" ;;
  build) task_build ;;
  update_event_data) task_update_event_data ;;
  deploy) task_deploy "$@" ;;
  *) usage ;;
esac
