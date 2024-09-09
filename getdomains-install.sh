#!/bin/sh

#set -x

check_repo() {
    printf "\033[32;1mChecking OpenWrt repo availability...\033[0m\n"
    opkg update | grep -q "Failed to download" && printf "\033[32;1mopkg failed. Check internet or date. Command for force ntp sync: ntpd -p ptbtime1.ptb.de\033[0m\n" && exit 1
}

route_vpn () {
    if [ "$TUNNEL" == wg ]; then
cat << EOF > /etc/hotplug.d/iface/30-vpnroute
#!/bin/sh

ip route add table vpn default dev wg0
EOF
    elif [ "$TUNNEL" == awg ]; then
cat << EOF > /etc/hotplug.d/iface/30-vpnroute
#!/bin/sh

ip route add table vpn default dev awg0
EOF
    elif [ "$TUNNEL" == singbox ] || [ "$TUNNEL" == ovpn ] || [ "$TUNNEL" == tun2socks ]; then
cat << EOF > /etc/hotplug.d/iface/30-vpnroute
#!/bin/sh

sleep 10
ip route add table vpn default dev tun0
EOF
    fi
}

add_mark() {
    grep -q "99 vpn" /etc/iproute2/rt_tables || echo '99 vpn' >> /etc/iproute2/rt_tables
    
    if ! uci show network | grep -q mark0x1; then
        printf "\033[32;1mConfigure mark rule\033[0m\n"
        uci add network rule
        uci set network.@rule[-1].name='mark0x1'
        uci set network.@rule[-1].mark='0x1'
        uci set network.@rule[-1].priority='100'
        uci set network.@rule[-1].lookup='vpn'
        uci commit
    fi
}

add_tunnel() {
    echo "We can automatically configure only Wireguard and Amnezia WireGuard. OpenVPN, Sing-box(Shadowsocks2022, VMess, VLESS, etc) and tun2socks will need to be configured manually"
    echo "Select a tunnel:"
    echo "1) WireGuard"
    echo "2) OpenVPN"
    echo "3) Sing-box"
    echo "4) tun2socks"
    echo "5) wgForYoutube"
    echo "6) Amnezia WireGuard"
    echo "7) Amnezia WireGuard For Youtube"
    echo "8) Skip this step"

    while true; do
    read -r -p '' TUNNEL
        case $TUNNEL in 

        1) 
            TUNNEL=wg
            break
            ;;

        2)
            TUNNEL=ovpn
            break
            ;;

        3) 
            TUNNEL=singbox
            break
            ;;

        4) 
            TUNNEL=tun2socks
            break
            ;;

        5) 
            TUNNEL=wgForYoutube
            break
            ;;

        6) 
            TUNNEL=awg
            break
            ;;

        7) 
            TUNNEL=awgForYoutube
            break
            ;;

        8)
            echo "Skip"
            TUNNEL=0
            break
            ;;

        *)
            echo "Choose from the following options"
            ;;
        esac
    done

    if [ "$TUNNEL" == 'wg' ]; then
        printf "\033[32;1mConfigure WireGuard\033[0m\n"
        if opkg list-installed | grep -q wireguard-tools; then
            echo "Wireguard already installed"
        else
            echo "Installed wg..."
            opkg install wireguard-tools
        fi

        route_vpn

        read -r -p "Enter the private key (from [Interface]):"$'\n' WG_PRIVATE_KEY

        while true; do
            read -r -p "Enter internal IP address with subnet, example 192.168.100.5/24 (from [Interface]):"$'\n' WG_IP
            if echo "$WG_IP" | egrep -oq '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+$'; then
                break
            else
                echo "This IP is not valid. Please repeat"
            fi
        done

        read -r -p "Enter the public key (from [Peer]):"$'\n' WG_PUBLIC_KEY
        read -r -p "If use PresharedKey, Enter this (from [Peer]). If your don't use leave blank:"$'\n' WG_PRESHARED_KEY
        read -r -p "Enter Endpoint host without port (Domain or IP) (from [Peer]):"$'\n' WG_ENDPOINT

        read -r -p "Enter Endpoint host port (from [Peer]) [51820]:"$'\n' WG_ENDPOINT_PORT
        WG_ENDPOINT_PORT=${WG_ENDPOINT_PORT:-51820}
        if [ "$WG_ENDPOINT_PORT" = '51820' ]; then
            echo $WG_ENDPOINT_PORT
        fi
        
        uci set network.wg0=interface
        uci set network.wg0.proto='wireguard'
        uci set network.wg0.private_key=$WG_PRIVATE_KEY
        uci set network.wg0.listen_port='51820'
        uci set network.wg0.addresses=$WG_IP

        if ! uci show network | grep -q wireguard_wg0; then
            uci add network wireguard_wg0
        fi
        uci set network.@wireguard_wg0[0]=wireguard_wg0
        uci set network.@wireguard_wg0[0].name='wg0_client'
        uci set network.@wireguard_wg0[0].public_key=$WG_PUBLIC_KEY
        uci set network.@wireguard_wg0[0].preshared_key=$WG_PRESHARED_KEY
        uci set network.@wireguard_wg0[0].route_allowed_ips='0'
        uci set network.@wireguard_wg0[0].persistent_keepalive='25'
        uci set network.@wireguard_wg0[0].endpoint_host=$WG_ENDPOINT
        uci set network.@wireguard_wg0[0].allowed_ips='0.0.0.0/0'
        uci set network.@wireguard_wg0[0].endpoint_port=$WG_ENDPOINT_PORT
        uci commit
    fi

    if [ "$TUNNEL" == 'ovpn' ]; then
        if opkg list-installed | grep -q openvpn-openssl; then
            echo "OpenVPN already installed"
        else
            echo "Installed openvpn"
            opkg install openvpn-openssl
        fi
        printf "\033[32;1mConfigure route for OpenVPN\033[0m\n"
        route_vpn
    fi

    if [ "$TUNNEL" == 'singbox' ]; then
        if opkg list-installed | grep -q sing-box; then
            echo "Sing-box already installed"
        else
            AVAILABLE_SPACE=$(df / | awk 'NR>1 { print $4 }')
            if  [[ "$AVAILABLE_SPACE" -gt 2000 ]]; then
                echo "Installed sing-box"
                opkg install sing-box
            else
                printf "\033[31;1mNo free space for a sing-box. Sing-box is not installed.\033[0m\n"
                exit 1
            fi
        fi
        if grep -q "option enabled '0'" /etc/config/sing-box; then
            sed -i "s/	option enabled \'0\'/	option enabled \'1\'/" /etc/config/sing-box
        fi
        if grep -q "option user 'sing-box'" /etc/config/sing-box; then
            sed -i "s/	option user \'sing-box\'/	option user \'root\'/" /etc/config/sing-box
        fi
        if grep -q "tun0" /etc/sing-box/config.json; then
        printf "\033[32;1mConfig /etc/sing-box/config.json already exists\033[0m\n"
        else
cat << 'EOF' > /etc/sing-box/config.json
{
  "log": {
    "level": "debug"
  },
  "inbounds": [
    {
      "type": "tun",
      "interface_name": "tun0",
      "domain_strategy": "ipv4_only",
      "inet4_address": "172.16.250.1/30",
      "auto_route": false,
      "strict_route": false,
      "sniff": true 
   }
  ],
  "outbounds": [
    {
      "type": "$TYPE",
      "server": "$HOST",
      "server_port": $PORT,
      "method": "$METHOD",
      "password": "$PASS"
    }
  ],
  "route": {
    "auto_detect_interface": true
  }
}
EOF
        printf "\033[32;1mCreate template config in /etc/sing-box/config.json. Edit it manually. Official doc: https://sing-box.sagernet.org/configuration/outbound/\033[0m\n"
        printf "\033[32;1mOfficial doc: https://sing-box.sagernet.org/configuration/outbound/\033[0m\n"
        printf "\033[32;1mManual with example SS: https://cli.co/Badmn3K \033[0m\n"

        fi
        printf "\033[32;1mConfigure route for Sing-box\033[0m\n"
        route_vpn
    fi

    if [ "$TUNNEL" == 'wgForYoutube' ]; then
        add_internal_wg Wireguard
    fi

    if [ "$TUNNEL" == 'awgForYoutube' ]; then
        add_internal_wg AmneziaWG
    fi

    if [ "$TUNNEL" == 'awg' ]; then
        printf "\033[32;1mConfigure Amnezia WireGuard\033[0m\n"

        install_awg_packages

        route_vpn

        read -r -p "Enter the private key (from [Interface]):"$'\n' AWG_PRIVATE_KEY

        while true; do
            read -r -p "Enter internal IP address with subnet, example 192.168.100.5/24 (Address from [Interface]):"$'\n' AWG_IP
            if echo "$AWG_IP" | egrep -oq '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+$'; then
                break
            else
                echo "This IP is not valid. Please repeat"
            fi
        done

        read -r -p "Enter Jc value (from [Interface]):"$'\n' AWG_JC
        read -r -p "Enter Jmin value (from [Interface]):"$'\n' AWG_JMIN
        read -r -p "Enter Jmax value (from [Interface]):"$'\n' AWG_JMAX
        read -r -p "Enter S1 value (from [Interface]):"$'\n' AWG_S1
        read -r -p "Enter S2 value (from [Interface]):"$'\n' AWG_S2
        read -r -p "Enter H1 value (from [Interface]):"$'\n' AWG_H1
        read -r -p "Enter H2 value (from [Interface]):"$'\n' AWG_H2
        read -r -p "Enter H3 value (from [Interface]):"$'\n' AWG_H3
        read -r -p "Enter H4 value (from [Interface]):"$'\n' AWG_H4
    
        read -r -p "Enter the public key (from [Peer]):"$'\n' AWG_PUBLIC_KEY
        read -r -p "If use PresharedKey, Enter this (from [Peer]). If your don't use leave blank:"$'\n' AWG_PRESHARED_KEY
        read -r -p "Enter Endpoint host without port (Domain or IP) (from [Peer]):"$'\n' AWG_ENDPOINT

        read -r -p "Enter Endpoint host port (from [Peer]) [51820]:"$'\n' AWG_ENDPOINT_PORT
        AWG_ENDPOINT_PORT=${AWG_ENDPOINT_PORT:-51820}
        if [ "$AWG_ENDPOINT_PORT" = '51820' ]; then
            echo $AWG_ENDPOINT_PORT
        fi
        
        uci set network.awg0=interface
        uci set network.awg0.proto='amneziawg'
        uci set network.awg0.private_key=$AWG_PRIVATE_KEY
        uci set network.awg0.listen_port='51820'
        uci set network.awg0.addresses=$AWG_IP

        uci set network.awg0.awg_jc=$AWG_JC
        uci set network.awg0.awg_jmin=$AWG_JMIN
        uci set network.awg0.awg_jmax=$AWG_JMAX
        uci set network.awg0.awg_s1=$AWG_S1
        uci set network.awg0.awg_s2=$AWG_S2
        uci set network.awg0.awg_h1=$AWG_H1
        uci set network.awg0.awg_h2=$AWG_H2
        uci set network.awg0.awg_h3=$AWG_H3
        uci set network.awg0.awg_h4=$AWG_H4

        if ! uci show network | grep -q amneziawg_awg0; then
            uci add network amneziawg_awg0
        fi

        uci set network.@amneziawg_awg0[0]=amneziawg_awg0
        uci set network.@amneziawg_awg0[0].name='awg0_client'
        uci set network.@amneziawg_awg0[0].public_key=$AWG_PUBLIC_KEY
        uci set network.@amneziawg_awg0[0].preshared_key=$AWG_PRESHARED_KEY
        uci set network.@amneziawg_awg0[0].route_allowed_ips='0'
        uci set network.@amneziawg_awg0[0].persistent_keepalive='25'
        uci set network.@amneziawg_awg0[0].endpoint_host=$AWG_ENDPOINT
        uci set network.@amneziawg_awg0[0].allowed_ips='0.0.0.0/0'
        uci set network.@amneziawg_awg0[0].endpoint_port=$AWG_ENDPOINT_PORT
        uci commit
    fi

}

dnsmasqfull() {
    if opkg list-installed | grep -q dnsmasq-full; then
        printf "\033[32;1mdnsmasq-full already installed\033[0m\n"
    else
        printf "\033[32;1mInstalled dnsmasq-full\033[0m\n"
        cd /tmp/ && opkg download dnsmasq-full
        opkg remove dnsmasq && opkg install dnsmasq-full --cache /tmp/

        [ -f /etc/config/dhcp-opkg ] && cp /etc/config/dhcp /etc/config/dhcp-old && mv /etc/config/dhcp-opkg /etc/config/dhcp
fi
}

remove_forwarding() {
    if [ ! -z "$forward_id" ]; then
        while uci -q delete firewall.@forwarding[$forward_id]; do :; done
    fi
}

add_zone() {
    if  [ "$TUNNEL" == 0 ]; then
        printf "\033[32;1mZone setting skipped\033[0m\n"
    elif uci show firewall | grep -q "@zone.*name='$TUNNEL'"; then
        printf "\033[32;1mZone already exist\033[0m\n"
    else
        printf "\033[32;1mCreate zone\033[0m\n"

        # Delete exists zone
        zone_tun_id=$(uci show firewall | grep -E '@zone.*tun0' | awk -F '[][{}]' '{print $2}' | head -n 1)
        if [ "$zone_tun_id" == 0 ] || [ "$zone_tun_id" == 1 ]; then
            printf "\033[32;1mtun0 zone has an identifier of 0 or 1. That's not ok. Fix your firewall. lan and wan zones should have identifiers 0 and 1. \033[0m\n"
            exit 1
        fi
        if [ ! -z "$zone_tun_id" ]; then
            while uci -q delete firewall.@zone[$zone_tun_id]; do :; done
        fi

        zone_wg_id=$(uci show firewall | grep -E '@zone.*wg0' | awk -F '[][{}]' '{print $2}' | head -n 1)
        if [ "$zone_wg_id" == 0 ] || [ "$zone_wg_id" == 1 ]; then
            printf "\033[32;1mwg0 zone has an identifier of 0 or 1. That's not ok. Fix your firewall. lan and wan zones should have identifiers 0 and 1. \033[0m\n"
            exit 1
        fi
        if [ ! -z "$zone_wg_id" ]; then
            while uci -q delete firewall.@zone[$zone_wg_id]; do :; done
        fi

        zone_awg_id=$(uci show firewall | grep -E '@zone.*awg0' | awk -F '[][{}]' '{print $2}' | head -n 1)
        if [ "$zone_awg_id" == 0 ] || [ "$zone_awg_id" == 1 ]; then
            printf "\033[32;1mawg0 zone has an identifier of 0 or 1. That's not ok. Fix your firewall. lan and wan zones should have identifiers 0 and 1. \033[0m\n"
            exit 1
        fi
        if [ ! -z "$zone_awg_id" ]; then
            while uci -q delete firewall.@zone[$zone_awg_id]; do :; done
        fi

        uci add firewall zone
        uci set firewall.@zone[-1].name="$TUNNEL"
        if [ "$TUNNEL" == wg ]; then
            uci set firewall.@zone[-1].network='wg0'
        elif [ "$TUNNEL" == awg ]; then
            uci set firewall.@zone[-1].network='awg0'
        elif [ "$TUNNEL" == singbox ] || [ "$TUNNEL" == ovpn ] || [ "$TUNNEL" == tun2socks ]; then
            uci set firewall.@zone[-1].device='tun0'
        fi
        if [ "$TUNNEL" == wg ] || [ "$TUNNEL" == awg ] || [ "$TUNNEL" == ovpn ] || [ "$TUNNEL" == tun2socks ]; then
            uci set firewall.@zone[-1].forward='REJECT'
            uci set firewall.@zone[-1].output='ACCEPT'
            uci set firewall.@zone[-1].input='REJECT'
        elif [ "$TUNNEL" == singbox ]; then
            uci set firewall.@zone[-1].forward='ACCEPT'
            uci set firewall.@zone[-1].output='ACCEPT'
            uci set firewall.@zone[-1].input='ACCEPT'
        fi
        uci set firewall.@zone[-1].masq='1'
        uci set firewall.@zone[-1].mtu_fix='1'
        uci set firewall.@zone[-1].family='ipv4'
        uci commit firewall
    fi
    
    if [ "$TUNNEL" == 0 ]; then
        printf "\033[32;1mForwarding setting skipped\033[0m\n"
    elif uci show firewall | grep -q "@forwarding.*name='$TUNNEL-lan'"; then
        printf "\033[32;1mForwarding already configured\033[0m\n"
    else
        printf "\033[32;1mConfigured forwarding\033[0m\n"
        # Delete exists forwarding
        if [[ $TUNNEL != "wg" ]]; then
            forward_id=$(uci show firewall | grep -E "@forwarding.*dest='wg'" | awk -F '[][{}]' '{print $2}' | head -n 1)
            remove_forwarding
        fi

        if [[ $TUNNEL != "awg" ]]; then
            forward_id=$(uci show firewall | grep -E "@forwarding.*dest='awg'" | awk -F '[][{}]' '{print $2}' | head -n 1)
            remove_forwarding
        fi

        if [[ $TUNNEL != "ovpn" ]]; then
            forward_id=$(uci show firewall | grep -E "@forwarding.*dest='ovpn'" | awk -F '[][{}]' '{print $2}' | head -n 1)
            remove_forwarding
        fi

        if [[ $TUNNEL != "singbox" ]]; then
            forward_id=$(uci show firewall | grep -E "@forwarding.*dest='singbox'" | awk -F '[][{}]' '{print $2}' | head -n 1)
            remove_forwarding
        fi

        if [[ $TUNNEL != "tun2socks" ]]; then
            forward_id=$(uci show firewall | grep -E "@forwarding.*dest='tun2socks'" | awk -F '[][{}]' '{print $2}' | head -n 1)
            remove_forwarding
        fi

        uci add firewall forwarding
        uci set firewall.@forwarding[-1]=forwarding
        uci set firewall.@forwarding[-1].name="$TUNNEL-lan"
        uci set firewall.@forwarding[-1].dest="$TUNNEL"
        uci set firewall.@forwarding[-1].src='lan'
        uci set firewall.@forwarding[-1].family='ipv4'
        uci commit firewall
    fi
}

show_manual() {
    if [ "$TUNNEL" == tun2socks ]; then
        printf "\033[42;1mZone for tun2socks cofigured. But you need to set up the tunnel yourself.\033[0m\n"
        echo "Use this manual: https://cli.co/VNZISEM"
    elif [ "$TUNNEL" == ovpn ]; then
        printf "\033[42;1mZone for OpenVPN cofigured. But you need to set up the tunnel yourself.\033[0m\n"
        echo "Use this manual: https://itdog.info/nastrojka-klienta-openvpn-na-openwrt/"
    fi
}

add_set() {
    if uci show firewall | grep -q "@ipset.*name='vpn_domains'"; then
        printf "\033[32;1mSet already exist\033[0m\n"
    else
        printf "\033[32;1mCreate set\033[0m\n"
        uci add firewall ipset
        uci set firewall.@ipset[-1].name='vpn_domains'
        uci set firewall.@ipset[-1].match='dst_net'
        uci commit
    fi
    if uci show firewall | grep -q "@rule.*name='mark_domains'"; then
        printf "\033[32;1mRule for set already exist\033[0m\n"
    else
        printf "\033[32;1mCreate rule set\033[0m\n"
        uci add firewall rule
        uci set firewall.@rule[-1]=rule
        uci set firewall.@rule[-1].name='mark_domains'
        uci set firewall.@rule[-1].src='lan'
        uci set firewall.@rule[-1].dest='*'
        uci set firewall.@rule[-1].proto='all'
        uci set firewall.@rule[-1].ipset='vpn_domains'
        uci set firewall.@rule[-1].set_mark='0x1'
        uci set firewall.@rule[-1].target='MARK'
        uci set firewall.@rule[-1].family='ipv4'
        uci commit
    fi
}

add_dns_resolver() {
    echo "Configure DNSCrypt2 or Stubby? It does matter if your ISP is spoofing DNS requests"
    DISK=$(df -m / | awk 'NR==2{ print $2 }')
    if [[ "$DISK" -lt 32 ]]; then 
        printf "\033[31;1mYour router a disk have less than 32MB. It is not recommended to install DNSCrypt, it takes 10MB\033[0m\n"
    fi
    echo "Select:"
    echo "1) No [Default]"
    echo "2) DNSCrypt2 (10.7M)"
    echo "3) Stubby (36K)"

    while true; do
    read -r -p '' DNS_RESOLVER
        case $DNS_RESOLVER in 

        1) 
            echo "Skiped"
            break
            ;;

        2)
            DNS_RESOLVER=DNSCRYPT
            break
            ;;

        3) 
            DNS_RESOLVER=STUBBY
            break
            ;;

        *)
            echo "Choose from the following options"
            ;;
        esac
    done

    if [ "$DNS_RESOLVER" == 'DNSCRYPT' ]; then
        if opkg list-installed | grep -q dnscrypt-proxy2; then
            printf "\033[32;1mDNSCrypt2 already installed\033[0m\n"
        else
            printf "\033[32;1mInstalled dnscrypt-proxy2\033[0m\n"
            opkg install dnscrypt-proxy2
            if grep -q "# server_names" /etc/dnscrypt-proxy2/dnscrypt-proxy.toml; then
                sed -i "s/^# server_names =.*/server_names = [\'google\', \'cloudflare\', \'scaleway-fr\', \'yandex\']/g" /etc/dnscrypt-proxy2/dnscrypt-proxy.toml
            fi

            printf "\033[32;1mDNSCrypt restart\033[0m\n"
            service dnscrypt-proxy restart
            printf "\033[32;1mDNSCrypt needs to load the relays list. Please wait\033[0m\n"
            sleep 30

            if [ -f /etc/dnscrypt-proxy2/relays.md ]; then
                uci set dhcp.@dnsmasq[0].noresolv="1"
                uci -q delete dhcp.@dnsmasq[0].server
                uci add_list dhcp.@dnsmasq[0].server="127.0.0.53#53"
                uci add_list dhcp.@dnsmasq[0].server='/use-application-dns.net/'
                uci commit dhcp
                
                printf "\033[32;1mDnsmasq restart\033[0m\n"

                /etc/init.d/dnsmasq restart
            else
                printf "\033[31;1mDNSCrypt not download list on /etc/dnscrypt-proxy2. Repeat install DNSCrypt by script.\033[0m\n"
            fi
    fi

    fi

    if [ "$DNS_RESOLVER" == 'STUBBY' ]; then
        printf "\033[32;1mConfigure Stubby\033[0m\n"

        if opkg list-installed | grep -q stubby; then
            printf "\033[32;1mStubby already installed\033[0m\n"
        else
            printf "\033[32;1mInstalled stubby\033[0m\n"
            opkg install stubby

            printf "\033[32;1mConfigure Dnsmasq for Stubby\033[0m\n"
            uci set dhcp.@dnsmasq[0].noresolv="1"
            uci -q delete dhcp.@dnsmasq[0].server
            uci add_list dhcp.@dnsmasq[0].server="127.0.0.1#5453"
            uci add_list dhcp.@dnsmasq[0].server='/use-application-dns.net/'
            uci commit dhcp

            printf "\033[32;1mDnsmasq restart\033[0m\n"

            /etc/init.d/dnsmasq restart
        fi
    fi
}

add_packages() {
    if opkg list-installed | grep -q "curl -"; then
        printf "\033[32;1mCurl already installed\033[0m\n"
    else
        printf "\033[32;1mInstall curl\033[0m\n"
        opkg install curl
    fi

    if opkg list-installed | grep -q nano; then
        printf "\033[32;1mNano already installed\033[0m\n"
    else
        printf "\033[32;1mInstall nano\033[0m\n"
        opkg install nano
    fi
}

add_getdomains() {
    echo "Choose you country"
    echo "Select:"
    echo "1) Russia inside. You are inside Russia"
    echo "2) Russia outside. You are outside of Russia, but you need access to Russian resources"
    echo "3) Ukraine. uablacklist.net list"
    echo "4) Skip script creation"

    while true; do
    read -r -p '' COUNTRY
        case $COUNTRY in 

        1) 
            COUNTRY=russia_inside
            break
            ;;

        2)
            COUNTRY=russia_outside
            break
            ;;

        3) 
            COUNTRY=ukraine
            break
            ;;

        4) 
            echo "Skiped"
            COUNTRY=0
            break
            ;;

        *)
            echo "Choose from the following options"
            ;;
        esac
    done

    if [ "$COUNTRY" == 'russia_inside' ]; then
        EOF_DOMAINS=DOMAINS=https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/inside-dnsmasq-nfset.lst
    elif [ "$COUNTRY" == 'russia_outside' ]; then
        EOF_DOMAINS=DOMAINS=https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Russia/outside-dnsmasq-nfset.lst
    elif [ "$COUNTRY" == 'ukraine' ]; then
        EOF_DOMAINS=DOMAINS=https://raw.githubusercontent.com/itdoginfo/allow-domains/main/Ukraine/inside-dnsmasq-nfset.lst
    fi

    if [ "$COUNTRY" != '0' ]; then
        printf "\033[32;1mCreate script /etc/init.d/getdomains\033[0m\n"

cat << EOF > /etc/init.d/getdomains
#!/bin/sh /etc/rc.common

START=99

start () {
    $EOF_DOMAINS
EOF
cat << 'EOF' >> /etc/init.d/getdomains
    count=0
    while true; do
        if curl -m 3 github.com; then
            curl -f $DOMAINS --output /tmp/dnsmasq.d/domains.lst
            break
        else
            echo "GitHub is not available. Check the internet availability [$count]"
            count=$((count+1))
        fi
    done

    if dnsmasq --conf-file=/tmp/dnsmasq.d/domains.lst --test 2>&1 | grep -q "syntax check OK"; then
        /etc/init.d/dnsmasq restart
    fi
}
EOF

        chmod +x /etc/init.d/getdomains
        /etc/init.d/getdomains enable

        if crontab -l | grep -q /etc/init.d/getdomains; then
            printf "\033[32;1mCrontab already configured\033[0m\n"

        else
            crontab -l | { cat; echo "0 */8 * * * /etc/init.d/getdomains start"; } | crontab -
            printf "\033[32;1mIgnore this error. This is normal for a new installation\033[0m\n"
            /etc/init.d/cron restart
        fi

        printf "\033[32;1mStart script\033[0m\n"

        /etc/init.d/getdomains start
    fi
}

add_internal_wg() {
    PROTOCOL_NAME=$1
    printf "\033[32;1mConfigure ${PROTOCOL_NAME}\033[0m\n"
    if [ "$PROTOCOL_NAME" = 'Wireguard' ]; then
        INTERFACE_NAME="wg1"
        CONFIG_NAME="wireguard_wg1"
        PROTO="wireguard"
        ZONE_NAME="wg_internal"

        if opkg list-installed | grep -q wireguard-tools; then
            echo "Wireguard already installed"
        else
            echo "Installed wg..."
            opkg install wireguard-tools
        fi
    fi

    if [ "$PROTOCOL_NAME" = 'AmneziaWG' ]; then
        INTERFACE_NAME="awg1"
        CONFIG_NAME="amneziawg_awg1"
        PROTO="amneziawg"
        ZONE_NAME="awg_internal"

        install_awg_packages
    fi

    read -r -p "Enter the private key (from [Interface]):"$'\n' WG_PRIVATE_KEY_INT

    while true; do
        read -r -p "Enter internal IP address with subnet, example 192.168.100.5/24 (from [Interface]):"$'\n' WG_IP
        if echo "$WG_IP" | egrep -oq '^([0-9]{1,3}\.){3}[0-9]{1,3}/[0-9]+$'; then
            break
        else
            echo "This IP is not valid. Please repeat"
        fi
    done

    read -r -p "Enter the public key (from [Peer]):"$'\n' WG_PUBLIC_KEY_INT
    read -r -p "If use PresharedKey, Enter this (from [Peer]). If your don't use leave blank:"$'\n' WG_PRESHARED_KEY_INT
    read -r -p "Enter Endpoint host without port (Domain or IP) (from [Peer]):"$'\n' WG_ENDPOINT_INT

    read -r -p "Enter Endpoint host port (from [Peer]) [51820]:"$'\n' WG_ENDPOINT_PORT_INT
    WG_ENDPOINT_PORT_INT=${WG_ENDPOINT_PORT_INT:-51820}
    if [ "$WG_ENDPOINT_PORT_INT" = '51820' ]; then
        echo $WG_ENDPOINT_PORT_INT
    fi

    if [ "$PROTOCOL_NAME" = 'AmneziaWG' ]; then
        read -r -p "Enter Jc value (from [Interface]):"$'\n' AWG_JC
        read -r -p "Enter Jmin value (from [Interface]):"$'\n' AWG_JMIN
        read -r -p "Enter Jmax value (from [Interface]):"$'\n' AWG_JMAX
        read -r -p "Enter S1 value (from [Interface]):"$'\n' AWG_S1
        read -r -p "Enter S2 value (from [Interface]):"$'\n' AWG_S2
        read -r -p "Enter H1 value (from [Interface]):"$'\n' AWG_H1
        read -r -p "Enter H2 value (from [Interface]):"$'\n' AWG_H2
        read -r -p "Enter H3 value (from [Interface]):"$'\n' AWG_H3
        read -r -p "Enter H4 value (from [Interface]):"$'\n' AWG_H4
    fi
    
    uci set network.${INTERFACE_NAME}=interface
    uci set network.${INTERFACE_NAME}.proto=$PROTO
    uci set network.${INTERFACE_NAME}.private_key=$WG_PRIVATE_KEY_INT
    uci set network.${INTERFACE_NAME}.listen_port='51821'
    uci set network.${INTERFACE_NAME}.addresses=$WG_IP

    if [ "$PROTOCOL_NAME" = 'AmneziaWG' ]; then
        uci set network.${INTERFACE_NAME}.awg_jc=$AWG_JC
        uci set network.${INTERFACE_NAME}.awg_jmin=$AWG_JMIN
        uci set network.${INTERFACE_NAME}.awg_jmax=$AWG_JMAX
        uci set network.${INTERFACE_NAME}.awg_s1=$AWG_S1
        uci set network.${INTERFACE_NAME}.awg_s2=$AWG_S2
        uci set network.${INTERFACE_NAME}.awg_h1=$AWG_H1
        uci set network.${INTERFACE_NAME}.awg_h2=$AWG_H2
        uci set network.${INTERFACE_NAME}.awg_h3=$AWG_H3
        uci set network.${INTERFACE_NAME}.awg_h4=$AWG_H4
    fi

    if ! uci show network | grep -q ${CONFIG_NAME}; then
        uci add network ${CONFIG_NAME}
    fi

    uci set network.@${CONFIG_NAME}[0]=$CONFIG_NAME
    uci set network.@${CONFIG_NAME}[0].name="${INTERFACE_NAME}_client"
    uci set network.@${CONFIG_NAME}[0].public_key=$WG_PUBLIC_KEY_INT
    uci set network.@${CONFIG_NAME}[0].preshared_key=$WG_PRESHARED_KEY_INT
    uci set network.@${CONFIG_NAME}[0].route_allowed_ips='0'
    uci set network.@${CONFIG_NAME}[0].persistent_keepalive='25'
    uci set network.@${CONFIG_NAME}[0].endpoint_host=$WG_ENDPOINT_INT
    uci set network.@${CONFIG_NAME}[0].allowed_ips='0.0.0.0/0'
    uci set network.@${CONFIG_NAME}[0].endpoint_port=$WG_ENDPOINT_PORT_INT
    uci commit network

    grep -q "110 vpninternal" /etc/iproute2/rt_tables || echo '110 vpninternal' >> /etc/iproute2/rt_tables

    if ! uci show network | grep -q mark0x2; then
        printf "\033[32;1mConfigure mark rule\033[0m\n"
        uci add network rule
        uci set network.@rule[-1].name='mark0x2'
        uci set network.@rule[-1].mark='0x2'
        uci set network.@rule[-1].priority='110'
        uci set network.@rule[-1].lookup='vpninternal'
        uci commit
    fi

    if ! uci show network | grep -q vpn_route_internal; then
        printf "\033[32;1mAdd route\033[0m\n"
        uci set network.vpn_route_internal=route
        uci set network.vpn_route_internal.name='vpninternal'
        uci set network.vpn_route_internal.interface=$INTERFACE_NAME
        uci set network.vpn_route_internal.table='vpninternal'
        uci set network.vpn_route_internal.target='0.0.0.0/0'
        uci commit network
    fi

    if ! uci show firewall | grep -q "@zone.*name='${ZONE_NAME}'"; then
        printf "\033[32;1mZone Create\033[0m\n"
        uci add firewall zone
        uci set firewall.@zone[-1].name=$ZONE_NAME
        uci set firewall.@zone[-1].network=$INTERFACE_NAME
        uci set firewall.@zone[-1].forward='REJECT'
        uci set firewall.@zone[-1].output='ACCEPT'
        uci set firewall.@zone[-1].input='REJECT'
        uci set firewall.@zone[-1].masq='1'
        uci set firewall.@zone[-1].mtu_fix='1'
        uci set firewall.@zone[-1].family='ipv4'
        uci commit firewall
    fi

    if ! uci show firewall | grep -q "@forwarding.*name='${ZONE_NAME}'"; then
        printf "\033[32;1mConfigured forwarding\033[0m\n"
        uci add firewall forwarding
        uci set firewall.@forwarding[-1]=forwarding
        uci set firewall.@forwarding[-1].name="${ZONE_NAME}-lan"
        uci set firewall.@forwarding[-1].dest=${ZONE_NAME}
        uci set firewall.@forwarding[-1].src='lan'
        uci set firewall.@forwarding[-1].family='ipv4'
        uci commit firewall
    fi

    if uci show firewall | grep -q "@ipset.*name='vpn_domains_internal'"; then
        printf "\033[32;1mSet already exist\033[0m\n"
    else
        printf "\033[32;1mCreate set\033[0m\n"
        uci add firewall ipset
        uci set firewall.@ipset[-1].name='vpn_domains_internal'
        uci set firewall.@ipset[-1].match='dst_net'
        uci commit firewall
    fi

    if uci show firewall | grep -q "@rule.*name='mark_domains_intenal'"; then
        printf "\033[32;1mRule for set already exist\033[0m\n"
    else
        printf "\033[32;1mCreate rule set\033[0m\n"
        uci add firewall rule
        uci set firewall.@rule[-1]=rule
        uci set firewall.@rule[-1].name='mark_domains_intenal'
        uci set firewall.@rule[-1].src='lan'
        uci set firewall.@rule[-1].dest='*'
        uci set firewall.@rule[-1].proto='all'
        uci set firewall.@rule[-1].ipset='vpn_domains_internal'
        uci set firewall.@rule[-1].set_mark='0x2'
        uci set firewall.@rule[-1].target='MARK'
        uci set firewall.@rule[-1].family='ipv4'
        uci commit firewall
    fi

    if uci show dhcp | grep -q "@ipset.*name='vpn_domains_internal'"; then
        printf "\033[32;1mDomain on vpn_domains_internal already exist\033[0m\n"
    else
        printf "\033[32;1mCreate domain for vpn_domains_internal\033[0m\n"
        uci add dhcp ipset
        uci add_list dhcp.@ipset[-1].name='vpn_domains_internal'
        uci add_list dhcp.@ipset[-1].domain='youtube.com'
        uci add_list dhcp.@ipset[-1].domain='googlevideo.com'
        uci add_list dhcp.@ipset[-1].domain='youtubekids.com'
        uci add_list dhcp.@ipset[-1].domain='googleapis.com'
        uci add_list dhcp.@ipset[-1].domain='ytimg.com'
        uci add_list dhcp.@ipset[-1].domain='ggpht.com'
        uci commit dhcp
    fi

    sed -i "/done/a sed -i '/youtube.com\\\|ytimg.com\\\|ggpht.com\\\|googlevideo.com\\\|googleapis.com\\\|youtubekids.com/d' /tmp/dnsmasq.d/domains.lst" "/etc/init.d/getdomains"

    service dnsmasq restart
    service network restart

    exit 0
}

install_awg_packages() {
    # Получение pkgarch с наибольшим приоритетом
    PKGARCH=$(opkg print-architecture | awk 'BEGIN {max=0} {if ($3 > max) {max = $3; arch = $2}} END {print arch}')

    TARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f 1)
    SUBTARGET=$(ubus call system board | jsonfilter -e '@.release.target' | cut -d '/' -f 2)
    VERSION=$(ubus call system board | jsonfilter -e '@.release.version')
    PKGPOSTFIX="_v${VERSION}_${PKGARCH}_${TARGET}_${SUBTARGET}.ipk"
    BASE_URL="https://github.com/Slava-Shchipunov/awg-openwrt/releases/download/"

    AWG_DIR="/tmp/amneziawg"
    mkdir -p "$AWG_DIR"

    if opkg list-installed | grep -q amneziawg-tools; then
        echo "amneziawg-tools already installed"
    else
        AMNEZIAWG_TOOLS_FILENAME="amneziawg-tools${PKGPOSTFIX}"
        DOWNLOAD_URL="${BASE_URL}v${VERSION}/${AMNEZIAWG_TOOLS_FILENAME}"
        curl -L -o "$AWG_DIR/$AMNEZIAWG_TOOLS_FILENAME" "$DOWNLOAD_URL"

        if [ $? -eq 0 ]; then
            echo "amneziawg-tools file downloaded successfully"
        else
            echo "Error downloading amneziawg-tools. Please, install amneziawg-tools manually and run the script again"
            exit 1
        fi

        opkg install "$AWG_DIR/$AMNEZIAWG_TOOLS_FILENAME"

        if [ $? -eq 0 ]; then
            echo "amneziawg-tools file downloaded successfully"
        else
            echo "Error installing amneziawg-tools. Please, install amneziawg-tools manually and run the script again"
            exit 1
        fi
    fi
    
    if opkg list-installed | grep -q kmod-amneziawg; then
        echo "kmod-amneziawg already installed"
    else
        KMOD_AMNEZIAWG_FILENAME="kmod-amneziawg${PKGPOSTFIX}"
        DOWNLOAD_URL="${BASE_URL}v${VERSION}/${KMOD_AMNEZIAWG_FILENAME}"
        curl -L -o "$AWG_DIR/$KMOD_AMNEZIAWG_FILENAME" "$DOWNLOAD_URL"

        if [ $? -eq 0 ]; then
            echo "kmod-amneziawg file downloaded successfully"
        else
            echo "Error downloading kmod-amneziawg. Please, install kmod-amneziawg manually and run the script again"
            exit 1
        fi
        
        opkg install "$AWG_DIR/$KMOD_AMNEZIAWG_FILENAME"

        if [ $? -eq 0 ]; then
            echo "kmod-amneziawg file downloaded successfully"
        else
            echo "Error installing kmod-amneziawg. Please, install kmod-amneziawg manually and run the script again"
            exit 1
        fi
    fi
    
    if opkg list-installed | grep -q luci-app-amneziawg; then
        echo "luci-app-amneziawg already installed"
    else
        LUCI_APP_AMNEZIAWG_FILENAME="luci-app-amneziawg${PKGPOSTFIX}"
        DOWNLOAD_URL="${BASE_URL}v${VERSION}/${LUCI_APP_AMNEZIAWG_FILENAME}"
        curl -L -o "$AWG_DIR/$LUCI_APP_AMNEZIAWG_FILENAME" "$DOWNLOAD_URL"

        if [ $? -eq 0 ]; then
            echo "luci-app-amneziawg file downloaded successfully"
        else
            echo "Error downloading luci-app-amneziawg. Please, install luci-app-amneziawg manually and run the script again"
            exit 1
        fi

        opkg install "$AWG_DIR/$LUCI_APP_AMNEZIAWG_FILENAME"

        if [ $? -eq 0 ]; then
            echo "luci-app-amneziawg file downloaded successfully"
        else
            echo "Error installing luci-app-amneziawg. Please, install luci-app-amneziawg manually and run the script again"
            exit 1
        fi
    fi

    rm -rf "$AWG_DIR"
}

# System Details
MODEL=$(cat /tmp/sysinfo/model)
source /etc/os-release
printf "\033[34;1mModel: $MODEL\033[0m\n"
printf "\033[34;1mVersion: $OPENWRT_RELEASE\033[0m\n"

VERSION_ID=$(echo $VERSION | awk -F. '{print $1}')

if [ "$VERSION_ID" -ne 23 ]; then
    printf "\033[31;1mScript only support OpenWrt 23.05\033[0m\n"
    echo "For OpenWrt 21.02 and 22.03 you can:"
    echo "1) Use ansible https://github.com/itdoginfo/domain-routing-openwrt"
    echo "2) Configure manually. Old manual: https://itdog.info/tochechnaya-marshrutizaciya-na-routere-s-openwrt-wireguard-i-dnscrypt/"
    exit 1
fi

printf "\033[31;1mAll actions performed here cannot be rolled back automatically.\033[0m\n"

check_repo

add_packages

add_tunnel

add_mark

add_zone

show_manual

add_set

dnsmasqfull

add_dns_resolver

add_getdomains

printf "\033[32;1mRestart network\033[0m\n"
/etc/init.d/network restart

printf "\033[32;1mDone\033[0m\n"
