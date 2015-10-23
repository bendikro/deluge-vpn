#!/usr/bin/env bash
source vpn_base.sh

LAN_IP=`get_nic_ip $NETIF`
SUBNET_MASK=`get_nic_subnet_mask $NETIF` # CIDR
LAN_NETWORK=`getnetmask $LAN_IP $SUBNET_MASK`
LAN_NETWORK="$LAN_NETWORK/$SUBNET_MASK" # Should be on the form 172.16.0.0/24

# For multiple ports, separate by comma: 6881,6889
# For port range, seperate by colon: 6881:6889
BITTORRENT_LISTEN_PORTS=6881:6889

DNS_PORT=53
# Use google DNS servers
DNS_IP1=8.8.4.4
DNS_IP2=8.8.8.8

iptables -F -t nat
iptables -F -t mangle
iptables -F -t filter

# Mark packets from $VPNUSER
iptables -t mangle -A OUTPUT ! --dest $LAN_NETWORK  -m owner --uid-owner $VPNUSER -j MARK --set-mark $MARK_ID
iptables -t mangle -A OUTPUT --dest $LAN_NETWORK -p udp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j MARK --set-mark $MARK_ID
iptables -t mangle -A OUTPUT --dest $LAN_NETWORK -p tcp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j MARK --set-mark $MARK_ID
iptables -t mangle -A OUTPUT ! --src $LAN_NETWORK -j MARK --set-mark $MARK_ID

# Allow responses
iptables -A INPUT -i $VPNIF -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Allow bittorrent
iptables -A INPUT -i $VPNIF -p tcp --match multiport --dport $BITTORRENT_LISTEN_PORTS -j ACCEPT
iptables -A INPUT -i $VPNIF -p udp --match multiport --dport $BITTORRENT_LISTEN_PORTS -j ACCEPT

# Block everything incoming on $VPNIF
iptables -A INPUT -i $VPNIF -j REJECT

# Set DNS for $VPNUSER
iptables -t nat -A OUTPUT --dest $LAN_NETWORK -p udp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j DNAT --to-destination $DNS_IP1
iptables -t nat -A OUTPUT --dest $LAN_NETWORK -p tcp --dport $DNS_PORT -m owner --uid-owner $VPNUSER -j DNAT --to-destination $DNS_IP2

# Let $VPNUSER access lo and $VPNIF
iptables -A OUTPUT -o lo -m owner --uid-owner $VPNUSER -j ACCEPT
iptables -A OUTPUT -o $VPNIF -m owner --uid-owner $VPNUSER -j ACCEPT

# All packets on $VPNIF needs to be masqueraded
iptables -t nat -A POSTROUTING -o $VPNIF -j MASQUERADE

# Reject connections from predator ip going over $NETIF
iptables -A OUTPUT ! --src $LAN_NETWORK -o $NETIF -j REJECT
