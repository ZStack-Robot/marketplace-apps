#!/bin/bash


# 获取端口号参数
PORT=$1
shift

# 检查每个参数传递的 URL 是否可达
for ip in "$@"; do
    url="${ip}:${PORT}/metrics"  # 或者替换为需要检查的 URL
    echo "Checking connectivity for $url ..."
    if curl -s --head "$url" | grep "200" > /dev/null; then
        echo "Success: $url is reachable."
    else
        echo "Error: $url is not reachable. 当前Cloud版本没有部署对应process_exporter或zstack_service_exporter或和物理机网络不通，请重新选择网络"
        exit 1
    fi
done