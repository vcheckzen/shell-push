#!/bin/sh

# https://hostloc.com/thread-805549-1-1.html
TG_MESSAGE_API="$TG_API_PROXY/bot$TG_BOT_TOKEN/sendMessage"
TG_TEMPLATE_MESSAGE=$(
    cat <<EOF
{
    "chat_id": $TG_USER_ID,
    "text": "%s",
    "parse_mode": "MarkdownV2",
    "disable_web_page_preview": true
}
EOF
)

tg_log() {
    log "$1" TG "$2"
}

tg_send_message() {
    # shellcheck disable=SC2059
    resp=$(post_json "$TG_MESSAGE_API" \
        "$(printf "$TG_TEMPLATE_MESSAGE" "*$1*\n\`\`\`$2\`\`\`")")

    [ "$(jqv "$resp" ok)" != "true" ] && {
        tg_log "$LOG_LEVEL_ERR" "failed to send message: $resp"
        return 1
    }

    tg_log "$LOG_LEVEL_INFO" "succeed to send message: $resp"
}
