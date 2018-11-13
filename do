#!/bin/bash

ensure_ruby() {
  bundle install --path vendor/bundle --binstubs vendor/bin
}

function task_prepare_ci {
  openssl aes-256-cbc \
    -K "$encrypted_9e05e58bd4ea_key" \
    -iv "$encrypted_9e05e58bd4ea_iv" \
    -in deploy/ssh.enc \
    -out deploy/ssh \
    -d
  chmod 600 deploy/ssh

  task_update_speakers
  task_update_keynotes

  if [[ "$(git diff --stat)" != '' ]];
  then
    eval "$(ssh-agent -s)"
    ssh-add deploy/ssh

    git commit -am '[travis] Update speakies and keynotes'
    git push origin master
  fi
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

task_update_speakers() {
  ensure_ruby

  bundle exec ruby bin/speakies.rb > partials/speakers_list.html.erb
}

task_update_keynotes() {
  ensure_ruby

  bundle exec ruby bin/keynotes.rb > partials/keynotes_list.html.erb
}

task_update_tickets() {
  ensure_ruby

  bundle exec ruby bin/tickets.rb > data/tickets.json
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
    --delete \
    deploy/conf.d/* \
    "${user}@turing.holderbaum.me:conf.d/"
}

usage() {
  echo "$0 serve | build | update_keynotes | update_speakers | update_tickets | deploy | clean"
  exit 1
}

cmd="${1:-}"
shift || true
case "$cmd" in
  prepare-ci) task_prepare_ci ;;
  clean) task_clean ;;
  serve) task_serve "$@" ;;
  build) task_build ;;
  update_keynotes) task_update_keynotes ;;
  update_speakers) task_update_speakers ;;
  update_tickets) task_update_tickets ;;
  deploy) task_deploy "$@" ;;
  *) usage ;;
esac
