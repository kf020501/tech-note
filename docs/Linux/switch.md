
# LinuxでL3スイッチ

どこかを見ながら作ったんだけど、
作り方をメモしてなかったのでhistoryから掘り返してみる
参考にしたURLすらメモってない..


## 手順


```
ens192
  IP：192.168.10.254/24
  GW：192.168.10.1
  DNS：8.8.8.8

ens224
  IP：192.168.30.253/24
```

```bash

# 接続名確認 NAME が接続名
nmcli c show

    # NAME         UUID                                  TYPE      DEVICE
    # System eth0  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  ethernet  eth0
    # System eth1  xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  ethernet  eth1

# IFにゾーンを割りふる
nmcli c mod ens192 connection.zone external
nmcli c mod ens224 connection.zone internal

# 確認
firewall-cmd --reload
firewall-cmd --get-active-zone

| internal
|   interfaces: ens224
| external
|   interfaces: ens192


# externalゾーンをmasquerade設定にする(既になっているかも)
firewall-cmd --zone=internal --add-masquerade --permanen
firewall-cmd --zone=external --add-masquerade --permanen

# externalからの通信を許可する
firewall-cmd --zone=external --set-target=ACCEPT --permanent 

# 参考；FWの許可・不許可サンプル
firewall-cmd --add-service=ssh --zone=public --permanent
firewall-cmd --add-port=22/tcp --zone=public --permanent
firewall-cmd --remove-service=ssh --zone=public --permanent
firewall-cmd --remove-port=22/tcp --zone=public --permanent

# 確認
firewall-cmd --reload
firewall-cmd --list-all-zones # または、firewall-cmd --zone=<zone名> --list-all

| internal (active)
|   target: default
|   icmp-block-inversion: no
|   interfaces: ens224
|   sources:
|   services: dhcpv6-client mdns samba-client ssh
|   ports:
|   protocols:
|   masquerade: no
|   forward-ports:
|   source-ports:
|   icmp-blocks:
|   rich rules:

| public (active)
|   target: ACCEPT
|   icmp-block-inversion: no
|   interfaces: ens192
|   sources:
|   services: dhcpv6-client ssh
|   ports:
|   protocols:
|   masquerade: yes
|   forward-ports:
|   source-ports:
|   icmp-blocks:
|   rich rules:

```

ポートフォワード設定しなくてもできてしまったのだが...
多くのところでは、以下実施している

```bash

vi /etc/sysctl.conf
  net.ipv4.ip_forward = 1

cat /proc/sys/net/ipv4/ip_forward 



echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
```

## コマンドについて

/etc/sysconfig/network-scripts/ifcfg-xxxxxx の直接書き換えは非推奨で、nmcliコマンドを使うといいみたい。  
[Tab] キーで選択肢表示しながら操作すると、だいぶ使いやすそう。

```bash

# 設定確認
nmcli

# 設定確認 connection指定 詳細
nmcli connection show <接続名>

        # 例) nmcli c s ens192 | grep ipv4
        # 大文字の IP4.ADDRESS などは現在反映済みの値？

# IPアドレス変更
nmcli connection modify <接続名> [変更する項目1] [値1] [変更する項目2] [値2].....

        # 例) 右記の 3点を変更する ipv4.method , ipv4.addresses , ipv4.gatewa , ipv4.dns
        #     nmcli c m ens192 ipv4.method manual ipv4.addresses 192.168.10.100/24 ipv4.gateway 192.168.10.254 ipv4.dns 192.168.10.254
        #     nmcli c m ens192 ipv4.method auto ipv4.addresses "" ipv4.gateway "" ipv4.dns ""
        # 変更する項目は nmcli connection show <接続名> で確認

# 設定反映
nmcli connection up <接続名>

# 接続名を作成したり削除したり

nmcli connection add                  # Connectionの作成
nmcli connection delete <接続名>  # Connectionの削除
nmcli connection up <接続名>      # Connectionの設定反映 Deviceとの手動紐づけ

nmcli connection modify <接続名> +ipv4.routes "192.168.122.0/24 10.10.10.1" # スタティックルートを作成
nmcli connection modify <接続名> -ipv4.routes "192.168.122.0/24 10.10.10.1" # スタティックルートを削除
```



★[nmcliコマンドの基礎 - えんでぃの技術ブログ](https://endy-tech.hatenablog.jp/entry/2018/09/08/140950#Device-%E3%81%A8-Connection)


[Linux（CentOS 7）でルータを構築する最も簡単な手順 | TURNING POINT](https://turningp.jp/server-client/linux/linux-centos7-router)


## 追記 DNS用 ポートフォワード

```bash
firewall-cmd --zone=internal --list-all

# 下記だと、宛先アドレスがスイッチでなくてもフォワードしてしまう模様
# firewall-cmd --zone=internal --add-forward-port=port=53:proto=tcp:toport=53:toaddr=8.8.8.8 --permanent
# firewall-cmd --zone=internal --add-forward-port=port=53:proto=udp:toport=53:toaddr=8.8.8.8 --permanent

# firewall-cmd --zone=external --add-forward-port=port=53:proto=tcp:toport=53:toaddr=8.8.8.8 --permanent
# firewall-cmd --zone=external --add-forward-port=port=53:proto=udp:toport=53:toaddr=8.8.8.8 --permanent

firewall-cmd --permanent --direct --add-rule ipv4 nat PREROUTING 0 -d 10.30.0.254/32 -p tcp --dport 53 -j DNAT --to-destination 10.30.0.124:53
firewall-cmd --permanent --direct --add-rule ipv4 nat PREROUTING 0 -d 10.30.0.254/32 -p udp --dport 53 -j DNAT --to-destination 10.30.0.124:53

firewall-cmd --reload
firewall-cmd --zone=internal --list-all
firewall-cmd --zone=internal --add-rich-rule='rule family=ipv4 destination address=192.168.10.0/24 drop' --permanent
firewall-cmd --zone=internal --add-rich-rule='rule family=ipv4 destination address=192.168.10.0/24 reject' --permanent
firewall-cmd --zone=internal --add-rich-rule='rule family=ipv4 destination address=192.168.0.0/16 source address="172.16.0.0/16" reject' --permanent



```

## note: 割り振ったzoneがリセットされる

Proxmox環境で発生。おそらくcloud-initが起動時に設定上書きしている気がする。



## 参考

[Firewalld リッチルール | りんか ネット](https://rin-ka.net/rich-rules/)