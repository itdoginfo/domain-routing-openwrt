# Описание
Shell скрипт и playbook для Ansible. Автоматизируют настройку OpenWrt роутера для обхода блокировок по доменам и спискам IP-адресов.

Полное описание происходящего: [Статья на хабре](!!)

## Скрипт для установки
Запуск
```
wget -O - https://raw.githubusercontent.com/itdoginfo/ansible-openwrt-hirkn/master/getdomains-install.sh | sh
```

Подробности описаны в статье указаной выше.

## Ansible
Для взаимодействия c OpenWRT используется модуль [gekmihesg/ansible-openwrt](https://github.com/gekmihesg/ansible-openwrt)

Домены берутся из [отсюда](https://github.com/itdoginfo/allow-domains). Списки IP-адресов берутся с [antifilter.download](https://antifilter.download/)

Тестировалось с
- Ansible 2.10.8

- OpenWrt 21.02.7
- OpenWrt 22.03.5
- OpenWrt 23.05.0-rc2

## Выбор туннеля
- Wireguard настраивается автоматически через переменные
- OpenVPN устанавливается пакет, настраивается роутинг и зона. Само подключение (скопировать конфиг и перезапустить openvpn) нужно [настроить вручную](https://itdog.info/nastrojka-klienta-openvpn-na-openwrt/)
- Sing-box устанавливает пакет, настраивается роутинг и зона. Также кладётся темплейт в `/etc/sing-box/config.json`. Нужно настроить `config.json` и сделать `service sing-box restart`
Не работает под 21ой версией. Поэтому при его выборе playbook выдаст ошибку.
Для 22ой версии нужно установить пакет вручную.
- tun2socks настраивается только роутинг и зона. Всё остальное нужно настроить вручную

Для **tunnel** четыре возможных значения:
- wg
- openvpn
- singbox
- tun2socks

## Шифрование DNS
Если ваш провайдер не подменяет DNS-запросы, ничего устанавливать не нужно.

Для **dns_encrypt** три возможных значения:
- dnscrypt
- stubby
- false/закомментировано - пропуск, ничего не устанавливается и не настраивается

## Выбор страны
 Для **county** три [возможных значения](https://github.com/itdoginfo/allow-domains):
- russia-inside
- russia-outside
- ukraine

## Списки IP-адресов и домены
Я советую использовать только домены
```
    list_domains: true
```
Если вам требуются списки IP-адресов, они также поддерживаются.

## Использование

Установить модуль gekmihesg/ansible-openwrt

```
ansible-galaxy install gekmihesg.openwrt
```

Скачать playbook и темплейты в /etc/ansible

```
cd /etc/ansible
git clone https://github.com/itdoginfo/ansible-openwrt-hirkn
mv ansible-openwrt-hirkn/* .
rm -rf ansible-openwrt-hirkn README.md
```

Добавить роутер в файл hosts в группу openwrt
```
[openwrt]
192.168.1.1
```

Подставить переменные в **hirkn.yml**
```
  vars:
    ansible_template_dir: /etc/ansible/templates/
    list_domains: true
    list_subnet: false
    list_ip: false
    list_community: false
    tunnel: wg
    dns_encrypt: false
    country: russia-inside

    wg_server_address: wg-server-host
    wg_private_key: privatekey-client
    wg_public_key: publickey-client
    #wg_preshared_key: presharedkey-client
    wg_listen_port: 51820
    wg_client_port: 51820
    wg_client_address: ip-client
```

Обязательно нужно задать:

Переменные **list_** обозначают, какие списки нужно установить. true - установить, false - не устанавливать и удалить, если уже есть

При использовании **list_domains** нужен пакет dnsmasq-full.

Для 23.05 устанавливается автоматически.

Для OpenWrt 22.03 версия dnsmasq-full должна быть => 2.87, её нет в официальном репозитории, но можно установить из dev репозитория. Если это условие не выполнено, плейбук завершится с ошибкой.

[Инструкция для OpenWrt 22.03](https://t.me/itdoginf/12)
[Инструкция для OpenWrt 21.02](https://t.me/itdoginfo/8)

В случае использования WG обязательно нужно задать:
**wg_server_address** - ip/url wireguard сервера

**wg_private_key**, **wg_public_key** - ключи для "клиента"

**wg_client_address** - адрес роутера в wg сети

Если ваш wg сервер использует preshared_key, то раскомментируйте **wg_preshared_key** и задайте ключ

Остальное можно менять, в зависимости от того, как настроен wireguard сервер

Запуск playbook
```
ansible-playbook playbooks/hirkn.yml --limit 192.168.1.1
```

После выполнения playbook роутер сразу начнёт выполнять обход блокировок.

Если у вас были ошибки и они исправились при повторном запуске playbook, но при этом обход не разработал, сделайте рестарт сети и скрипта:
```
service network restart
service getdomains start
```

# Скрипт для проверки конфигурации

Написан для OpenWrt 22.03. На 21.02 работает только половина проверок.

[x] - не обязательно означает, что эта часть не работает. Но это повод для ручной проверки.

Есть функционал сохранения вывода скрипта, конфигурации сети и firewall в файл. Все чувствительные переменные при этом затираются.

### Запуск
```
wget -O - https://raw.githubusercontent.com/itdoginfo/ansible-openwrt-hirkn/master/getdomains-check.sh | sh
```

### Запустить с созданием dump
```
wget -O - https://raw.githubusercontent.com/itdoginfo/ansible-openwrt-hirkn/master/getdomains-check.sh | sh -s dump
```

### Скачать и потом запустить
```
wget https://raw.githubusercontent.com/itdoginfo/ansible-openwrt-hirkn/master/getdomains-check.sh
chmod +x check-hirkn.sh
./check-hirkn.sh
```

С созданием dump
```
./check-hirkn.sh dump
```

Поиск ошибок вручную: https://habr.com/ru/post/702388/

---

[Telegram-канал с обновлениями](https://t.me/+lW1HmBO_Fa00M2Iy)