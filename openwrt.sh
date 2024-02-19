#!/bin/sh

OPENWRT_SRC_FILE="$(pwd)"/main.sh
# https://serverfault.com/questions/47915/how-do-i-get-the-default-gateway-in-linux-given-the-destination
# https://forum.openwrt.org/t/wan-up-down-etc-hotplug-d-iface-scripts-not-called-run/44156
# OPENWRT_WAN_NAME="$(sed -nr "/wan/s/.*?interface '([^']+?).*?/\1/p" /etc/config/network)"
OPENWRT_WAN_NAME="wan"
OPENWRT_OBJ_FILE=/etc/hotplug.d/iface/99-shellpush-ip
# https://tldp.org/HOWTO/PPP-HOWTO/x1455.html
# OPENWRT_OBJ_FILE=/etc/ppp/ip-up.d/99-shellpush-ip

# https://forum.openwrt.org/t/run-a-script-when-an-interface-goes-up-and-down/3728/3
OPENWRT_TEMPLATE=$(
    cat <<'EOF'
#!/bin/sh

[ "$ACTION" = "ifup" -a "$INTERFACE" = "%s" ] && {
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
printf \
    "$OPENWRT_TEMPLATE" \
    "$OPENWRT_WAN_NAME" \
    "$OPENWRT_SRC_FILE" \
    >"$OPENWRT_OBJ_FILE"

chmod +x "$OPENWRT_OBJ_FILE"
