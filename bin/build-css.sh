#!/bin/bash

cmd='postcss source/stylesheets/site.css -o .tmp/dist/stylesheets/site.css'

if [[ "${1:-}" = '--watch' ]];
then
  $cmd
  while inotifywait source/stylesheets/*.css source/stylesheets/*/*.css;
  do
    $cmd
  done
else
  exec $cmd
fi
