#!/bin/bash

youtube-dl --xattrs --add-metadata --embed-thumbnail --audio-format best --format best --verbose "${1}"
