# Описание
Playbook для Ansible, автоматизирующий настройку обхода блокировок РКН через Wireguard на роутере с OpenWRT

Для взаимодействия c OpenWRT используется модуль [gekmihesg/ansible-openwrt](https://github.com/gekmihesg/ansible-openwrt)

Списки берутся с [antifilter.download](https://antifilter.download/)

Бонусом устанавливается и настраивается DNSCrypt2

Полное описание происходящего: https://itdog.info/tochechnyj-obhod-blokirovok-rkn-na-routere-s-openwrt-s-pomoshhyu-wireguard-i-dnscrypt/

И вот здесь: https://habr.com/ru/post/440030/

Поиск ошибок:
- https://itdog.info/tochechnyj-obhod-blokirovok-rkn-na-routere-s-openwrt-chast-2-poisk-i-ispravlenie-oshibok/
- https://habr.com/ru/post/702388/

Тестировалось с
- Ansible 2.9.27
- OpenWrt 21.02.5
- OpenWrt 22.03.3

# Использование

Для работы необходим wg сервер вне зоны действия РКН

Установить модуль gekmihesg/ansible-openwrt

``` ansible-galaxy install gekmihesg.openwrt ```

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
    wg_server_address: wg_server_ip/url
    wg_private_key: privatekey-client
    wg_public_key: publickey-client
    wg_listen_port: 51820
    wg_client_port: 51820
    wg_client_address: 192.168.100.3/24
    download_utility: curl
    list_subnet: true
    list_ip: true
    list_community: true
    list_domains: false
```

Обязательно нужно задать:

**wg_server_address** - ip/url wireguard сервера

**wg_private_key**, **wg_public_key** - ключи для "клиента"

**wg_client_address** - адрес роутера в wg сети

Переменные **list_** обозначают, какие списки нужно установить. true - установить, false - не устанавливать и удалить, если уже есть

При использовании **list_domains** должен быть установлен пакет dnsmasq-full. А для OpenWrt 22.03 версия dnsmasq-full должна быть => 2.87, её нет в официальном репозитории, но можно установить из dev репозитория. Инструкция по установке есть [в моём тг канале](https://t.me/itdoginf/12). Если это условие не выполнено, плейбук завершится с ошибкой

Остальное можно менять, в зависимости от того как настроен wireguard сервер

Если ваш wg сервер использует preshared_key, то раскомментируйте **wg_preshared_key** и задайте ключ

**download_utility** можно использовать curl или wget. Curl не скачивает заново списки, если на роутере они ещё актуальны

Запуск playbook
```
ansible-playbook playbooks/hirkn.yml
```

После выполнения playbook роутер сразу начнёт выполнять обход блокировок через Wireguard сервер.

# DNSCrypt-proxy2

Если у вас уже стоит dnscrypt-proxy первой версии, его необходимо удалить
```
opkg remove dnscrypt-proxy
```
Во второй версии есть отказоустойчивость из коробки.