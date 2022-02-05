#!/bin/sh

for req in curl grep sed awk; do
    which $req 1>/dev/null || {
        echo Lack of $req, quit running.
        exit 1
    }
done

[ -d "$BASE_DIR"/data/gen ] || mkdir -p "$BASE_DIR"/data/gen

# shellcheck source=/dev/null
. "$BASE_DIR"/data/config.sh
# shellcheck source=/dev/null
. "$BASE_DIR"/common/jq.sh
# shellcheck source=/dev/null
. "$BASE_DIR"/common/util.sh
# shellcheck source=/dev/null
. "$BASE_DIR"/push/wx.sh
# shellcheck source=/dev/null
. "$BASE_DIR"/push/tg.sh
# shellcheck source=/dev/null
. "$BASE_DIR"/app/dnspod.sh
