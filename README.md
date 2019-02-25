# Описание
Playbook для Ansible, автоматизирующий настройку обхода блокировок РКН через Wireguard на роутере с OpenWRT

Для взаимодействия c OpenWRT используется модуль [gekmihesg/ansible-openwrt](https://github.com/gekmihesg/ansible-openwrt)

Списки берутся с [antifilter.download](https://antifilter.download/)

Бонусом устанавливается и настраивается DNSCrypt

Полное описание происходящего: https://itdog.info/tochechnyj-obhod-blokirovok-rkn-na-routere-s-openwrt-s-pomoshhyu-wireguard-i-dnscrypt/

И вот здесь: https://habr.com/ru/post/440030/

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
```

Обязательно нужно задать:

**wg_server_address** - ip/url wireguard сервера

**wg_private_key**, **wg_public_key** - ключи для "клиента"

Остальное можно менять, в зависимости от того как настроен wireguard сервер

Запуск playbook
```
ansible-playbook playbooks/hirkn.yml
```

После выполнения playbook роутер сразу начнёт выполнять обход блокировок через Wireguard сервер.
