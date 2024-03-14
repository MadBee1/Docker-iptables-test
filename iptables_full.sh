#===== Firewall für WEBEX Server (apache) mit ipv4 & ipv6 =====

#!/bin/bash
 
# Autor:        Fabian Köhler
# Version:      1.1
# Datum:        21.09.2023
# Mail:         fabian.koehler@sulzer.de
# 
#
# Dieses Script lädt die Firewall Regeln für ein Lokales 
# Dual-Stack Firewall System (IPv4/IPv6)
# 
# ========================================================
 
## Variablen
IPT='/sbin/iptables'
IPT6='/sbin/ip6tables'
CONNTRACK='/usr/sbin/conntrack'
ECHO='/bin/echo'
SYSCTL='/sbin/sysctl'
MODP='/sbin/modprobe'
 
# Devices
LAN='ens224'
LANADDRESS='172.31.254.12'
LANNETZ='172.31.254.0/24'
WAN='ens192'
WANADDRESS='193.28.64.14'
WANNETZ='193.28.64.0/24'

INTRA='172.0.0.0/16'
INTRA2='172.21.0.0/21'
INTRA3='172.17.0.0/16'


case $1 in
    start)
        # Set default policies to DROP for security
        $IPT -P FORWARD DROP
        $IPT6 -P FORWARD DROP

        # Flush existing rules to start fresh
        $IPT -F DOCKER-USER
        $IPT6 -F DOCKER-USER

        # Allow loopback interface traffic
        $IPT -I DOCKER-USER -i lo -j ACCEPT
        $IPT6 -I DOCKER-USER -i lo -j ACCEPT

        # Allow established and related connections
        $IPT -I DOCKER-USER -m state --state ESTABLISHED,RELATED -j ACCEPT
        $IPT6 -I DOCKER-USER -m state --state ESTABLISHED,RELATED -j ACCEPT

        # System settings
        $SYSCTL -w net.ipv4.icmp_echo_ignore_broadcasts=1
        $SYSCTL -w net.ipv4.conf.all.rp_filter=1
        $SYSCTL -w net.ipv4.conf.all.accept_source_route=0
        $SYSCTL -w net.ipv4.ip_forward=0

        # Allow ICMP and traceroute
        $IPT -I DOCKER-USER -m state --state NEW -p icmp --icmp-type echo-request -j ACCEPT
        $IPT -I DOCKER-USER -m state --state NEW -p udp -m multiport --dports 33434:33523 -j ACCEPT

        # DNS settings
        for DNSv4 in 8.8.8.8 8.8.4.4
        do
            $IPT -I DOCKER-USER -o $WAN -m state --state NEW -p udp --dport 53 -d ${DNSv4} -j ACCEPT
            $IPT -I DOCKER-USER -o $WAN -m state --state NEW -p tcp --dport 53 -d ${DNSv4} -j ACCEPT
        done

        # Allow HTTP and HTTPS
        $IPT -I DOCKER-USER -m state --state NEW -p tcp --dport 80 -j ACCEPT
        $IPT -I DOCKER-USER -m state --state NEW -p tcp --dport 443 -j ACCEPT
        $IPT6 -I DOCKER-USER -m state --state NEW -p tcp --dport 80 -j ACCEPT
        $IPT6 -I DOCKER-USER -m state --state NEW -p tcp --dport 443 -j ACCEPT

        # Incoming access rules
        $IPT -I DOCKER-USER -i $LAN -p tcp --dport 113 -j REJECT
        $IPT -I DOCKER-USER -i $LAN -m state --state NEW -p icmp --icmp-type echo-request -j ACCEPT

        # SSH rules
        $IPT -I DOCKER-USER -i $LAN -p tcp --dport 22 -s $INTRA -m state --state NEW -j ACCEPT
        $IPT -I DOCKER-USER -i $LAN -p tcp --dport 22 -s $INTRA2 -m state --state NEW -j ACCEPT
        $IPT -I DOCKER-USER -i $LAN -p tcp --dport 22 -s $INTRA3 -m state --state NEW -j ACCEPT

        # Web access rules
        $IPT -I DOCKER-USER -i $LAN -p tcp --dport 443 -m state --state NEW -j ACCEPT -m comment --comment "Allow incoming to LAN for Port 443 P-Stage"
        $IPT -I DOCKER-USER -i $LAN -p tcp --dport 8443 -m state --state NEW -j ACCEPT -m comment --comment "Allow incoming to LAN for Port 8443 DEV-Stage"
        $IPT -I DOCKER-USER -i $WAN -p tcp --dport 443 -m state --state NEW -j ACCEPT -m comment --comment "Allow incoming to WAN for Port 443 P-Stage"

        # Check status
        $0 status
        ;;
    stop)
        # Flush DOCKER-USER rules
        $IPT -F DOCKER-USER
        $IPT6 -F DOCKER-USER

        # Set default policies to ACCEPT for cleanup
        $IPT -P FORWARD ACCEPT
        $IPT6 -P FORWARD ACCEPT

        # System settings
        $SYSCTL -w net.ipv6.conf.all.forwarding=0
        $SYSCTL -w net.ipv4.ip_forward=0
        $SYSCTL -w net.ipv4.icmp_echo_ignore_broadcasts=0
        $SYSCTL -w net.ipv4.conf.all.accept_source_route=1
        $SYSCTL -w net.ipv4.conf.all.rp_filter=0

        # Check status
        $0 status
        ;;
    status)
        echo
        echo "============================= IPv4 ============================="
        $IPT -vnL DOCKER-USER --line-numbers
        echo
        echo "============================= IPv6 ============================="
        $IPT6 -vnL DOCKER-USER --line-numbers
        ;;
    restart)
        $0 stop > /dev/null 2>&1; sleep 2; $0 start
        ;;
    *)
        $ECHO $0 'USAGE: { start | stop | restart | status }'
        ;;
esac