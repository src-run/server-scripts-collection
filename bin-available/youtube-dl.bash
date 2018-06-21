#!/bin/bash

for url in "${@}"; do
  /usr/bin/youtube-dl --xattrs --add-metadata --embed-thumbnail --audio-format best --format best --verbose "${url}"
done
