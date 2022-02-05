#!/bin/sh

export LOG_LEVEL_INFO=1
export LOG_LEVEL_WARN=2
export LOG_LEVEL_ERR=3

LOG_FILE="$BASE_DIR"/data/gen/log

get() {
    curl -m3 -skL "$1"
}

post_form_data() {
    curl -m5 -skL "$1" -d "$2"
}

post_json() {
    curl -m5 -skL "$1" -H 'Content-Type: application/json' -d "$2"
}

get_ip1() {
    # https://unix.stackexchange.com/questions/8518/how-to-get-my-own-ip-address-and-save-it-to-a-variable-in-a-shell-script
    ip route get 1 |
        sed -nr "/src/{s/.*?src *?([^ ]+?).*?/\1/p;q}"
}

get_ip2() {
    get "$(get http://nstool.netease.com |
        grep -oE "src=[^ ]+?" |
        sed -nr "s/.*?['\"](.+?)['\"].*?/\1/p")" |
        grep -oE "[0-9\.]+?" |
        head -1
}

log() {
    [ "$1" -lt "$LOG_LEVEL" ] && return

    [ -s "$LOG_FILE" ] &&
        [ "$(wc -c "$LOG_FILE" |
            cut -d' ' -f1)" -gt 10240 ] &&
        {
            latest_log=$(tail -99 "$LOG_FILE")
            echo "$latest_log" >"$LOG_FILE"
        }

    echo "$USER \
shellpush[$$] \
$(date "+%Y-%m-%d %H:%M:%S") \
[$(echo 'INFO WARN ERR' | cut -d' ' -f"$1")] \
$2: $3" >>"$LOG_FILE"
}
