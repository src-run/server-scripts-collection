#!/bin/bash

printf 'Resolvable System Hostnames:\n\n'

printf \
  '%s %s' \
  "$(hostname -a)" \
  "$(hostname -A)" | \
sed \
  -E \
  's/[ ]+/\n/g' | \
sed \
  -E \
  's/^ip6-//g' | \
sort \
  -r | \
uniq | \
xargs \
  printf '  -> %s\n'
