#!/bin/sh

DNSPOD_API_HOST="https://dnsapi.cn"
DNSPOD_API_GET_RECORD="$DNSPOD_API_HOST/Record.List"
DNSPOD_API_CREATE_RECORD="$DNSPOD_API_HOST/Record.Create"
DNSPOD_API_UPDATE_RECORD="$DNSPOD_API_HOST/Record.Ddns"
DNSPOD_API_PUB_PARAMS="login_token=${DNSPOD_API_ID},${DNSPOD_API_TOKEN}&\
lang=en&\
format=json&\
error_on_empty=yes&\
domain=${DNSPOD_DOMAIN}&\
sub_domain=${DNSPOD_SUB_DOMAIN}"

dnspod_log() {
    log "$1" DNSPOD "$2"
}

dnspod_get_record() {
    records=$(post_form_data "$DNSPOD_API_GET_RECORD" "$DNSPOD_API_PUB_PARAMS")
    code=$(jqv "$records" status.code -s)
    [ "$code" != "1" ] && {
        dnspod_log "$LOG_LEVEL_ERR" "failed to get record list: $records"
        return "$code"
    }

    dnspod_log "$LOG_LEVEL_INFO" "got record list: $records"
    jqv "$records" 'records[0]'
}

dnspod_create_record() {
    resp="$(post_form_data "$DNSPOD_API_CREATE_RECORD" \
        "$DNSPOD_API_PUB_PARAMS&record_type=A&record_line=默认&value=$1")"
    code=$(jqv "$resp" status.code -s)
    [ "$code" != "1" ] && {
        dnspod_log "$LOG_LEVEL_ERR" "failed to create record: $resp"
        return "$code"
    }

    dnspod_log "$LOG_LEVEL_INFO" "record created: $resp"
}

dnspod_update_record() {
    resp="$(post_form_data "$DNSPOD_API_UPDATE_RECORD" \
        "$DNSPOD_API_PUB_PARAMS&record_id=$1&record_line=默认&value=$2")"
    code=$(jqv "$resp" status.code -s)
    [ "$code" != "1" ] && {
        dnspod_log "$LOG_LEVEL_ERR" "failed to update record: $resp"
        return "$code"
    }

    dnspod_log "$LOG_LEVEL_INFO" "record updated: $resp"
}

dnspod_notify() {
    wx_send_message "$DNSPOD_DEV_NAME NEW IP" "$1"
    tg_send_message "$DNSPOD_DEV_NAME NEW IP" "$1"
}

dnspod_sync_ip() {
    record=$(dnspod_get_record)
    code="$?"

    record_id=$(jqv "$record" id -s)
    record_value=$(jqv "$record" value -s)
    current_ip=$(get_ip1)
    if [ "$code" = "10" ]; then
        dnspod_create_record "$current_ip"
        dnspod_notify "$current_ip"
    elif [ "$code" = "0" ] &&
        [ "$current_ip" != "$record_value" ]; then
        dnspod_update_record "$record_id" "$current_ip"
        dnspod_notify "$current_ip"
    fi
}
