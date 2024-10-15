#!/bin/bash

# Define the output file
output_file="cloud-variables.tf"

# Initialize variables
self_ip=""
vip=""
peer_ip=""
zstack_ui_url=""
zstack_config_path=""

# Check if zsha2 command exists
if command -v zsha2 > /dev/null 2>&1; then
    # Capture the output of zsha2 show-config
    zsha2_config_output=$(zsha2 show-config)

    # Extract the IP addresses from the JSON output
    self_ip=$(echo "$zsha2_config_output" | awk -F'"' '/"nodeip":/ {print $4}')
    vip=$(echo "$zsha2_config_output" | awk -F'"' '/"dbvip":/ {print $4}')
    peer_ip=$(echo "$zsha2_config_output" | awk -F'"' '/"peerip":/ {print $4}')

else
    # zsha2 command not found, use zstack-ctl to get management server IP
    self_ip=$(zstack-ctl show_configuration | grep 'management.server.ip' | awk -F'=' '{print $2}' | xargs)
fi

# Get ZSTACK_HOME using zstack-ctl
zstack_home=$(zstack-ctl getenv | grep 'ZSTACK_HOME' | awk -F'=' '{print $2}' | xargs)

# Extract the base path from ZSTACK_HOME
base_path=$(dirname $(dirname $(dirname $zstack_home)))
zstack_config_path="${base_path}/zstack-ui"


# Output JSON for Terraform external data source
cat <<EOF
{
    "self_ip": "$self_ip",
    "vip": "$vip",
    "peer_ip": "$peer_ip",
    "zstack_config_path": "$zstack_config_path",
    "zstack_home": "$zstack_home"
}
EOF
