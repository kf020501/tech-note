
# WireGuard


## インストール
```sh
# インストール
apt install wireguard
apt install ufw

# firewall設定
ufw default deny incoming   # 受信パケット デフォルトはすべて拒否
ufw default allow outgoing  # 送信パケット デフォルトはすべて許可する
ufw allow 22                # ポート22(SSH)を許可
ufw allow 51820/udp         # UDPポート許可(wireguard)
ufw enable                  # ufw 有効化
ufw status                  # 確認


```

## 鍵の作成方法

VPNに参加するホスト分、秘密鍵と公開鍵を作成する。

```sh
umask 177
# 秘密鍵の生成方法
wg genkey | tee /etc/wireguard/server-private.key
# 秘密鍵から公開鍵を生成
cat /etc/wireguard/server-private.key | wg pubkey

wg genkey | tee /dev/tty | wg pubkey
```

実行例: 
```text
root@wireguard:~# wg genkey | tee /dev/tty | wg pubkey
XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX=  ★ こちらが秘密鍵
xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=  ★ こちらが公開鍵
```

例として、以下のように作成できた事とする。


| ホスト         | 秘密鍵(各ホストの設定に記載) | (公開鍵 対向ホストの設定に記載) |
| -------------- | ---------------------------- | ------------------------------- |
| WGサーバー用   | XXXXXXXXXXXXXXXXXXXX=        | xxxxxxxxxxxxxxxxxxxx=           |
| クライアント01 | YYYYYYYYYYYYYYYYYYYY=        | yyyyyyyyyyyyyyyyyyyy=           |
| クライアント02 | ZZZZZZZZZZZZZZZZZZZZ=        | zzzzzzzzzzzzzzzzzzzz=           |

## サーバーの設定ファイル

/etc/wireguard/インターフェース.conf

/etc/wireguard/wg0.conf
```text
[Interface]
# サーバプライベートキー
PrivateKey = XXXXXXXXXXXXXXXXXXXX=
# VPN インターフェースに割り当てる IP アドレス
Address = 10.0.100.1
# サーバーでリスンする UDP ポート
ListenPort = 51820

# WireGuard 起動後/終了後に任意のコマンドを実行可能なので、
# wg0 -> ens160 の通信をMASQUERADE する設定を記載する
# ローカルネットワークへのルーティングルールを設定
# wg0: VPN インターフェース名
# ens160: イーサネット インターフェース名
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o ens160 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o ens160 -j MASQUERADE

[Peer]
# クライアント01の設定を記載
# クライアント01のパブリックキー
PublicKey = yyyyyyyyyyyyyyyyyyyy=
# 接続を許可するクライアントの VPN の IP アドレス
AllowedIPs = 10.0.100.2/32

[Peer]
# クライアント02の設定を記載
# クライアント02のパブリックキー
PublicKey = zzzzzzzzzzzzzzzzzzzz=
# 接続を許可するクライアントの VPN の IP アドレス
AllowedIPs = 10.0.100.3/32
```

# クライアント01の設定ファイル

peer01.conf
```text
[Interface]
# クライアントプライベートキー
PrivateKey = YYYYYYYYYYYYYYYYYYYY=
# VPN インターフェースに割り当てる IP アドレス
Address = 10.0.100.3

[Peer]
# サーバー用パブリックキー
PublicKey = xxxxxxxxxxxxxxxxxxxx=
# 接続を許可するクライアントの VPN の IP アドレス
AllowedIPs = 10.30.0.0/16, 192.168.10.0/24
Endpoint = wireguard.example.com:51820
```

## クライアント02の設定ファイル

peer02.conf
```text
[Interface]
# クライアントプライベートキー
PrivateKey = ZZZZZZZZZZZZZZZZZZZZ=
# VPN インターフェースに割り当てる IP アドレス
Address = 10.0.100.2

[Peer]
# サーバー用パブリックキー
PublicKey = xxxxxxxxxxxxxxxxxxxx=
# 接続を許可するクライアントの VPN の IP アドレス
AllowedIPs = 10.0.100.0/24
Endpoint = wireguard.example.com:51820
```

## ログ出力設定

ログを /var/log/syslog に出力させる

[Quick Start - WireGuard](https://www.wireguard.com/quickstart/)

```sh
# 動的デバッグを有効にする
echo module wireguard +p > /sys/kernel/debug/dynamic_debug/control

# 動的デバッグを無効にする場合は以下
# echo module wireguard -p > /sys/kernel/debug/dynamic_debug/control

# 確認 いっぱい出てくればOK 何も出てこなければ無効化できている
cat /sys/kernel/debug/dynamic_debug/control | grep -e 'wireguard.*=p'
```

上記は再起動すると設定が失われるため、/etc/crontabに設定を追加する。
※ 軌道に間に合わなかったみたいなので、雑に1分sleepした

```sh
echo '@reboot root sleep 60 ; /usr/sbin/modprobe wireguard && echo module wireguard +p > /sys/kernel/debug/dynamic_debug/control' >> /etc/crontab
```

## 起動
```sh 
systemctl start wg-quick@wg0
systemctl enable wg-quick@wg0
systemctl restart wg-quick@wg0

systemctl status wg-quick@wg0
```


## Firewall設定
```sh
# インストール
apt install ufw

# firewall設定
ufw default deny incoming   # 受信パケット デフォルトはすべて拒否
ufw default allow outgoing  # 送信パケット デフォルトはすべて許可する
ufw allow 22                # ポート22(SSH)を許可
ufw allow 51820/udp         # UDPポート許可(wireguard)
ufw enable                  # ufw 有効化
ufw status                  # 確認

# 開始・有効化
systemctl enable ufw
systemctl start ufw
systemctl status ufw
```

## 参考

* [Ubuntu 20.04 LTS : WireGuard : サーバーの設定 : Server World](https://www.server-world.info/query?os=Ubuntu_20.04&p=wireguard&f=1)
* [第614回　WireGuardでVPNサーバーを構築する：Ubuntu Weekly Recipe｜gihyo.jp … 技術評論社](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0614)

* [wireguardでlinuxサーバとandroidスマホとでvpn接続 - ぱっそ あ ぱっそ](https://acecat.hatenablog.com/entry/2020/05/07/074921)

[WireGuard VPN の利用 [MA-E/MA-S/MA-X/IP-K/XG Developers' WiKi]](https://ma-tech.centurysys.jp/doku.php?id=mae3xx_ope:use_wireguard_vpn:start)

[技術メモメモ: WireGuardの接続・切断のログをファイルに出力させる手順](https://tech-mmmm.blogspot.com/2022/04/wireguard.html)

[技術メモメモ: WireGuardを使って自宅にVPN接続する方法](https://tech-mmmm.blogspot.com/2021/11/wireguardvpn.html)


## 補足: AWSのインスタンスでうまくいかなかった


AWSのEC2インスタンスではデフォルトで「Source/Destination Check」が有効になっています。この設定が有効だと、該当インスタンスがルーティングデバイスとして動作できません。

確認事項：

WG(AWS)のインスタンスで「Source/Destination Check」を無効にしてください。
設定方法：

AWSマネジメントコンソールにログイン。
WG(AWS)インスタンスを選択。
[Actions] → [Networking] → [Change Source/Destination Check]。
「Disable」に設定。