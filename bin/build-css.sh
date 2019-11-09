#!/bin/bash

cmd='postcss source/stylesheets/site.css -o .tmp/dist/stylesheets/site.css'

if [[ "${1:-}" = '--watch' ]];
then
  $cmd
  if command -v fswatch;
  then
    while fswatch source/stylesheets/*.css source/stylesheets/*/*.css;
    do
      $cmd
    done
  else
    while inotifywait source/stylesheets/*.css source/stylesheets/*/*.css;
    do
      $cmd
    done
  fi
else
  exec $cmd
fi
