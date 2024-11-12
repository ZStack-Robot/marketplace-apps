#!/bin/bash

# Initialize variables
self_ip=""
vip=""

# Capture the output of zstack-ctl show_configuration
zstack_config_output=$(sudo zstack-ctl show_configuration)

# Extract management.server.ip and management.server.vip from the output
self_ip=$(echo "$zstack_config_output" | grep 'management.server.ip' | awk -F'=' '{print $2}' | xargs)
vip=$(echo "$zstack_config_output" | grep 'management.server.vip' | awk -F'=' '{print $2}' | xargs)

# Output JSON for Terraform external data source
cat <<EOF
{
    "self_ip": "$self_ip",
    "vip": "$vip"
}
EOF