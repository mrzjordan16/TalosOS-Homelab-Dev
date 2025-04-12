#!/bin/bash

set -o allexport
source .env
set +o allexport

IP_ONLY="${CP_IP%/*}"

talosctl upgrade --nodes $IP_ONLY --image $image