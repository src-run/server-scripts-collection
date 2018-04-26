#!/bin/bash

wget http://ipecho.net/plain -O - -q --bind-address="$(ip route get 8.8.8.8 oif "tun0" | awk '{if ($5 == "") next;} {print $5}')"; echo

