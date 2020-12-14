VPN for torrent traffic
==========================

This repo contains a collection of bash scripts for setting up routing torrent traffic through a VPN interface.

[user_filter](user_filter) contains scripts that setup a routing table and configure iptables to route all traffic from a specific user over the VPN interface.

OpenVPN
--------------------------

To use these scripts with OpenVPN:

1. Make a clone of the repo and set the correct values for the interfaces and user in vpn_base.sh.

2. Edit the OpenVPN client config and add this line:

 ```up "/path/to/repo/link_up_user_filter.sh"``` with the correct path to the cloned repo.

 To allow executing external scripts automatically when starting the OpenVPN client, run openvpn with the argument

 ```--script-security 2``` or add this line to the OpenVPN client config: ```script-security 2```

 By standard OpenVPN will accept alternative routing tables from the VPN server. Since we want to use a custom routing table we need to disable this
 by adding ```pull-filter ignore redirect-gateway``` to the OpenVPN client config.

3. Run openvpn
