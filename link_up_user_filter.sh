#!/usr/bin/env bash
SRC_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SRC_DIR" ]]; then SRC_DIR="$PWD"; fi

# Run scripts
"$SRC_DIR/user_filter/vpn_routing_table.sh"
"$SRC_DIR/user_filter/iptables_user_filter.sh"
