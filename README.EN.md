Domain routing OpenWrt
=========

Configuring domain routing on Openwrt router.


Role Variables
--------------

Lists
```
  country: russia-inside|russia-outside|ukraine
  list_domains: true|falase

  list_subnet: false|true
  list_ip: false|true
  list_community: false|true
```

Tunnel
```
  tunnel: wg|openvpn|singbox|tun2socks
```

DoH or DoT
```
  dns_encrypt: false|dnscrypt|stubby
```

Nano package
```
  nano: true|false
```

Acces from wg network to router
```
  wg_access: false|true
  wg_access_network: 192.168.80.0/24 (for example)
```

If wireguard is used:
```
    wg_server_address: wg-server-host
    wg_private_key: privatekey-client
    wg_public_key: publickey-client
    wg_preshared_key: presharedkey-client
    wg_client_port: 51820
    wg_client_address: ip-client

    wg_access: true
    wg_access_network: wg-network
```

Dependencies
------------

[gekmihesg.openwrt](https://github.com/gekmihesg/ansible-openwrt)


Example Playbook
----------------

The inventory file must contain the group `[openwrt]` where your router will be located.


Wireguard, only domains, stubby, Russia, acces from wg network, host 192.168.1.1
```
- hosts: 192.168.1.1
  remote_user: root

  roles:
    - itdoginfo.domain_routing_openwrt

  vars:
    tunnel: wg
    dns_encrypt: stubby
    country: russia-inside
    
    wg_access: true
    wg_server_address: wg-server-host
    wg_private_key: privatekey-client
    wg_public_key: publickey-client
    wg_preshared_key: presharedkey-client
    wg_listen_port: 51820
    wg_client_port: 51820
    wg_client_address: ip-client
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

License
-------

GNU General Public License v3.0