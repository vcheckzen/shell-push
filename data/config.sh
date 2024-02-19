#!/bin/sh

# 1: INFO, 2: WARN, 3: ERR
export LOG_LEVEL="3"

# Wechat
# https://www.cnblogs.com/mengyu/p/10073140.html
# 企业 ID
export WX_CORP_ID=""
# 应用 AgentId
export WX_APP_ID=""
# 应用 Secret
export WX_APP_SECRET=""

# Telegram
# https://www.hostloc.com/thread-805441-1-1.html
export TG_BOT_TOKEN=""
## @getuseridbot 中获取到的纯数字 ID
export TG_USER_ID=""
## 反向代理地址
export TG_API_PROXY=""

# DNSPod
# https://docs.dnspod.cn/account/5f2d466de8320f1a740d9ff3/
# DNSPod API Token 中的 API 项
export DNSPOD_API_ID=""
# DNSPod API Token 中的 TOKEN 项
export DNSPOD_API_TOKEN=""
# 域名，例如 logi.im，不加前缀
export DNSPOD_DOMAIN=""
# 子域名，例如 home，即域名前缀
export DNSPOD_SUB_DOMAIN=""
# 本设备名
export DNSPOD_DEV_NAME=""