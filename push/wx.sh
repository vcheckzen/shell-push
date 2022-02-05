#!/bin/sh

WX_TOKEN_FILE="$BASE_DIR"/data/gen/wx_token

# https://developer.work.weixin.qq.com/document/path/91039
WX_TOKEN_API="https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid=%s&corpsecret=%s"
WX_MESSAGE_API="https://qyapi.weixin.qq.com/cgi-bin/message/send?access_token=%s"
WX_TEMPLATE_MESSAGE=$(
    cat <<EOF
{
    "touser": "@all",
    "agentid": $WX_APP_ID,
    "msgtype": "news",
    "news": {
        "articles": [
            {
                "title": "%s",
                "description": "%s"
            }
        ]
    },
    "enable_id_trans": 0,
    "enable_duplicate_check": 0,
    "duplicate_check_interval": 1800
}
EOF
)

wx_log() {
    log "$1" WX "$2"
}

wx_get_token() {
    [ -s "$WX_TOKEN_FILE" ] &&
        [ "$(jq "$WX_TOKEN_FILE" errcode)" -eq 0 ] &&
        [ "$(jq "$WX_TOKEN_FILE" expires_at)" -gt "$(date +%s)" ] && {
        wx_log "$LOG_LEVEL_INFO" "use cached token: $(cat "$WX_TOKEN_FILE")"
        jq "$WX_TOKEN_FILE" access_token -s
        return 0
    }

    # shellcheck disable=SC2059
    get "$(printf "$WX_TOKEN_API" "$WX_CORP_ID" "$WX_APP_SECRET")" >"$WX_TOKEN_FILE"
    [ "$(jq "$WX_TOKEN_FILE" errcode)" -ne 0 ] && {
        wx_log "$LOG_LEVEL_ERR" "cannot get token: $(cat "$WX_TOKEN_FILE")"
        return 1
    }

    ts=$(date +%s)
    expires_in=$(jq "$WX_TOKEN_FILE" expires_in)
    expires_at=$((ts + expires_in))
    sed -i -r "s/\"expires_in\":[^}]+?/\"expires_at\":$expires_at/" "$WX_TOKEN_FILE"

    wx_log "$LOG_LEVEL_INFO" "get new token: $(cat "$WX_TOKEN_FILE")"
    jq "$WX_TOKEN_FILE" access_token -s
}

wx_send_message() {
    # shellcheck disable=SC2059
    resp=$(post_json "$(printf "$WX_MESSAGE_API" "$(wx_get_token)")" \
        "$(printf "$WX_TEMPLATE_MESSAGE" "$1" "$2")")

    [ "$(jqv "$resp" errcode)" -ne 0 ] && {
        wx_log "$LOG_LEVEL_ERR" "failed to send message: $resp"
        return 1
    }

    wx_log "$LOG_LEVEL_INFO" "succeed to send message: $resp"
}
