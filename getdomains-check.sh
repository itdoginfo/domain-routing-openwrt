#!/bin/sh

HIVPN=/etc/init.d/hivpn
GETDOMAINS=/etc/init.d/getdomains
DUMP=/tmp/dump.txt

checkpoint_true() {
    printf "\033[32;1m[\342\234\223] $1\033[0m\n"
}

checkpoint_false() {
    printf "\033[31;1m[x] $1\033[0m\n"
}

output_21() {
    if [ "$VERSION_ID" -eq 21 ]; then
        echo "You are using OpenWrt 21.02. This check does not support it"
    fi
}

# System Details
MODEL=$(grep machine /proc/cpuinfo | cut -d ':' -f 2)
RELEASE=$(grep OPENWRT_RELEASE /etc/os-release | awk -F '"' '{print $2}')
printf "\033[34;1mModel:$MODEL\033[0m\n"
printf "\033[34;1mVersion: $RELEASE\033[0m\n"
printf "\033[34;1mDate: $(date)\033[0m\n"

VERSION_ID=$(grep VERSION_ID /etc/os-release | awk -F '"' '{print $2}' | awk -F. '{print $1}')
RAM=$(free -m | grep Mem: | awk '{print $2}')
if [[ "$VERSION_ID" -ge 22 && "$RAM" -lt 150000 ]]
then 
   echo "Your router has less than 256MB of RAM. I recommend using only the vpn_domains list"
fi

# Check packages
CURL=$(opkg list-installed | grep -c curl)
if [ $CURL -eq 2 ]; then
    checkpoint_true "Curl package"
else
    checkpoint_false "Curl package"
    echo "Install: opkg install curl"
fi

DNSMASQ=$(opkg list-installed | grep dnsmasq-full | awk -F "-" '{print $3}' | tr -d '.' )
if [ $DNSMASQ -ge 287 ]; then
    checkpoint_true "Dnsmasq-full package"
else
    checkpoint_false "Dnsmasq-full package"
    echo "If you don't use vpn_domains set, it's OK"
    echo "Check version: opkg list-installed | grep dnsmasq-full"
    echo "Required version >= 2.87. For openwrt 22.03 follow manual: https://t.me/itdoginfo/12"
    if [ "$VERSION_ID" -eq 21 ]; then
        echo "You are using OpenWrt 21.02. This check does not support it"
        echo "Manual for openwrt 21.02: https://t.me/itdoginfo/8"
    fi
fi

# Chek xray package
if opkg list-installed | grep -q xray-core; then
    checkpoint_false "Xray-core package detected"
fi

if opkg list-installed | grep -q luci-app-xray; then
    checkpoint_false "luci-app-xray package detected. Not compatible. For delete: opkg remove luci-app-xray --force-removal-of-dependent-packages"
fi

# Check dnsmasq
DNSMASQ_RUN=$(service dnsmasq status | grep -c 'running')
if [ $DNSMASQ_RUN -eq 1 ]; then
    checkpoint_true "Dnsmasq service"
else
    checkpoint_false "Dnsmasq service"
    echo "Check config /etc/config/dhcp"
    output_21
fi


# Check internet connection
if curl -Is https://community.antifilter.download/ | grep -q 200; then
    checkpoint_true "Check Internet"
    else
    checkpoint_false "Check Internet"
    if [ $CURL -lt 2 ]; then
        echo "Install curl: opkg install curl"
    else
        echo "Check internet connection. If ok, check date on router. Details: https://cli.co/2EaW4rO"
        echo "For more info run: curl -Is https://community.antifilter.download/"
    fi
fi

# Check IPv6

if curl -6 -s https://ifconfig.io | egrep -q "(::)?[0-9a-fA-F]{1,4}(::?[0-9a-fA-F]{1,4}){1,7}(::)?"; then
    checkpoint_false "IPv6 detected. This script does not currently work with IPv6"
fi

# PPPoE
if uci show network.wan.proto | grep -q "pppoe"; then
    checkpoint_false "PPPoE is used. That could be a problem"
fi

# Tunnels
WIREGUARD=$(opkg list-installed | grep -c wireguard-tools )
if [ $WIREGUARD -eq 1 ]; then
    checkpoint_true "Wireguard-tools package"
    WG=true
fi

if [ "$WG" == true ]; then
    WG_PING=$(ping -c 1 -q -I wg0 itdog.info | grep -c "1 packets received")
    if [ $WG_PING -eq 1 ]; then
        checkpoint_true "Wireguard"
    else
        checkpoint_false "Wireguard"
        WG_TRACE=$(traceroute -i wg0 itdog.info -m 1 | grep ms | awk '{print $2}' | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
        if [ $WG_TRACE -eq 1 ]; then
            echo "Tunnel to wg server is work, but routing to internet doesn't work. Check server configuration. Details: https://cli.co/RSCvOxI"
        else
            echo "Bad news: WG tunnel isn't work, check your WG configuration. Details: https://cli.co/hGUUXDs"
            echo "If you don't use WG, but OpenVPN for example, it's OK"
        fi
    fi

    # Check WG route_allowed_ips
    if uci show network | grep -q ".route_allowed_ips='1'"; then
        checkpoint_false "Wireguard route_allowed_ips"
        echo "All traffic goes into the tunnel. Read more at: https://cli.co/SaxBzH7"
    else
        checkpoint_true "Wireguard route_allowed_ips"
    fi

    # Check route table
    ROUTE_TABLE=$(ip route show table vpn | grep -c "default dev wg0" )
    if [ $ROUTE_TABLE -eq 1 ]; then
        checkpoint_true "Route table WG"
    else
        checkpoint_false "Route table WG"
        echo "Details: https://cli.co/Atxr6U3"
    fi
fi

if opkg list-installed | grep -q openvpn; then
    checkpoint_true "OpenVPN package"
    OVPN=true
fi

# Check OpenVPN
if [ "$OVPN" == true ]; then
    if ping -c 1 -q -I tun0 itdog.info | grep -q "1 packets received"; then
        checkpoint_true "OpenVPN"
    else
        checkpoint_false "OpenVPN"
        if traceroute -i tun0 itdog.info -m 1 | grep ms | awk '{print $2}' | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'; then
            echo "Tunnel to OpenVPN server is work, but routing to internet doesn't work. Check server configuration."
        else
            echo "Bad news: OpenVPN tunnel isn't work, check your OpenVPN configuration."
        fi
    fi

    # Check OpenVPN redirect-gateway
    if grep -q redirect-gateway /etc/openvpn/*; then
        checkpoint_false "OpenVPN redirect-gateway"
        echo "All traffic goes into the tunnel. Read more at: https://cli.co/vzTNq_3"
    else
        checkpoint_true "OpenVPN redirect-gateway"
    fi

    # Check route table
    if ip route show table vpn | grep -q "default dev tun0"; then
        checkpoint_true "Route table OpenVPN"
    else
        checkpoint_false "Route table OpenVPN"
        echo "Details: https://cli.co/Atxr6U3"
    fi
fi

if opkg list-installed | grep -q sing-box; then
    checkpoint_true "Sing-box package"

    # Check route table
    if ip route show table vpn | grep -q "default dev tun0"; then
        checkpoint_true "Route table Sing-box"
    else
        checkpoint_false "Route table Sing-box. Try service network restart. Details: https://cli.co/n7xAbc1"
    fi

    # Sing-box uci validation
    if uci show sing-box 2>&1 | grep -q "Parse error"; then
        checkpoint_false "Sing-box UCI config. Check /etc/config/sing-box"
    else
        checkpoint_true "Sing-box UCI config"
    fi    

    # Check traffic
    IP_EXTERNAL=$(curl -s ifconfig.me)
    IFCONFIG=$(nslookup -type=a ifconfig.me | awk '/^Address: / {print $2}')

    IP_VPN=$(curl --interface tun0 -s ifconfig.me)

    if [ "$IP_EXTERNAL" != $IP_VPN ]; then
        checkpoint_true "Sing-box. VPN IP: $IP_VPN"
    else
        checkpoint_false "Sing-box. Check config: https://cli.co/Badmn3K"
    fi
fi

if which tun2socks | grep -q tun2socks; then
    checkpoint_true "tun2socks package"

    # Check route table
    if ip route show table vpn | grep -q "default dev tun0"; then
        checkpoint_true "Route table tun2socks"
    else
        checkpoint_false "Route table tun2socks. Try service network restart. Details: https://cli.co/n7xAbc1"
    fi

    IP_EXTERNAL=$(curl -s ifconfig.me)
    IFCONFIG=$(nslookup -type=a ifconfig.me | awk '/^Address: / {print $2}')

    IP_VPN=$(curl --interface tun0 -s ifconfig.me)

    if [ "$IP_EXTERNAL" != $IP_VPN ]; then
        checkpoint_true "tun2socks. VPN IP: $IP_VPN"
    else
        checkpoint_false "tun2socks. Check config: https://cli.co/VNZISEM"
    fi
fi

# Check sets

# vpn_domains set
vpn_domain_ipset_id=$(uci show firewall | grep -E '@ipset.*vpn_domains' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_domain_ipset_string=$(uci show firewall.@ipset[$vpn_domain_ipset_id] | grep -c "name='vpn_domains'\|match='dst_net'")
vpn_domain_rule_id=$(uci show firewall | grep -E '@rule.*vpn_domains' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_domain_rule_string=$(uci show firewall.@rule[$vpn_domain_rule_id] | grep -c "name='mark_domains'\|src='lan'\|dest='*'\|proto='all'\|ipset='vpn_domains'\|set_mark='0x1'\|target='MARK'\|family='ipv4'")

if [ $((vpn_domain_ipset_string + vpn_domain_rule_string)) -eq 10 ]; then
    checkpoint_true "vpn_domains set"

    # force resolve for vpn_domains. All list
    nslookup terraform.io 127.0.0.1 > /dev/null
    nslookup pochta.ru 127.0.0.1 > /dev/null
    nslookup 2gis.ru 127.0.0.1 > /dev/null

    VPN_DOMAINS_IP=$(nft list ruleset | grep -A 10 vpn_domains | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    if [ $VPN_DOMAINS_IP -ge 1 ]; then
        checkpoint_true "IPs in vpn_domains"
    else
        checkpoint_false "IPs in vpn_domains"
        echo "If you don't use vpn_domains, it's OK"
        echo "But if you want use, check configs. And run `service getdomains start`"
        output_21
    fi
else
    checkpoint_false "vpn_domains set"
    echo "If you don't use vpn_domains set, it's OK"
    echo "But if you want use, check config: https://cli.co/AwUGeM6"
fi

# vpn_ip set
vpn_ip_ipset_id=$(uci show firewall | grep -E '@ipset.*vpn_ip' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_ip_ipset_string=$(uci show firewall.@ipset[$vpn_ip_ipset_id] | grep -c "name='vpn_ip'\|match='dst_net'\|loadfile='/tmp/lst/ip.lst'")
vpn_ip_rule_id=$(uci show firewall | grep -E '@rule.*vpn_ip' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_ip_rule_string=$(uci show firewall.@rule[$vpn_ip_rule_id] | grep -c "name='mark_ip'\|src='lan'\|dest='*'\|proto='all'\|ipset='vpn_ip'\|set_mark='0x1'\|target='MARK'\|family='ipv4'")

if [ $((vpn_ip_ipset_string + vpn_ip_rule_string)) -eq 11 ]; then
    checkpoint_true "vpn_ip set"
    VPN_IP_IP=$(nft list ruleset | grep -A 10 vpn_ip | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    if [ $VPN_IP_IP -ge 1 ]; then
        checkpoint_true "IPs in vpn_ip"
    else
        checkpoint_false "IPs in vpn_ip"
        echo "But if you want use, check configs"
        output_21
    fi
elif uci show firewall | grep -q "vpn_ip"; then
        checkpoint_false "vpn_ip set"
        echo "Check config: https://cli.co/AwUGeM6"
fi

# vpn_subnet set
vpn_subnet_ipset_id=$(uci show firewall | grep -E '@ipset.*vpn_subnet' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_subnet_ipset_string=$(uci show firewall.@ipset[$vpn_subnet_ipset_id] | grep -c "name='vpn_subnets'\|match='dst_net'\|loadfile='/tmp/lst/subnet.lst'")
vpn_subnet_rule_id=$(uci show firewall | grep -E '@rule.*vpn_subnet' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_subnet_rule_string=$(uci show firewall.@rule[$vpn_subnet_rule_id] | grep -c "name='mark_subnet'\|src='lan'\|dest='*'\|proto='all'\|ipset='vpn_subnets'\|set_mark='0x1'\|target='MARK'\|family='ipv4'")

if [ $((vpn_subnet_ipset_string + vpn_subnet_rule_string)) -eq 11 ]; then
    checkpoint_true "vpn_subnet set"
    VPN_IP_SUBNET=$(nft list ruleset | grep -A 10 vpn_subnet | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    if [ $VPN_IP_SUBNET -ge 1 ]; then
        checkpoint_true "IPs in vpn_subnet"
    else
        checkpoint_false "IPs in vpn_subnet"
        echo "But if you want use, check configs"
        output_21
    fi
elif uci show firewall | grep -q "vpn_subnet"; then
        checkpoint_false "vpn_subnet set"
        echo "Check config: https://cli.co/AwUGeM6"
fi

# vpn_community set
vpn_community_ipset_id=$(uci show firewall | grep -E '@ipset.*vpn_community' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_community_ipset_string=$(uci show firewall.@ipset[$vpn_community_ipset_id] | grep -c "name='vpn_community'\|match='dst_net'\|loadfile='/tmp/lst/community.lst'")
vpn_community_rule_id=$(uci show firewall | grep -E '@rule.*vpn_community' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_community_rule_string=$(uci show firewall.@rule[$vpn_community_rule_id] | grep -c "name='mark_community'\|src='lan'\|dest='*'\|proto='all'\|ipset='vpn_community'\|set_mark='0x1'\|target='MARK'\|family='ipv4'")

if [ $((vpn_community_ipset_string + vpn_community_rule_string)) -eq 11 ]; then
    checkpoint_true "vpn_community set"
    VPN_COMMUNITY_IP=$(nft list ruleset | grep -A 10 vpn_community | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    if [ $VPN_COMMUNITY_IP -ge 1 ]; then
        checkpoint_true "IPs in vpn_community"
    else
        checkpoint_false "IPs in vpn_community"
        echo "But if you want use, check configs"
        output_21
    fi
elif uci show firewall | grep -q "vpn_community"; then
        checkpoint_false "vpn_community set"
        echo "Check config: https://cli.co/AwUGeM6"
fi

# getdomains script
if [ -s "$GETDOMAINS" ]; then
    checkpoint_true "Script getdomains"
    if crontab -l | grep -q $GETDOMAINS; then
        checkpoint_true "Script getdomains in crontab"
    else
        checkpoint_false "Script getdomains in crontab"
        echo "Script is not enabled in crontab. Check: crontab -l"
    fi
else
    checkpoint_false "Script getdomains"
    echo "Script don't exists in $GETDOMAINS. If you don't use getdomains, it's OK"
fi

# DNS

# DNSCrypt
if opkg list-installed | grep -q dnscrypt-proxy2; then
    checkpoint_true "Dnscrypt-proxy2 package"
    if service dnscrypt-proxy status | grep -q 'running'; then
        checkpoint_true "DNSCrypt service"
    else
        checkpoint_false "DNSCrypt service"
        echo "Check config: https://cli.co/wN-tc_S"
        output_21
    fi

    DNSMASQ_STRING=$(uci show dhcp.@dnsmasq[0] | grep -c "127.0.0.53#53\|noresolv='1'")
    if [ $DNSMASQ_STRING -eq 2 ]; then
        checkpoint_true "Dnsmasq config for DNSCrypt"
    else
        checkpoint_false "Dnsmasq config for DNSCrypt"
        echo "Check config: https://cli.co/rooc0uz"
    fi
fi

# Stubby
if opkg list-installed | grep -q stubby; then
    checkpoint_true "Stubby package"
    if service stubby status | grep -q 'running'; then
        checkpoint_true "Stubby service"
    else
        checkpoint_false "Stubby service"
        echo "Check config: https://cli.co/HbDBT2V"
        output_21
    fi

    STUBBY_STRING=$(uci show dhcp.@dnsmasq[0] | grep -c "127.0.0.1#5453\|noresolv='1'")
    if [ $STUBBY_STRING -eq 2 ]; then
        checkpoint_true "Dnsmasq config for Stubby"
    else
        checkpoint_false "Dnsmasq config for Stubby"
        echo "Check config: https://cli.co/HbDBT2V"
    fi
fi

# Create dump
if [[ "$1" == dump ]]; then
    printf "\033[36;1mCreate dump without private variables\033[0m\n"
    date > $DUMP
    $HIVPN start >> $DUMP 2>&1
    $GETDOMAINS start >> $DUMP 2>&1
    uci show firewall >> $DUMP
    uci show network | sed -r 's/(.*private_key=|.*preshared_key=|.*public_key=|.*endpoint_host=|.*wan.ipaddr=|.*wan.netmask=|.*wan.gateway=|.*wan.dns|.*.macaddr=).*/\1REMOVED/' >> $DUMP

    echo "Dump is here: $DUMP"
    echo "For download Linux/Mac use:"
    echo "scp root@IP_ROUTER:$DUMP ."
    echo "For Windows use PSCP or WSL"
fi

# Check DNS
if [[ "$1" == dns ]]; then
    printf "\033[36;1mCheck DNS servers\033[0m\n"
    DNS_SERVERS="1.1.1.1 8.8.8.8 8.8.4.4"
    DOH_DNS_SERVERS="cloudflare-dns.com 1.1.1.1 mozilla.cloudflare-dns.com security.cloudflare-dns.com"
    DOMAINS="instagram.com facebook.com"

    echo "1. Block DNS traffic (Port 53/udp is available)"

    for i in $DNS_SERVERS;
    do
        if nslookup -type=a -timeout=2 -retry=1 itdog.info $i | grep -q "timed out"; then
            checkpoint_false "$i"
        else
            checkpoint_true "$i"
        fi
    done

    echo "2. DoH available"

    for i in $DOH_DNS_SERVERS;
    do
        if curl --connect-timeout 5 -s -H "accept: application/dns-json" "https://$i/dns-query?name=itdog.info&type=A" | awk -F"data\":\"" '/data":"/{print $2}' | grep -q -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'; then
            checkpoint_true "$i"
        else
            checkpoint_false "$i"
        fi
    done

    echo "3. The response not contains an address from 127.0.0.0/8"

    for i in $DOMAINS;
    do
        if nslookup -type=a -timeout=2 -retry=1 $i | awk '/^Address: / {print $2}' | grep -q -E '127\.[0-9]{1,3}\.'; then
            checkpoint_false "$i"
        else
            checkpoint_true "$i"
        fi
    done

    echo "4. One IP for two different domains"

    FIRSTIP=$(nslookup -type=a instagram.com | awk '/^Address: / {print $2}')
    SECONDIP=$(nslookup -type=a facebook.com | awk '/^Address: / {print $2}')

    if [ "$FIRSTIP" = "$SECONDIP" ] ; then 
        checkpoint_false "IP addresses are the same"
    else
        checkpoint_true "Different IP addresses"
    fi

    echo "5. The response is not blank"

    for i in $DOMAINS;
    do
        if nslookup -type=a -timeout=2 -retry=1 $i | awk '/^Address: / {print $2}' | grep -q -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'; then
            checkpoint_true "$i"
        else
            checkpoint_false "$i"
        fi
    done

    echo "6. Сomparing response from unencrypted DNS and DoH (DNS poisoning)"

    DOHIP=$(curl -s -H "accept: application/dns-json" "https://1.1.1.1/dns-query?name=facebook.com&type=A" | awk -F"data\":\"" '/data":"/{print $2}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    OPENIP=$(nslookup -type=a -timeout=2 facebook.com 1.1.1.1 | awk '/^Address: / {print $2}')

    if [ "$DOHIP" = "$OPENIP" ]; then 
        checkpoint_true "IPs match"
    else
        checkpoint_false "IPs not match"
    fi
fi

# Info
echo -e "\nTelegram channel: https://t.me/itdoginfo"
echo "Telegram chat: https://t.me/itdogchat"