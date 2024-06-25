#!/bin/bash

HASH_FILE="container_hashes.txt"

find /var/lib/docker/containers -type f ! -name '*.log' -exec sha256sum {} \; > "$HASH_FILE"
