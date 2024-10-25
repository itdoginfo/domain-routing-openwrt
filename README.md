[English role README](https://github.com/itdoginfo/domain-routing-openwrt/blob/master/README.EN.md)

# Описание
Shell скрипт и [роль для Ansible](https://galaxy.ansible.com/ui/standalone/roles/itdoginfo/domain_routing_openwrt). Автоматизируют настройку роутера на OpenWrt для роутинга по доменам и спискам IP-адресов.

Полное описание происходящего:
- [Статья на хабре](https://habr.com/ru/articles/767464/)
- [Копия в моём блоге](https://itdog.info/tochechnyj-obhod-blokirovok-po-domenam-na-routere-s-openwrt/)

# Скрипт для установки
```
sh <(wget -O - https://raw.githubusercontent.com/itdoginfo/domain-routing-openwrt/master/getdomains-install.sh)
```

# Скрипт для удаления
```
sh <(wget -O - https://raw.githubusercontent.com/itdoginfo/domain-routing-openwrt/refs/heads/master/getdomains-uninstall.sh)
```

## AmneziaWG
Через этот скрипт можно установить Amnezia wireguard. Скрипт проверяет наличие пакетов под вашу платформу в [стороннем репозитории](https://github.com/Slava-Shchipunov/awg-openwrt/releases), так как в официальном репозитории OpenWRT они отсутствуют, и автоматически их устанавливает.

Если вам нужно установить только AWG, воспользуйтесь скриптом в репозитории: https://github.com/Slava-Shchipunov/awg-openwrt

Если подходящих пакетов нет, перед настройкой необходимо будет самостоятельно [собрать бинарники AmneziaWG](https://github.com/itdoginfo/domain-routing-openwrt/wiki/Amnezia-WG-Build) для своего устройства и установить их.

## Скрипт для проверки конфигурации
Написан для OpenWrt 23.05 и 22.03. На 21.02 работает только половина проверок.

[x] - не обязательно означает, что эта часть не работает. Но это повод для ручной проверки.

### Запуск
```
wget -O - https://raw.githubusercontent.com/itdoginfo/domain-routing-openwrt/master/getdomains-check.sh | sh
```

По-умолчанию запускается на русском языке. Если нужно запустить на английском, то после `sh` нужно добавить `-s --lang en`. Аналогично для проверок на подмену DNS и создания дампа.

```
wget -O - https://raw.githubusercontent.com/itdoginfo/domain-routing-openwrt/master/getdomains-check.sh | sh -s --lang en
```

### Запустить с проверкой на подмену DNS
```
wget -O - https://raw.githubusercontent.com/itdoginfo/domain-routing-openwrt/master/getdomains-check.sh | sh -s dns
```

### Запустить с созданием dump
Все чувствительные переменные затираются.

```
wget -O - https://raw.githubusercontent.com/itdoginfo/domain-routing-openwrt/master/getdomains-check.sh | sh -s dump
```

Поиск ошибок вручную: https://habr.com/ru/post/702388/

# Ansible
Установить роль
```
ansible-galaxy role install itdoginfo.domain_routing_openwrt
```

Примеры playbooks

Wireguard, only domains, stubby, Russia, acces from wg network (пример 192.168.80.0/24), host 192.168.1.1
```
- hosts: 192.168.1.1
  remote_user: root

  roles:
    - itdoginfo.domain_routing_openwrt

  vars:
    tunnel: wg
    dns_encrypt: stubby
    country: russia-inside

    wg_server_address: wg-server-host
    wg_private_key: privatekey-client
    wg_public_key: publickey-client
    wg_preshared_key: presharedkey-client
    wg_listen_port: 51820
    wg_client_port: 51820
    wg_client_address: ip-client

    wg_access: true
    wg_access_network: wg-network
```

Sing-box, stubby, Russia
```
- hosts: 192.168.1.1
  remote_user: root

  roles:
    - itdoginfo.domain_routing_openwrt

  vars:
    tunnel: singbox
    dns_encrypt: stubby
    country: russia-inside

  tasks:
  - name: sing-box config
    template:
      src: "templates/openwrt-sing-box-json.j2"
      dest: "/etc/sing-box/config.json"
      mode: 0644
    notify:
      - Restart sing-box
      - Restart network
```

В inventory файле роутер обязательно должен быть в группе `[openwrt]`
```
[openwrt]
192.168.1.1
```

Для работы Ansible c OpenWrt необходимо, чтоб было выполнено одно из условий:
- Отсутствие пароля для root (не рекомендуется)
- Настроен доступ через публичный SSH-ключ в [конфиге dropbear](https://openwrt.org/docs/guide-user/security/dropbear.public-key.auth)

После выполнения playbook роутер сразу начнёт роутить необходмые домены в туннель/прокси.

Если у вас были ошибки и они исправились при повторном запуске playbook, но при этом роутинг не заработал, сделайте рестарт сети и скрипта:
```
service network restart
service getdomains start
```

Тестировалось с
- Ansible 2.10.8
- OpenWrt 21.02.7
- OpenWrt 22.03.5
- OpenWrt 23.05.2

## Выбор туннеля
- Wireguard настраивается автоматически через переменные
- OpenVPN устанавливается пакет, настраивается роутинг и зона. Само подключение (скопировать конфиг и перезапустить openvpn) нужно [настроить вручную](https://itdog.info/nastrojka-klienta-openvpn-na-openwrt/)
- Sing-box устанавливает пакет, настраивается роутинг и зона. Также кладётся темплейт в `/etc/sing-box/config.json`. [Нужно настроить](https://habr.com/ru/articles/767458/) `config.json` и сделать `service sing-box restart`
Не работает под 21ой версией. Поэтому при его выборе playbook выдаст ошибку.
Для 22ой версии нужно установить пакет вручную.
- tun2socks настраивается только роутинг и зона. Всё остальное нужно настроить вручную

Для **tunnel** шесть возможных значений:
- wg
- openvpn
- singbox
- tun2socks

В случае использования WG:
```
    wg_server_address: wg-server-host
    wg_private_key: privatekey-client
    wg_public_key: publickey-client
    wg_preshared_key: presharedkey-client
    wg_client_port: 51820
    wg_client_address: ip-client
```

Если ваш wg сервер не использует `preshared_key`, то просто не задавайте её.

**wg_access** и **wg_access_network** для доступа к роутеру через WG. Переменная wg_access_network должна иметь значение подсети, например 192.168.10.0/24.
```
    wg_access_network: wg-network
    wg_access: true
```

## Шифрование DNS
Если ваш провайдер не подменяет DNS-запросы, ничего устанавливать не нужно.

Для **dns_encrypt** три возможных значения:
- dnscrypt
- stubby
- false/закомментировано - пропуск, ничего не устанавливается и не настраивается

## Выбор страны
Выбор списка доменов.
Для **county** три [возможных значения](https://github.com/itdoginfo/allow-domains):
- russia-inside
- russia-outside
- ukraine

## Списки IP-адресов
Списки IP-адресов берутся с [antifilter.download](https://antifilter.download/)
Переменные **list_** обозначают, какие списки нужно установить. true - установить, false - не устанавливать и удалить, если уже есть

Доступные переменные
```
  list_domains: true
  list_subnet: false
  list_ip: falses
  list_community: false
```

Я советую использовать только домены
```
    list_domains: true
```
Если вам требуются списки IP-адресов, они также поддерживаются.

При использовании **list_domains** нужен пакет dnsmasq-full.

Для 23.05 dnsmasq-full устанавливается автоматически.

Для OpenWrt 22.03 версия dnsmasq-full должна быть => 2.87, её нет в официальном репозитории, но можно установить из dev репозитория. Если это условие не выполнено, плейбук завершится с ошибкой.

[Инструкция для OpenWrt 22.03](https://t.me/itdoginf/12)

[Инструкция для OpenWrt 21.02](https://t.me/itdoginfo/8)

## Текстовый редактор nano
Устанавливается по умолчанию. Можно выключить
```
  nano: false
```

---

[Telegram-канал с обновлениями](https://t.me/+lW1HmBO_Fa00M2Iy)
