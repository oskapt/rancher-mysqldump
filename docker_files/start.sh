#!/bin/bash

if [[ ! -z ${STARTUP_OPTIONS} ]]; then
  /usr/local/bin/mysqldump ${STARTUP_OPTIONS} -- "$@"
else
  /usr/local/bin/mysqldump -- "$@"
fi
