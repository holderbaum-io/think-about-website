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

function prepare_ci {
  if [[ -z "${TRAVIS:=}" ]]; then return 0; fi

  sudo apt-get \
    install \
    -y \
    lftp
}

task_serve() {
  ensure_ruby

  local port="${1:-9090}"
  ./vendor/bin/middleman serve -p "$port" --bind-address=127.0.0.1
}

task_build() {
  ensure_ruby

  ./vendor/bin/middleman build
}

task_clean() {
  rm -rf build/
}

task_update_event_data() {
  ensure_ruby

  local url='https://orga.hrx.events/en/thinkabout2019/public/events.json'
  curl \
    -L \
    "$url" \
      |ruby -rjson -e 'puts JSON.pretty_generate(JSON.parse(STDIN.read))' \
      >.events.json

  bundle exec ruby bin/schedule.rb <.events.json >.schedule.json

  if [ -s .schedule.json ];
  then
    mv .schedule.json data/events/2019/schedule.json
  fi

  rm -f .events.json .schedule.json
}

task_deploy() {
  prepare_ci

  set -x
  lftp -c "
    set ftps:initial-prot \"\";
    set ftp:ssl-force true;
    set ftp:ssl-protect-data true;
    set dns:order \"inet\";
    open ftp://$DEPLOY_USER:$DEPLOY_PASS@www151.your-server.de:21;
    mirror -eRv build .;
    quit;"
}

usage() {
  echo "$0 serve | build | update_event_data | deploy | clean"
  exit 1
}

cmd="${1:-}"
shift || true
case "$cmd" in
  clean) task_clean ;;
  serve) task_serve "$@" ;;
  build) task_build ;;
  update_event_data) task_update_event_data ;;
  deploy) task_deploy "$@" ;;
  *) usage ;;
esac
