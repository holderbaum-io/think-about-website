#!/bin/bash

task_run() {
  local port="${1:-9090}"

  if python --version 2>&1 |grep 2.7 &>/dev/null;
  then
    python -m SimpleHTTPServer "$port"
  else
    python -m http.server "$port"
  fi
}

usage() {
  echo "$0 run"
  exit 1
}

cmd="${1:-}"
shift || true
case "$cmd" in
  run) task_run "${1:-}" ;;
  *) usage ;;
esac
