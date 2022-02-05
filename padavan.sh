#!/bin/sh

PADAVAN_SRC_FILE="$(pwd)"/main.sh
PADAVAN_OBJ_FILE=/etc/storage/post_wan_script.sh
PADAVAN_TEMPLATE=$(
    cat <<'EOF'
[ "$1" = "up" ] && {
    for _ in $(seq 1 10); do
        curl -sm1 qq.com -o /dev/null && {
            %s &
            break
        }
        sleep 12
    done
}
EOF
)

# shellcheck disable=2059
printf "\n$PADAVAN_TEMPLATE" "$PADAVAN_SRC_FILE" >>"$PADAVAN_OBJ_FILE"

nvram commit
mtd_storage.sh save
