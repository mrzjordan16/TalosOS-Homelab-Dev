#!/bin/bash

set -o allexport
source .env
set +o allexport

for value in $(echo "$WORKER_NODE_IP" | tr ',' ' '); do
    IP_ONLY="${value%/*}"
    talosctl upgrade --nodes $IP_ONLY --image $image
done

