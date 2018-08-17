#!/bin/bash

task_run() {
  local port="${1:-9090}"
  python server.py "$port"
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
