#!/bin/bash
set -e

if [[ -n "$1" && "${1:0:1}" != '-' ]]; then
  # they're not passing options
  exec "$@"
elif [[ ! -z ${STARTUP_OPTIONS} ]]; then
  /usr/local/bin/mysqldump ${STARTUP_OPTIONS} -- "$@"
else
  /usr/local/bin/mysqldump -- "$@"
fi
