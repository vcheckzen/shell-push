#!/bin/sh

BASE_DIR="$(dirname "$0")"
export BASE_DIR

# shellcheck source=/dev/null
. "$BASE_DIR"/import.sh

dnspod_sync_ip
