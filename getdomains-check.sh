#!/bin/sh

SCRIPTS_DIR="/etc/init.d"
TMP_DIR="/tmp"
HIVPN_SCRIPT_FILENAME="hivpn"
GETDOMAINS_SCRIPT_FILENAME="getdomains"
DUMP_FILENAME="dump.txt"

HIVPN_SCRIPT_PATH="$SCRIPTS_DIR/$HIVPN_SCRIPT_FILENAME"
GETDOMAINS_SCRIPT_PATH="$SCRIPTS_DIR/$GETDOMAINS_SCRIPT_FILENAME"
DUMP_PATH="$TMP_DIR/$DUMP_FILENAME"

COLOR_BOLD_BLUE="\033[34;1m"
COLOR_BOLD_GREEN="\033[32;1m"
COLOR_BOLD_RED="\033[31;1m"
COLOR_BOLD_CYAN="\033[36;1m"
COLOR_RESET="\033[0m"

UNSUPPORTED_OPENWRT_VERSION="21.02"
MIN_RAM="256"
DNSMASQ_FULL_REQUIRED_VERSION="2.87"

SINGBOX_CONFIG_PATH="/etc/config/sing-box"

CURL_PACKAGE="curl"
DNSMASQ_PACKAGE="dnsmasq"
DNSMASQ_FULL_PACKAGE="$DNSMASQ_PACKAGE-full"
XRAY_CORE_PACKAGE="xray-core"
LUCI_APP_XRAY_PACKAGE="luci-app-xray"
WIREGUARD_TOOLS_PACKAGE="wireguard-tools"
OPENVPN_PACKAGE="openvpn"
SINGBOX_PACKAGE="sing-box"
TUN2SOCKS_PACKAGE="tun2socks"
DNSCRYPT_PACKAGE="dnscrypt-proxy2"
STUBBY_PACKAGE="stubby"

WIREGUARD_PROTOCOL="Wireguard"
OPENVPN_PROTOCOL="OpenVPN"

LANGUAGE="ru"
SUPPORTED_LANGUAGES="ru, en"

set_language_en() {
  DEVICE_MODEL="Model"
  OPENWRT_VERSION="Version"
  CURRENT_DATE="Date"
  INSTALLED="is installed"
  NOT_INSTALLED="is not installed"
  RUNNING="is running"
  NOT_RUNNING="is not running"
  ENABLED="is enabled"
  DISABLED="is disabled"
  EXISTS="exists"
  DOESNT_EXIST="doesn't exist"
  UNSUPPORTED_OPENWRT="You are using OpenWrt $UNSUPPORTED_OPENWRT_VERSION. This check script does not support it."
  RAM_WARNING="Your router has less than $MIN_RAM MB of RAM. It is recommended to use only the vpn_domains list."
  CURL_INSTALLED="$CURL_PACKAGE $INSTALLED"
  CURL_NOT_INSTALLED="$CURL_PACKAGE $NOT_INSTALLED. Install it: opkg install $CURL_PACKAGE"
  DNSMASQ_FULL_INSTALLED="$DNSMASQ_FULL_PACKAGE $INSTALLED"
  DNSMASQ_FULL_NOT_INSTALLED="$DNSMASQ_FULL_PACKAGE $NOT_INSTALLED"
  DNSMASQ_FULL_DETAILS="If you don't use vpn_domains set, it's OK\nCheck version: opkg list-installed | grep $DNSMASQ_FULL_PACKAGE\nRequired version >= $DNSMASQ_FULL_REQUIRED_VERSION. For OpenWrt 22.03 follow manual: https://t.me/itdoginfo/12"
  OPENWRT_21_DETAILS="\nYou are using OpenWrt $UNSUPPORTED_OPENWRT_VERSION. This check does not support it.\nManual for OpenWrt $UNSUPPORTED_OPENWRT_VERSION: https://t.me/itdoginfo/8"
  XRAY_CORE_PACKAGE_DETECTED="$XRAY_CORE_PACKAGE package detected"
  LUCI_APP_XRAY_PACKAGE_DETECTED="$LUCI_APP_XRAY_PACKAGE package detected which is incompatible. Remove it: opkg remove $LUCI_APP_XRAY_PACKAGE --force-removal-of-dependent-packages"
  DNSMASQ_SERVICE_RUNNING="$DNSMASQ_PACKAGE service $RUNNING"
  DNSMASQ_SERVICE_NOT_RUNNING="$DNSMASQ_PACKAGE service $NOT_RUNNING. Check configuration: /etc/config/dhcp"
  INTERNET_IS_AVAILABLE="Internet is available"
  INTERNET_IS_NOT_AVAILABLE="Internet is not available"
  INTERNET_DETAILS="Check internet connection. If it's ok, check date on router. Details: https://cli.co/2EaW4rO\nFor more info run: curl -Is https://community.antifilter.download/"
  IPV6_DETECTED="IPv6 detected. This script does not currently work with IPv6"
  WIREGUARD_TOOLS_INSTALLED="$WIREGUARD_TOOLS_PACKAGE $INSTALLED"
  WIREGUARD_ROUTING_DOESNT_WORK="Tunnel to the $WIREGUARD_PROTOCOL server works, but routing to the internet does not work. Check server configuration. Details: https://cli.co/RSCvOxI"
  WIREGUARD_TUNNEL_NOT_WORKING="Bad news: $WIREGUARD_PROTOCOL tunnel isn't working. Check your $WIREGUARD_PROTOCOL configuration. Details: https://cli.co/hGUUXDs\nIf you don't use $WIREGUARD_PROTOCOL, but $OPENVPN_PROTOCOL for example, it's OK"
  WIREGUARD_ROUTE_ALLOWED_IPS_ENABLED="$WIREGUARD_PROTOCOL route_allowed_ips $ENABLED. All traffic goes into the tunnel. Read more at: https://cli.co/SaxBzH7"
  WIREGUARD_ROUTE_ALLOWED_IPS_DISABLED="$WIREGUARD_PROTOCOL route_allowed_ips $DISABLED"
  WIREGUARD_ROUTING_TABLE_EXISTS="$WIREGUARD_PROTOCOL routing table $EXISTS"
  WIREGUARD_ROUTING_TABLE_DOESNT_EXIST="$WIREGUARD_PROTOCOL routing table $DOESNT_EXIST. Details: https://cli.co/Atxr6U3"
  OPENVPN_INSTALLED="$OPENVPN_PACKAGE $INSTALLED"
  OPENVPN_ROUTING_DOESNT_WORK="Tunnel to the $OPENVPN_PROTOCOL server works, but routing to the internet does not work. Check server configuration."
  OPENVPN_TUNNEL_NOT_WORKING="Bad news: $OPENVPN_PROTOCOL tunnel isn't working. Check your $OPENVPN_PROTOCOL configuration."
  OPENVPN_REDIRECT_GATEWAY_ENABLED="$OPENVPN_PROTOCOL redirect-gateway $ENABLED. All traffic goes into the tunnel. Read more at: https://cli.co/vzTNq_3"
  OPENVPN_REDIRECT_GATEWAY_DISABLED="$OPENVPN_PROTOCOL redirect-gateway $DISABLED"
  OPENVPN_ROUTING_TABLE_EXISTS="$OPENVPN_PROTOCOL routing table $EXISTS"
  OPENVPN_ROUTING_TABLE_DOESNT_EXIST="$OPENVPN_PROTOCOL routing table $DOESNT_EXIST. Details: https://cli.co/Atxr6U3"
  SINGBOX_INSTALLED="$SINGBOX_PACKAGE $INSTALLED"
  SINGBOX_ROUTING_TABLE_EXISTS="$SINGBOX_PACKAGE routing table $EXISTS"
  SINGBOX_ROUTING_TABLE_DOESNT_EXIST="$SINGBOX_PACKAGE routing table $DOESNT_EXIST. Try: service network restart. Details: https://cli.co/n7xAbc1"
  SINGBOX_UCI_CONFIG_OK="$SINGBOX_PACKAGE UCI configuration has been successfully validated"
  SINGBOX_UCI_CONFIG_ERROR="$SINGBOX_PACKAGE Error validation UCI configuration. Check $SINGBOX_CONFIG_PATH"
  SINGBOX_CONFIG_OK="$SINGBOX_PACKAGE configuration has been successfully validated"
  SINGBOX_CONFIG_ERROR="$SINGBOX_PACKAGE configuration validation error"
  SINGBOX_WORKING="$SINGBOX_PACKAGE works. VPN IP: $IP_VPN"
  SINGBOX_ROUTING_DOESNT_WORK="$SINGBOX_PACKAGE: Your traffic is not routed through the VPN. Check configuration: https://cli.co/Badmn3K"
  TUN2SOCKS_INSTALLED="$TUN2SOCKS_PACKAGE $INSTALLED"
  TUN2SOCKS_ROUTING_TABLE_EXISTS="$TUN2SOCKS_PACKAGE routing table $EXISTS"
  TUN2SOCKS_ROUTING_TABLE_DOESNT_EXIST="$TUN2SOCKS_PACKAGE routing table $DOESNT_EXIST. Try: service network restart. Details: https://cli.co/n7xAbc1"
  TUN2SOCKS_WORKING="$TUN2SOCKS_PACKAGE works. VPN IP: $IP_VPN"
  TUN2SOCKS_ROUTING_DOESNT_WORK="$TUN2SOCKS_PACKAGE: Your traffic is not routed through the VPN. Check configuration: https://cli.co/VNZISEM"
  VPN_DOMAINS_SET_EXISTS="vpn_domains set $EXISTS"
  VPN_DOMAINS_SET_DOESNT_EXIST="vpn_domains set $DOESNT_EXIST"
  IPS_IN_VPN_DOMAINS_SET_OK="IPs are successfully added to vpn_domains set"
  IPS_IN_VPN_DOMAINS_SET_ERROR="IPs were not added to vpn_domains set"
  VPN_DOMAINS_DETAILS="If you don't use vpn_domains, it's OK.\nBut if you want to use it, check the configuration and run: service getdomains start"
  VPN_DOMAINS_DETAILS_2="If you don't use vpn_domains, it's OK.\nBut if you want use, check the configuration: https://cli.co/AwUGeM6"
  VPN_IP_SET_EXISTS="vpn_ip set $EXISTS"
  VPN_IP_SET_DOESNT_EXIST="vpn_ip set $DOESNT_EXIST. Check configuration: https://cli.co/AwUGeM6"
  IPS_IN_VPN_IP_SET_OK="IPs are successfully added to vpn_ip set"
  IPS_IN_VPN_IP_SET_ERROR="IPs were not added to vpn_ip set. But if you want to use it, check configuration"
  VPN_SUBNET_SET_EXISTS="vpn_subnets set $EXISTS"
  VPN_SUBNET_SET_DOESNT_EXIST="vpn_subnets set $DOESNT_EXIST. Check configuration: https://cli.co/AwUGeM6"
  IPS_IN_VPN_SUBNET_SET_OK="IPs are successfully added to vpn_subnets set"
  IPS_IN_VPN_SUBNET_SET_ERROR="IPs were not added to vpn_subnets set. But if you want to use it, check configs"
  VPN_COMMUNITY_SET_EXISTS="vpn_community set $EXISTS"
  VPN_COMMUNITY_SET_DOESNT_EXIST="vpn_community set $DOESNT_EXIST. Check configuration: https://cli.co/AwUGeM6"
  IPS_IN_VPN_COMMUNITY_SET_OK="IPs are successfully added to vpn_community set"
  IPS_IN_VPN_COMMUNITY_SET_ERROR="IPs were not added to vpn_community set. But if you want to use it, check configs"
  GETDOMAINS_SCRIPT_EXISTS="Script $GETDOMAINS_SCRIPT_FILENAME $EXISTS"
  GETDOMAINS_SCRIPT_DOESNT_EXIST="Script $GETDOMAINS_SCRIPT_FILENAME $DOESNT_EXIST. Script doesn't exists in $GETDOMAINS_SCRIPT_PATH. If you don't use getdomains, it's OK"
  GETDOMAINS_SCRIPT_CRONTAB_OK="Script $GETDOMAINS_SCRIPT_FILENAME has been successfully added to crontab"
  GETDOMAINS_SCRIPT_CRONTAB_ERROR="Script $GETDOMAINS_SCRIPT_FILENAME has not been added to crontab. Check: crontab -l"
  DNSCRYPT_INSTALLED="$DNSCRYPT_PACKAGE $INSTALLED"
  DNSCRYPT_SERVICE_RUNNING="$DNSCRYPT_PACKAGE service $RUNNING"
  DNSCRYPT_SERVICE_NOT_RUNNING="$DNSCRYPT_PACKAGE service $NOT_RUNNING. Check configuration: https://cli.co/wN-tc_S"
  DNSMASQ_CONFIG_FOR_DNSCRYPT_OK="$DNSMASQ_PACKAGE configuration for $DNSCRYPT_PACKAGE is ok"
  DNSMASQ_CONFIG_FOR_DNSCRYPT_ERROR="$DNSMASQ_PACKAGE configuration for $DNSCRYPT_PACKAGE is not ok. Check configuration: https://cli.co/rooc0uz"
  STUBBY_INSTALLED="$STUBBY_PACKAGE $INSTALLED"
  STUBBY_SERVICE_RUNNING="$STUBBY_PACKAGE service $RUNNING"
  STUBBY_SERVICE_NOT_RUNNING="$STUBBY_PACKAGE service $NOT_RUNNING. Check configuration: https://cli.co/HbDBT2V"
  DNSMASQ_CONFIG_FOR_STUBBY_OK="$DNSMASQ_PACKAGE configuration for $STUBBY_PACKAGE is ok"
  DNSMASQ_CONFIG_FOR_STUBBY_ERROR="$DNSMASQ_PACKAGE configuration for $STUBBY_PACKAGE is not ok. Check configuration: https://cli.co/HbDBT2V"
  DUMP_CREATION="Creating dump without private variables"
  DUMP_DETAILS="Dump is here: $DUMP_PATH\nFor download on Linux/Mac use: scp root@IP_ROUTER:$DUMP_PATH .\nFor Windows use WinSCP/PSCP or WSL"
  DNS_CHECK="Checking DNS servers"
  IS_DNS_TRAFFIC_BLOCKED="Checking DNS traffic blocking (Port 53/udp is available)"
  IS_DOH_AVAILABLE="Checking DOH availability"
  RESPONSE_NOT_CONTAINS_127_0_0_8="Checking that the response does not contain an address from 127.0.0.8"
  ONE_IP_FOR_TWO_DOMAINS="Checking IP for two different domains"
  IPS_ARE_THE_SAME="IPs are the same"
  IPS_ARE_DIFFERENT="IPs are different"
  RESPONSE_IS_NOT_BLANK="Checking if response is not blank"
  DNS_POISONING_CHECK="Сomparing response from unencrypted DNS and DoH (DNS poisoning)"
  TELEGRAM_CHANNEL="Telegram channel"
  TELEGRAM_CHAT="Telegram chat"
}

set_language_ru() {
  DEVICE_MODEL="Модель"
  OPENWRT_VERSION="Версия"
  CURRENT_DATE="Дата"
  INSTALLED="установлен"
  NOT_INSTALLED="не установлен"
  RUNNING="запущен"
  NOT_RUNNING="не запущен"
  ENABLED="включен"
  DISABLED="выключен"
  EXISTS="существует"
  DOESNT_EXIST="не существует"
  UNSUPPORTED_OPENWRT="Вы используете OpenWrt $UNSUPPORTED_OPENWRT_VERSION. Этот скрипт проверки её не поддерживает."
  RAM_WARNING="У вашего роутера менее $MIN_RAM МБ ОЗУ. Рекомендуется использовать только vpn_domains set."
  CURL_INSTALLED="$CURL_PACKAGE $INSTALLED"
  CURL_NOT_INSTALLED="$CURL_PACKAGE $NOT_INSTALLED. Установите его: opkg install $CURL_PACKAGE"
  DNSMASQ_FULL_INSTALLED="$DNSMASQ_FULL_PACKAGE $INSTALLED"
  DNSMASQ_FULL_NOT_INSTALLED="$DNSMASQ_FULL_PACKAGE $NOT_INSTALLED"
  DNSMASQ_FULL_DETAILS="Если вы не используете vpn_domains set, это нормально\nПроверьте версию: opkg list-installed | grep $DNSMASQ_FULL_PACKAGE\nТребуемая версия >= $DNSMASQ_FULL_REQUIRED_VERSION. Для OpenWrt 22.03 следуйте инструкции: https://t.me/itdoginfo/12"
  OPENWRT_21_DETAILS="\nВы используете OpenWrt $UNSUPPORTED_OPENWRT_VERSION. Этот скрипт её не поддерживает.\nИнструкция для OpenWrt $UNSUPPORTED_OPENWRT_VERSION: https://t.me/itdoginfo/8"
  XRAY_CORE_PACKAGE_DETECTED="Обнаружен пакет $XRAY_CORE_PACKAGE"
  LUCI_APP_XRAY_PACKAGE_DETECTED="Обнаружен пакет $LUCI_APP_XRAY_PACKAGE, который не совместим. Удалите его: opkg remove $LUCI_APP_XRAY_PACKAGE --force-removal-of-dependent-packages"
  DNSMASQ_SERVICE_RUNNING="Сервис $DNSMASQ_PACKAGE $RUNNING"
  DNSMASQ_SERVICE_NOT_RUNNING="Сервис $DNSMASQ_PACKAGE $NOT_RUNNING. Проверьте конфигурацию: /etc/config/dhcp"
  INTERNET_IS_AVAILABLE="Интернет доступен"
  INTERNET_IS_NOT_AVAILABLE="Интернет недоступен"
  INTERNET_DETAILS="Проверьте подключение к интернету. Если оно в порядке, проверьте дату на роутере. Подробности: https://cli.co/2EaW4rO\nДополнительно выполните: curl -Is https://community.antifilter.download/"
  IPV6_DETECTED="Обнаружен IPv6. Этот скрипт не поддерживает работу с IPv6"
  WIREGUARD_TOOLS_INSTALLED="$WIREGUARD_TOOLS_PACKAGE $INSTALLED"
  WIREGUARD_ROUTING_DOESNT_WORK="Туннель к $WIREGUARD_PROTOCOL серверу работает, но маршрутизация в интернет не работает. Проверьте конфигурацию сервера. Подробности: https://cli.co/RSCvOxI"
  WIREGUARD_TUNNEL_NOT_WORKING="Плохие новости: туннель $WIREGUARD_PROTOCOL не работает. Проверьте конфигурацию $WIREGUARD_PROTOCOL. Подробности: https://cli.co/hGUUXDs\nЕсли вы не используете $WIREGUARD_PROTOCOL, а, например, $OPENVPN_PROTOCOL, то это нормально"
  WIREGUARD_ROUTE_ALLOWED_IPS_ENABLED="$WIREGUARD_PROTOCOL route_allowed_ips $ENABLED. Весь трафик идет в туннель. Подробнее: https://cli.co/SaxBzH7"
  WIREGUARD_ROUTE_ALLOWED_IPS_DISABLED="$WIREGUARD_PROTOCOL route_allowed_ips $DISABLED"
  WIREGUARD_ROUTING_TABLE_EXISTS="Таблица маршрутизации $WIREGUARD_PROTOCOL $EXISTS"
  WIREGUARD_ROUTING_TABLE_DOESNT_EXIST="Таблица маршрутизации $WIREGUARD_PROTOCOL $DOESNT_EXIST. Подробности: https://cli.co/Atxr6U3"
  OPENVPN_INSTALLED="$OPENVPN_PACKAGE $INSTALLED"
  OPENVPN_ROUTING_DOESNT_WORK="Туннель к $OPENVPN_PROTOCOL серверу работает, но маршрутизация в интернет не работает. Проверьте конфигурацию сервера."
  OPENVPN_TUNNEL_NOT_WORKING="Плохие новости: туннель $OPENVPN_PROTOCOL не работает. Проверьте конфигурацию $OPENVPN_PROTOCOL."
  OPENVPN_REDIRECT_GATEWAY_ENABLED="$OPENVPN_PROTOCOL redirect-gateway $ENABLED. Весь трафик идет в туннель. Подробнее: https://cli.co/vzTNq_3"
  OPENVPN_REDIRECT_GATEWAY_DISABLED="$OPENVPN_PROTOCOL redirect-gateway $DISABLED"
  OPENVPN_ROUTING_TABLE_EXISTS="Таблица маршрутизации $OPENVPN_PROTOCOL $EXISTS"
  OPENVPN_ROUTING_TABLE_DOESNT_EXIST="Таблица маршрутизации $OPENVPN_PROTOCOL $DOESNT_EXIST. Подробности: https://cli.co/Atxr6U3"
  SINGBOX_INSTALLED="$SINGBOX_PACKAGE $INSTALLED"
  SINGBOX_ROUTING_TABLE_EXISTS="Таблица маршрутизации $SINGBOX_PACKAGE $EXISTS"
  SINGBOX_ROUTING_TABLE_DOESNT_EXIST="Таблица маршрутизации $SINGBOX_PACKAGE $DOESNT_EXIST. Попробуйте: service network restart. Подробности: https://cli.co/n7xAbc1"
  SINGBOX_UCI_CONFIG_OK="UCI конфигурация для $SINGBOX_PACKAGE успешно проверена"
  SINGBOX_UCI_CONFIG_ERROR="Ошибка валидации UCI конфигурации для $SINGBOX_PACKAGE"
  SINGBOX_CONFIG_OK="Конфигурация $SINGBOX_PACKAGE успешно проверена"
  SINGBOX_CONFIG_ERROR="Ошибка валидации конфигурации $SINGBOX_PACKAGE"
  SINGBOX_WORKING="$SINGBOX_PACKAGE работает. VPN IP: $IP_VPN"
  SINGBOX_ROUTING_DOESNT_WORK="$SINGBOX_PACKAGE: Ваш трафик не идёт через VPN. Проверьте конфигурацию: https://cli.co/Badmn3K"
  TUN2SOCKS_INSTALLED="$TUN2SOCKS_PACKAGE $INSTALLED"
  TUN2SOCKS_ROUTING_TABLE_EXISTS="Таблица маршрутизации $TUN2SOCKS_PROTOCOL $EXISTS"
  TUN2SOCKS_ROUTING_TABLE_DOESNT_EXIST="Таблица маршрутизации $TUN2SOCKS_PROTOCOL $DOESNT_EXIST. Подробности: https://cli.co/n7xAbc1"
  TUN2SOCKS_WORKING="$TUN2SOCKS_PACKAGE работает. VPN IP: $IP_VPN"
  TUN2SOCKS_ROUTING_DOESNT_WORK="$TUN2SOCKS_PACKAGE: Ваш трафик не идёт через VPN. Проверьте конфигурацию: https://cli.co/VNZISEM"
  VPN_DOMAINS_SET_EXISTS="vpn_domains set $EXISTS"
  VPN_DOMAINS_SET_DOESNT_EXIST="vpn_domains set $DOESNT_EXIST"
  IPS_IN_VPN_DOMAINS_SET_OK="IP-адреса успешно добавлены в vpn_domains set"
  IPS_IN_VPN_DOMAINS_SET_ERROR="IP-адреса не добавлены в vpn_domains set"
  VPN_DOMAINS_DETAILS="Если вы не используете vpn_domains, все в порядке.\nНо если вы хотите использовать его, проверьте конфигурацию и выполните: service getdomains start"
  VPN_DOMAINS_DETAILS_2="Если вы не используете vpn_domains, все в порядке.\nНо если вы хотите использовать, проверьте конфигурацию: https://cli.co/AwUGeM6"
  VPN_IP_SET_EXISTS="vpn_ip set $EXISTS"
  VPN_IP_SET_DOESNT_EXIST="vpn_ip set $DOESNT_EXIST"
  IPS_IN_VPN_IP_SET_OK="IP-адреса успешно добавлены в set vpn_ip"
  IPS_IN_VPN_IP_SET_ERROR="IP-адреса не добавлены в set vpn_ip"
  VPN_SUBNET_SET_EXISTS="vpn_subnet set $EXISTS"
  VPN_SUBNET_SET_DOESNT_EXIST="vpn_subnet set $DOESNT_EXIST"
  IPS_IN_VPN_SUBNET_SET_OK="IP-адреса успешно добавлены в set vpn_subnet"
  IPS_IN_VPN_SUBNET_SET_ERROR="IP-адреса не добавлены в set vpn_subnet"
  VPN_COMMUNITY_SET_EXISTS="vpn_community set $EXISTS"
  VPN_COMMUNITY_SET_DOESNT_EXIST="vpn_community set $DOESNT_EXIST"
  IPS_IN_VPN_COMMUNITY_SET_OK="IP-адреса успешно добавлены в set vpn_community"
  IPS_IN_VPN_COMMUNITY_SET_ERROR="IP-адреса не добавлены в set vpn_community"
  GETDOMAINS_SCRIPT_EXISTS="Скрипт $GETDOMAINS_SCRIPT_FILENAME $EXISTS"
  GETDOMAINS_SCRIPT_DOESNT_EXIST="Скрипт $GETDOMAINS_SCRIPT_FILENAME $DOESNT_EXIST"
  GETDOMAINS_SCRIPT_CRONTAB_OK="Скрипт $GETDOMAINS_SCRIPT_FILENAME успешно добавлен в crontab"
  GETDOMAINS_SCRIPT_CRONTAB_ERROR="Скрипт $GETDOMAINS_SCRIPT_FILENAME не был добавлен в crontab. Проверьте: crontab -l"
  DNSCRYPT_INSTALLED="$DNSCRYPT_PACKAGE $INSTALLED"
  DNSCRYPT_SERVICE_RUNNING="Сервис $DNSCRYPT_PACKAGE $RUNNING"
  DNSCRYPT_SERVICE_NOT_RUNNING="Сервис $DNSCRYPT_PACKAGE $NOT_RUNNING. Проверьте конфигурацию: https://cli.co/wN-tc_S"
  DNSMASQ_CONFIG_FOR_DNSCRYPT_OK="Конфигурация $DNSMASQ_PACKAGE для $DNSCRYPT_PACKAGE в порядке"
  DNSMASQ_CONFIG_FOR_DNSCRYPT_ERROR="Конфигурация $DNSMASQ_PACKAGE для $DNSCRYPT_PACKAGE не в порядке. Проверьте конфигурацию: https://cli.co/rooc0uz"
  STUBBY_INSTALLED="$STUBBY_PACKAGE $INSTALLED"
  STUBBY_SERVICE_RUNNING="Сервис $STUBBY_PACKAGE $RUNNING"
  STUBBY_SERVICE_NOT_RUNNING="Сервис $STUBBY_PACKAGE $NOT_RUNNING. Проверьте конфигурацию: https://cli.co/HbDBT2V"
  DNSMASQ_CONFIG_FOR_STUBBY_OK="Конфигурация $DNSMASQ_PACKAGE для $STUBBY_PACKAGE в порядке"
  DNSMASQ_CONFIG_FOR_STUBBY_ERROR="Конфигурация $DNSMASQ_PACKAGE для $STUBBY_PACKAGE не в порядке. Проверьте конфигурацию: https://cli.co/HbDBT2V"
  DUMP_CREATION="Создание дампа без приватных переменных"
  DUMP_DETAILS="Дамп находится здесь: $DUMP_PATH\nДля загрузки на Linux/Mac используйте: scp root@IP_ROUTER:$DUMP_PATH .\nДля Windows используйте WinSCP/PSCP или WSL"
  DNS_CHECK="Проверка DNS серверов"
  IS_DNS_TRAFFIC_BLOCKED="Проверяем блокировку DNS трафика (Порт 53/udp доступен)"
  IS_DOH_AVAILABLE="Проверяем доступность DoH"
  RESPONSE_NOT_CONTAINS_127_0_0_8="Проверяем, что ответ на запрос не содержит адреса из 127.0.0.8"
  ONE_IP_FOR_TWO_DOMAINS="Проверяем IP для двух разных доменов"
  IPS_ARE_THE_SAME="IP совпадают"
  IPS_ARE_DIFFERENT="IP различаются"
  RESPONSE_IS_NOT_BLANK="Проверяем, что ответ не пустой"
  DNS_POISONING_CHECK="Сравниваем ответ от незащищенного DNS и DoH (Подмена DNS)"
  TELEGRAM_CHANNEL="Telegram канал"
  TELEGRAM_CHAT="Telegram чат"
}

checkpoint_true() {
  printf "$COLOR_BOLD_GREEN[\342\234\223] $1$COLOR_RESET\n"
}

checkpoint_false() {
  printf "$COLOR_BOLD_RED[x] $1$COLOR_RESET\n"
}

output_21() {
  if [ "$VERSION_ID" -eq 21 ]; then
    echo "$UNSUPPORTED_OPENWRT"
  fi
}

while [ $# -gt 0 ]; do
  case "$1" in
    --lang)
      LANGUAGE="$2"
      shift 2
      ;;
    dump | dns)
      COMMAND="$1"
      shift 1
      ;;
    *)
      printf "$COLOR_BOLD_RED[ERROR]$COLOR_RESET Unknown option: %s\n" "$1"
      exit 1
      ;;
  esac
done

case $LANGUAGE in
  ru)
    set_language_ru
    ;;
  en)
    set_language_en
    ;;
  *)
    printf "$COLOR_BOLD_RED[ERROR]$COLOR_RESET Unsupported language '$LANGUAGE'. Supported languages: $SUPPORTED_LANGUAGES %s\n" "$1"
    exit 1
    ;;
esac

# System Details
MODEL=$(cat /tmp/sysinfo/model)
source /etc/os-release
printf "$COLOR_BOLD_BLUE$DEVICE_MODEL: $MODEL$COLOR_RESET\n"
printf "$COLOR_BOLD_BLUE$OPENWRT_VERSION: $OPENWRT_RELEASE$COLOR_RESET\n"
printf "$COLOR_BOLD_BLUE$CURRENT_DATE: $(date)$COLOR_RESET\n"

VERSION_ID=$(echo $VERSION | awk -F. '{print $1}')
RAM=$(free -m | grep Mem: | awk '{print $2}')
if [[ "$VERSION_ID" -ge 22 && "$RAM" -lt 150000 ]]; then
  echo "$RAM_WARNING"
fi

# Check packages
CURL=$(opkg list-installed | grep -c curl)
if [ $CURL -eq 2 ]; then
  checkpoint_true "$CURL_INSTALLED"
else
  checkpoint_false "$CURL_NOT_INSTALLED"
fi

DNSMASQ=$(opkg list-installed | grep dnsmasq-full | awk -F "-" '{print $3}' | tr -d '.')
if [ $DNSMASQ -ge 287 ]; then
  checkpoint_true "$DNSMASQ_FULL_INSTALLED"
else
  checkpoint_false "$DNSMASQ_FULL_NOT_INSTALLED"
  printf "$DNSMASQ_FULL_DETAILS\n"
  if [ "$VERSION_ID" -eq 21 ]; then
    printf "$OPENWRT_21_DETAILS\n"
  fi
fi

# Chek xray package
if opkg list-installed | grep -q xray-core; then
  checkpoint_false "$XRAY_CORE_PACKAGE_DETECTED"
fi

if opkg list-installed | grep -q luci-app-xray; then
  checkpoint_false "$LUCI_APP_XRAY_PACKAGE_DETECTED"
fi

# Check dnsmasq
DNSMASQ_RUN=$(service dnsmasq status | grep -c 'running')
if [ $DNSMASQ_RUN -eq 1 ]; then
  checkpoint_true "$DNSMASQ_SERVICE_RUNNING"
else
  checkpoint_false "$DNSMASQ_SERVICE_NOT_RUNNING"
  output_21
fi

# Check internet connection
if curl -Is https://community.antifilter.download/ | grep -q 200; then
  checkpoint_true "$INTERNET_IS_AVAILABLE"
else
  checkpoint_false "$INTERNET_IS_NOT_AVAILABLE"
  if [ $CURL -lt 2 ]; then
    echo "$CURL_NOT_INSTALLED"
  else
    printf "$INTERNET_DETAILS\n"
  fi
fi

# Check IPv6

if curl -6 -s https://ifconfig.io | egrep -q "(::)?[0-9a-fA-F]{1,4}(::?[0-9a-fA-F]{1,4}){1,7}(::)?"; then
  checkpoint_false "$IPV6_DETECTED"
fi

# Tunnels
WIREGUARD=$(opkg list-installed | grep -c wireguard-tools)
if [ $WIREGUARD -eq 1 ]; then
  checkpoint_true "$WIREGUARD_TOOLS_INSTALLED"
  WG=true
fi

if [ "$WG" == true ]; then
  WG_PING=$(ping -c 1 -q -I wg0 itdog.info | grep -c "1 packets received")
  if [ $WG_PING -eq 1 ]; then
    checkpoint_true "$WIREGUARD_PROTOCOL"
  else
    checkpoint_false "$WIREGUARD_PROTOCOL"
    WG_TRACE=$(traceroute -i wg0 itdog.info -m 1 | grep ms | awk '{print $2}' | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    if [ $WG_TRACE -eq 1 ]; then
      echo "$WIREGUARD_ROUTING_DOESNT_WORK"
    else
      printf "$WIREGUARD_TUNNEL_NOT_WORKING\n"
    fi
  fi

  # Check WG route_allowed_ips
  if uci show network | grep -q ".route_allowed_ips='1'"; then
    checkpoint_false "$WIREGUARD_ROUTE_ALLOWED_IPS_ENABLED"
  else
    checkpoint_true "$WIREGUARD_ROUTE_ALLOWED_IPS_DISABLED"
  fi

  # Check route table
  ROUTE_TABLE=$(ip route show table vpn | grep -c "default dev wg0")
  if [ $ROUTE_TABLE -eq 1 ]; then
    checkpoint_true "$WIREGUARD_ROUTING_TABLE_EXISTS"
  else
    checkpoint_false "$WIREGUARD_ROUTING_TABLE_DOESNT_EXIST"
  fi
fi

if opkg list-installed | grep -q openvpn; then
  checkpoint_true "$OPENVPN_INSTALLED"
  OVPN=true
fi

# Check OpenVPN
if [ "$OVPN" == true ]; then
  if ping -c 1 -q -I tun0 itdog.info | grep -q "1 packets received"; then
    checkpoint_true "$OPENVPN_PROTOCOL"
  else
    checkpoint_false "$OPENVPN_PROTOCOL"
    if traceroute -i tun0 itdog.info -m 1 | grep ms | awk '{print $2}' | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'; then
      echo "$OPENVPN_ROUTING_DOESNT_WORK"
    else
      echo "$OPENVPN_TUNNEL_NOT_WORKING"
    fi
  fi

  # Check OpenVPN redirect-gateway
  if grep -q redirect-gateway /etc/openvpn/*; then
    checkpoint_false "$OPENVPN_REDIRECT_GATEWAY_ENABLED"
  else
    checkpoint_true "$OPENVPN_REDIRECT_GATEWAY_DISABLED"
  fi

  # Check route table
  if ip route show table vpn | grep -q "default dev tun0"; then
    checkpoint_true "$OPENVPN_ROUTING_TABLE_EXISTS"
  else
    checkpoint_false "$OPENVPN_ROUTING_TABLE_DOESNT_EXIST"
  fi
fi

if opkg list-installed | grep -q sing-box; then
  checkpoint_true "$SINGBOX_INSTALLED"

  # Check route table
  if ip route show table vpn | grep -q "default dev tun0"; then
    checkpoint_true "$SINGBOX_ROUTING_TABLE_EXISTS"
  else
    checkpoint_false "$SINGBOX_ROUTING_TABLE_DOESNT_EXIST"
  fi

  # Sing-box uci validation
  if uci show sing-box 2>&1 | grep -q "Parse error"; then
    checkpoint_false "$SINGBOX_UCI_CONFIG_ERROR"
  else
    checkpoint_true "$SINGBOX_UCI_CONFIG_OK"
  fi

  singbox_check_cmd="sing-box -c /etc/sing-box/config.json check"
  if $singbox_check_cmd >/dev/null 2>&1; then
    checkpoint_true "$SINGBOX_CONFIG_OK"

    # Check traffic
    IP_EXTERNAL=$(curl -s ifconfig.me)
    IFCONFIG=$(nslookup -type=a ifconfig.me | awk '/^Address: / {print $2}')

    IP_VPN=$(curl --interface tun0 -s ifconfig.me)

    if [ "$IP_EXTERNAL" != $IP_VPN ]; then
      checkpoint_true "$SINGBOX_WORKING"
    else
      checkpoint_false "$SINGBOX_ROUTING_DOESNT_WORK"
    fi
  else
    checkpoint_false "$SINGBOX_CONFIG_ERROR:"
    $singbox_check_cmd
  fi
fi

if which tun2socks | grep -q tun2socks; then
  checkpoint_true "$TUN2SOCKS_INSTALLED"

  # Check route table
  if ip route show table vpn | grep -q "default dev tun0"; then
    checkpoint_true "$TUN2SOCKS_ROUTING_TABLE_EXISTS"
  else
    checkpoint_false "$TUN2SOCKS_ROUTING_TABLE_DOESNT_EXIST"
  fi

  IP_EXTERNAL=$(curl -s ifconfig.me)
  IFCONFIG=$(nslookup -type=a ifconfig.me | awk '/^Address: / {print $2}')

  IP_VPN=$(curl --interface tun0 -s ifconfig.me)

  if [ "$IP_EXTERNAL" != $IP_VPN ]; then
    checkpoint_true "$TUN2SOCKS_WORKING"
  else
    checkpoint_false "$TUN2SOCKS_ROUTING_DOESNT_WORK"
  fi
fi

# Check sets

# vpn_domains set
vpn_domain_ipset_id=$(uci show firewall | grep -E '@ipset.*vpn_domains' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_domain_ipset_string=$(uci show firewall.@ipset[$vpn_domain_ipset_id] | grep -c "name='vpn_domains'\|match='dst_net'")
vpn_domain_rule_id=$(uci show firewall | grep -E '@rule.*vpn_domains' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_domain_rule_string=$(uci show firewall.@rule[$vpn_domain_rule_id] | grep -c "name='mark_domains'\|src='lan'\|dest='*'\|proto='all'\|ipset='vpn_domains'\|set_mark='0x1'\|target='MARK'\|family='ipv4'")

if [ $((vpn_domain_ipset_string + vpn_domain_rule_string)) -eq 10 ]; then
  checkpoint_true "$VPN_DOMAINS_SET_EXISTS"

  # force resolve for vpn_domains. All list
  nslookup terraform.io 127.0.0.1 >/dev/null
  nslookup pochta.ru 127.0.0.1 >/dev/null
  nslookup 2gis.ru 127.0.0.1 >/dev/null

  VPN_DOMAINS_IP=$(nft list ruleset | grep -A 10 vpn_domains | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
  if [ $VPN_DOMAINS_IP -ge 1 ]; then
    checkpoint_true "$IPS_IN_VPN_DOMAINS_SET_OK"
  else
    checkpoint_false "$IPS_IN_VPN_DOMAINS_SET_ERROR"
    printf "$VPN_DOMAINS_DETAILS\n"
    output_21
  fi
else
  checkpoint_false "$VPN_DOMAINS_SET_DOESNT_EXIST"
  printf "$VPN_DOMAINS_DETAILS_2\n"
fi

# vpn_ip set
vpn_ip_ipset_id=$(uci show firewall | grep -E '@ipset.*vpn_ip' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_ip_ipset_string=$(uci show firewall.@ipset[$vpn_ip_ipset_id] | grep -c "name='vpn_ip'\|match='dst_net'\|loadfile='/tmp/lst/ip.lst'")
vpn_ip_rule_id=$(uci show firewall | grep -E '@rule.*vpn_ip' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_ip_rule_string=$(uci show firewall.@rule[$vpn_ip_rule_id] | grep -c "name='mark_ip'\|src='lan'\|dest='*'\|proto='all'\|ipset='vpn_ip'\|set_mark='0x1'\|target='MARK'\|family='ipv4'")

if [ $((vpn_ip_ipset_string + vpn_ip_rule_string)) -eq 11 ]; then
  checkpoint_true "$VPN_IP_SET_EXISTS"
  VPN_IP_IP=$(nft list ruleset | grep -A 10 vpn_ip | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
  if [ $VPN_IP_IP -ge 1 ]; then
    checkpoint_true "$IPS_IN_VPN_IP_SET_OK"
  else
    checkpoint_false "$IPS_IN_VPN_IP_SET_ERROR"
    output_21
  fi
elif uci show firewall | grep -q "vpn_ip"; then
  checkpoint_false "$VPN_IP_SET_DOESNT_EXIST"
fi

# vpn_subnet set
vpn_subnet_ipset_id=$(uci show firewall | grep -E '@ipset.*vpn_subnet' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_subnet_ipset_string=$(uci show firewall.@ipset[$vpn_subnet_ipset_id] | grep -c "name='vpn_subnets'\|match='dst_net'\|loadfile='/tmp/lst/subnet.lst'")
vpn_subnet_rule_id=$(uci show firewall | grep -E '@rule.*vpn_subnet' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_subnet_rule_string=$(uci show firewall.@rule[$vpn_subnet_rule_id] | grep -c "name='mark_subnet'\|src='lan'\|dest='*'\|proto='all'\|ipset='vpn_subnets'\|set_mark='0x1'\|target='MARK'\|family='ipv4'")

if [ $((vpn_subnet_ipset_string + vpn_subnet_rule_string)) -eq 11 ]; then
  checkpoint_true "$VPN_SUBNET_SET_EXISTS"
  VPN_IP_SUBNET=$(nft list ruleset | grep -A 10 vpn_subnet | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
  if [ $VPN_IP_SUBNET -ge 1 ]; then
    checkpoint_true "$IPS_IN_VPN_SUBNET_SET_OK"
  else
    checkpoint_false "$IPS_IN_VPN_SUBNET_SET_ERROR"
    output_21
  fi
elif uci show firewall | grep -q "vpn_subnet"; then
  checkpoint_false "$VPN_SUBNET_SET_DOESNT_EXIST"
fi

# vpn_community set
vpn_community_ipset_id=$(uci show firewall | grep -E '@ipset.*vpn_community' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_community_ipset_string=$(uci show firewall.@ipset[$vpn_community_ipset_id] | grep -c "name='vpn_community'\|match='dst_net'\|loadfile='/tmp/lst/community.lst'")
vpn_community_rule_id=$(uci show firewall | grep -E '@rule.*vpn_community' | awk -F '[][{}]' '{print $2}' | head -n 1)
vpn_community_rule_string=$(uci show firewall.@rule[$vpn_community_rule_id] | grep -c "name='mark_community'\|src='lan'\|dest='*'\|proto='all'\|ipset='vpn_community'\|set_mark='0x1'\|target='MARK'\|family='ipv4'")

if [ $((vpn_community_ipset_string + vpn_community_rule_string)) -eq 11 ]; then
  checkpoint_true "$VPN_COMMUNITY_SET_EXISTS"
  VPN_COMMUNITY_IP=$(nft list ruleset | grep -A 10 vpn_community | grep -c -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
  if [ $VPN_COMMUNITY_IP -ge 1 ]; then
    checkpoint_true "$IPS_IN_VPN_COMMUNITY_SET_OK"
  else
    checkpoint_false "$IPS_IN_VPN_COMMUNITY_SET_ERROR"
    output_21
  fi
elif uci show firewall | grep -q "vpn_community"; then
  checkpoint_false "$VPN_COMMUNITY_SET_DOESNT_EXIST"
fi

# getdomains script
if [ -s "$GETDOMAINS_SCRIPT_PATH" ]; then
  checkpoint_true "$GETDOMAINS_SCRIPT_EXISTS"
  if crontab -l | grep -q $GETDOMAINS_SCRIPT_PATH; then
    checkpoint_true "$GETDOMAINS_SCRIPT_CRONTAB_OK"
  else
    checkpoint_false "$GETDOMAINS_SCRIPT_CRONTAB_ERROR"
  fi
else
  checkpoint_false "$GETDOMAINS_SCRIPT_DOESNT_EXIST"
fi

# DNS

# DNSCrypt
if opkg list-installed | grep -q dnscrypt-proxy2; then
  checkpoint_true "$DNSCRYPT_INSTALLED"
  if service dnscrypt-proxy status | grep -q 'running'; then
    checkpoint_true "$DNSCRYPT_SERVICE_RUNNING"
  else
    checkpoint_false "$DNSCRYPT_SERVICE_NOT_RUNNING"
    output_21
  fi

  DNSMASQ_STRING=$(uci show dhcp.@dnsmasq[0] | grep -c "127.0.0.53#53\|noresolv='1'")
  if [ $DNSMASQ_STRING -eq 2 ]; then
    checkpoint_true "$DNSMASQ_CONFIG_FOR_DNSCRYPT_OK"
  else
    checkpoint_false "$DNSMASQ_CONFIG_FOR_DNSCRYPT_ERROR"
  fi
fi

# Stubby
if opkg list-installed | grep -q stubby; then
  checkpoint_true "$STUBBY_INSTALLED"
  if service stubby status | grep -q 'running'; then
    checkpoint_true "$STUBBY_SERVICE_RUNNING"
  else
    checkpoint_false "$STUBBY_SERVICE_NOT_RUNNING"
    output_21
  fi

  STUBBY_STRING=$(uci show dhcp.@dnsmasq[0] | grep -c "127.0.0.1#5453\|noresolv='1'")
  if [ $STUBBY_STRING -eq 2 ]; then
    checkpoint_true "$DNSMASQ_CONFIG_FOR_STUBBY_OK"
  else
    checkpoint_false "$DNSMASQ_CONFIG_FOR_STUBBY_ERROR"
  fi
fi

case $COMMAND in
  dump)
    # Create dump
    printf "\n$COLOR_BOLD_CYAN$DUMP_CREATION$COLOR_RESET\n"
    date >$DUMP_PATH
    $HIVPN start >>$DUMP_PATH 2>&1
    $GETDOMAINS_SCRIPT_PATH start >>$DUMP_PATH 2>&1
    uci show firewall >>$DUMP_PATH
    uci show network | sed -r 's/(.*private_key=|.*preshared_key=|.*public_key=|.*endpoint_host=|.*wan.ipaddr=|.*wan.netmask=|.*wan.gateway=|.*wan.dns|.*.macaddr=).*/\1REMOVED/' >>$DUMP_PATH
    printf "$DUMP_DETAILS\n"
    ;;
  dns)
    # Check DNS
    printf "\n$COLOR_BOLD_CYAN$DNS_CHECK$COLOR_RESET\n"
    DNS_SERVERS="1.1.1.1 8.8.8.8 8.8.4.4"
    DOH_DNS_SERVERS="cloudflare-dns.com 1.1.1.1 mozilla.cloudflare-dns.com security.cloudflare-dns.com"
    DOMAINS="instagram.com facebook.com"

    echo "1. $IS_DNS_TRAFFIC_BLOCKED"

    for i in $DNS_SERVERS; do
      if nslookup -type=a -timeout=2 -retry=1 itdog.info $i | grep -q "timed out"; then
        checkpoint_false "$i"
      else
        checkpoint_true "$i"
      fi
    done

    echo "2. $IS_DOH_AVAILABLE"

    for i in $DOH_DNS_SERVERS; do
      if curl --connect-timeout 5 -s -H "accept: application/dns-json" "https://$i/dns-query?name=itdog.info&type=A" | awk -F"data\":\"" '/data":"/{print $2}' | grep -q -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'; then
        checkpoint_true "$i"
      else
        checkpoint_false "$i"
      fi
    done

    echo "3. $RESPONSE_NOT_CONTAINS_127_0_0_8"

    for i in $DOMAINS; do
      if nslookup -type=a -timeout=2 -retry=1 $i | awk '/^Address: / {print $2}' | grep -q -E '127\.[0-9]{1,3}\.'; then
        checkpoint_false "$i"
      else
        checkpoint_true "$i"
      fi
    done

    echo "4. $ONE_IP_FOR_TWO_DOMAINS"

    FIRSTIP=$(nslookup -type=a instagram.com | awk '/^Address: / {print $2}')
    SECONDIP=$(nslookup -type=a facebook.com | awk '/^Address: / {print $2}')

    if [ "$FIRSTIP" = "$SECONDIP" ]; then
      checkpoint_false "$IPS_ARE_THE_SAME"
    else
      checkpoint_true "$IPS_ARE_DIFFERENT"
    fi

    echo "5. $RESPONSE_IS_NOT_BLANK"

    for i in $DOMAINS; do
      if nslookup -type=a -timeout=2 -retry=1 $i | awk '/^Address: / {print $2}' | grep -q -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}'; then
        checkpoint_true "$i"
      else
        checkpoint_false "$i"
      fi
    done

    echo "6. $DNS_POISONING_CHECK"

    DOHIP=$(curl -s -H "accept: application/dns-json" "https://1.1.1.1/dns-query?name=facebook.com&type=A" | awk -F"data\":\"" '/data":"/{print $2}' | grep -oE '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}')
    OPENIP=$(nslookup -type=a -timeout=2 facebook.com 1.1.1.1 | awk '/^Address: / {print $2}')

    if [ "$DOHIP" = "$OPENIP" ]; then
      checkpoint_true "$IPS_ARE_THE_SAME"
    else
      checkpoint_false "$IPS_ARE_DIFFERENT"
    fi
    ;;
  *) ;;
esac

# Info
echo -e "\n$TELEGRAM_CHANNEL: https://t.me/itdoginfo"
echo "$TELEGRAM_CHAT: https://t.me/itdogchat"
