#!/usr/bin/env bash
#
# Mostly based on the script from this blog:
# https://www.niftiestsoftware.com/2011/08/28/making-all-network-traffic-for-a-linux-user-use-a-specific-network-interface/
#
SRC_DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$SRC_DIR" ]]; then SRC_DIR="$PWD"; fi
source "$SRC_DIR/vpn_base.sh"

LAN_IP=`get_nic_ip $NETIF`
SUBNET_MASK=`get_nic_subnet_mask $NETIF` # CIDR
LAN_NETWORK=`getnetmask $LAN_IP $SUBNET_MASK`
LAN_NETWORK="$LAN_NETWORK/$SUBNET_MASK" # Should be on the form 172.16.0.0/24

# For multiple ports, separate by comma: 6881,6889
# For port range, seperate by colon: 6881:6889
BITTORRENT_LISTEN_PORTS=6881:6891


DNS_PORT=53
# Use google DNS servers
DNS_IP1=8.8.4.4
DNS_IP2=8.8.8.8

#Remove iprules based on the custom comment we add with the rules.
COMMENT="deluge-vpn"
iptables-save | grep -v "${COMMENT}" | iptables-restore

# Mark packets from $VPNUSER
iptables -t mangle -A OUTPUT ! --dest $LAN_NETWORK  -m owner --uid-owner $VPNUSER -j MARK --set-mark $MARK_ID -m comment --comment "${COMMENT}"
iptables -t mangle -A OUTPUT --dest $LAN_NETWORK -p udp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j MARK --set-mark $MARK_ID -m comment --comment "${COMMENT}"
iptables -t mangle -A OUTPUT --dest $LAN_NETWORK -p tcp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j MARK --set-mark $MARK_ID -m comment --comment "${COMMENT}"
iptables -t mangle -A OUTPUT ! --src $LAN_NETWORK -j MARK --set-mark $MARK_ID -m comment --comment "${COMMENT}"

# Allow responses
iptables -A INPUT -i $VPNIF -m conntrack --ctstate ESTABLISHED -j ACCEPT -m comment --comment "${COMMENT}"

# Allow bittorrent
iptables -A INPUT -i $VPNIF -p tcp --match multiport --dport $BITTORRENT_LISTEN_PORTS -j ACCEPT -m comment --comment "${COMMENT}"
iptables -A INPUT -i $VPNIF -p udp --match multiport --dport $BITTORRENT_LISTEN_PORTS -j ACCEPT -m comment --comment "${COMMENT}"

# Block everything incoming on $VPNIF
iptables -A INPUT -i $VPNIF -j REJECT -m comment --comment "${COMMENT}"

# Set DNS for $VPNUSER
iptables -t nat -A OUTPUT --dest $LAN_NETWORK -p udp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j DNAT --to-destination $DNS_IP1 -m comment --comment "${COMMENT}"
iptables -t nat -A OUTPUT --dest $LAN_NETWORK -p tcp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j DNAT --to-destination $DNS_IP1 -m comment --comment "${COMMENT}"
iptables -t nat -A OUTPUT --dest $LAN_NETWORK -p udp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j DNAT --to-destination $DNS_IP2 -m comment --comment "${COMMENT}"
iptables -t nat -A OUTPUT --dest $LAN_NETWORK -p tcp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j DNAT --to-destination $DNS_IP2 -m comment --comment "${COMMENT}"

# Let $VPNUSER access lo and $VPNIF
iptables -A OUTPUT -o lo -m owner --uid-owner $VPNUSER -j ACCEPT -m comment --comment "${COMMENT}"
iptables -A OUTPUT -o $VPNIF -m owner --uid-owner $VPNUSER -j ACCEPT -m comment --comment "${COMMENT}"

# All packets on $VPNIF needs to be masqueraded
iptables -t nat -A POSTROUTING -o $VPNIF -j MASQUERADE -m comment --comment "${COMMENT}"

# Reject connections from predator ip going over $NETIF
iptables -A OUTPUT ! --src $LAN_NETWORK -o $NETIF -j REJECT -m comment --comment "${COMMENT}"
