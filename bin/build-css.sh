#!/bin/bash

node="$(find bin/vendor/ -maxdepth 1 |sort |tail -n1)"
PATH="$(pwd)/$node/bin:$PATH"

cmd='./node_modules/.bin/postcss source/stylesheets/site.css -o .tmp/dist/stylesheets/site.css'

if [[ "${1:-}" = '--watch' ]];
then
  $cmd
  # while inotifywait source/stylesheets/*.css source/stylesheets/*/*.css;
  while inotifywait source/stylesheets/*.css;
  do
    $cmd
  done
else
  exec $cmd
fi
