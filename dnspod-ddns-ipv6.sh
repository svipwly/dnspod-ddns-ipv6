#!/bin/bash

# 配置区域
API_TOKEN=""  # 替换为你的 DNSPod API 密钥
DOMAIN=""  # 你的主域名
SUBDOMAIN=""  # 你的子域名，例如 home.example.com
TTL=600  # DNS 记录的 TTL 值（可选）

# 获取当前主机的 IPv6 地址
get_ipv6_address() {
    ip -6 addr show scope global | grep inet6 | awk '{print $2}' | cut -d'/' -f1 | head -n 1
}

# 获取记录 ID 和现有 IP
get_record_id_and_ip() {
    RESPONSE=$(curl -s -X POST https://dnsapi.cn/Record.List \
        -d "login_token=$API_TOKEN&format=json&domain=$DOMAIN&sub_domain=$SUBDOMAIN")
    echo "API Response: $RESPONSE"  # 调试信息

    # 检查 API 响应状态
    STATUS_CODE=$(echo "$RESPONSE" | jq -r '.status.code')
    if [ "$STATUS_CODE" != "1" ]; then
        echo "API 请求失败: $(echo "$RESPONSE" | jq -r '.status.message')"
        exit 1
    fi

    # 提取记录 ID 和 IP
    RECORD_ID=$(echo "$RESPONSE" | jq -r '.records[] | select(.type=="AAAA") | .id')
    CURRENT_IP=$(echo "$RESPONSE" | jq -r '.records[] | select(.type=="AAAA") | .value')
}

# 更新记录
update_record() {
    RESPONSE=$(curl -s -X POST https://dnsapi.cn/Record.Modify \
        -d "login_token=$API_TOKEN&format=json&domain=$DOMAIN&record_id=$RECORD_ID&sub_domain=$SUBDOMAIN&record_type=AAAA&record_line=默认&value=$NEW_IP&ttl=$TTL")
    echo "更新结果: $(echo "$RESPONSE" | jq -r '.status.message')"
}

# 主逻辑
NEW_IP=$(get_ipv6_address)
if [ -z "$NEW_IP" ]; then
    echo "无法获取 IPv6 地址"
    exit 1
fi

get_record_id_and_ip
if [ -z "$RECORD_ID" ]; then
    echo "无法获取记录 ID，请检查域名和子域名是否正确"
    exit 1
fi

if [ "$NEW_IP" != "$CURRENT_IP" ]; then
    echo "IPv6 地址已更改，更新记录: $CURRENT_IP -> $NEW_IP"
    update_record
else
    echo "IPv6 地址未改变，无需更新"
fi
