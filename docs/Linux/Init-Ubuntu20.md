# Ubuntu20.04 初期設定

## バージョン確認
`hostnamectl`, `cat /etc/os-release`

## ユーザー作成

```sh
### ユーザ名「UserName」を作成・設定するサンプル ### 

useradd -m UserName         # UserName を作成 (-m ホームディレクトリ作成)
passwd UserName             # パスワードを変更 (コマンド実行後入力を求められる)
usermod -G sudo UserName   # sudoを使えるように sudoグループに追加(Debian系) -G で補助グループに追加 -gで主グループ指定

## 補足
/etc/passwd | grep UserName # 設定確認
  > UserName:x:1001:1001::/home/UserName:/bin/bash
userdel -r UserName         # UserName を削除 (-r ホームディレクトリも削除)
usermod -s /bin/bash UserName # ログインシェルを指定(フルパス)

groupadd GroupName  # グループを作成
cat /etc/group      # グループを確認
gpasswd -d UserName sudo # sudoから UserNameをはずす
```
よく使う。
```sh
# user01を作成 ホームディレクトリ作成、sudoグループに追加、ログインシェルをbashに
useradd -m user01 -G sudo -s /bin/bash
echo "user01:password01" | chpasswd # パスワードを指定
```

## SSHインストール(Desktop)

sshが標準では非搭載だったのでインストール。
```sh
sudo su -               # 管理者権限取得 標準でrootログイン無効のため
apt-get install ssh     # sshインストール openssh-server?
systemctl start sshd    # ssh起動
systemctl enable sshd   # ssh自動起動を許可
systemctl status sshd --no-pager  # ssh自動起動を許可


# なお、FWは初期設定でOKだった。
# (メモ：systemctl status ufw ← firewalldではない)
```

## vi で方向キーが効かない

- memo:RaspberryPi ver は不要だった
```bash 
# vi互換モードをoffにする？
vi ~/.vimrc
  set nocompatible

# または？
echo "set nocompatible" >> ~/.vimrc
```

## 日本語化 (Server)

[【Ubuntu 20.04/18.04 LTS Server】日本語環境にする（日本語ロケールとタイムゾーンの変更） | The modern stone age.](https://www.yokoweb.net/2018/05/04/ubuntu-18_04-lts-server-japanese/)
```bash
# 日本語関連パッケージのインストール
apt install -y language-pack-ja-base language-pack-ja ibus-mozc

# システムの文字セットを日本語に変更
localectl set-locale LANG=ja_JP.UTF-8 LANGUAGE="ja_JP:ja"

# タイムゾーン設定
timedatectl set-timezone Asia/Tokyo

``` 
## ホームディレクトリ名を英語に (Desktop)

GUIで実行
```
LANG=C xdg-user-dirs-gtk-update
```

## ネットワーク設定変更 (Desktop)

- NetworkManager ありなので、`nmtui`, `nmcli`が使用可能。
- 日本語版だと接続名が「有線接続 1」と全角文字になっているので、nmtuiのほうが設定しやすい。

```bash
nmcli c m 有線接続\ 1 connection.id ens160 ipv4.method manual ipv4.addresses 192.168.10.131/24 ipv4.gateway 192.168.10.254 ipv4.dns 8.8.8.8
nmcli connection up ens160 ; exit
```

## ネットワーク設定変更 (server)

- NetworkManager はないので、`nmtui`, `nmcli` は初期設定では使用できない。

```bash
cp /etc/netplan/nn-xxxxxxxxxx.yaml nn-xxxxxxxxxx.yaml.bk  # バックアップ

cat << '____EOF____' > /etc/netplan/99-netcfg.yaml # 新規作成

network:
  ethernets:
    ens160:
      addresses:
      - 10.30.0.51/24
      gateway4: 10.30.0.254
      nameservers:
        addresses:
        - 10.30.0.254
        search: []
  version: 2
____EOF____

# デバッグ
netplan --debug generate

# 適用 (再起動 不要)
netplan apply

# 確認
ip addr
```

参考：[【Ubuntu】 /etc/netplan/50-cloud-init.yamlを編集するの止めろ - Qiita](https://qiita.com/yas-nyan/items/9033fb1d1037dcf9dba5)

[Ubuntu20.04[server]でNetworkManagerを使いたい時のTips - Qiita](https://qiita.com/jack-low/items/6a4912e382626b9aecd8)

## 時刻同期
timedatectl で時刻同期されている模様

```sh
vi /etc/systemd/timesyncd.conf
  最終行に追記
  NTP=ntp.sample.com

systemctl restart systemd-timesyncd.service
systemctl status systemd-timesyncd.service  # 確認(同期先なども確認できる)
```

## ログ保存期間変更

共通設定は `/etc/logrotate.conf`で変更する

```sh
# see "man logrotate" for details
# rotate log files weekly
weekly  ★ ローテは週ごと

# use the adm group by default, since this is the owning group
# of /var/log/syslog.
su root adm

# keep 4 weeks worth of backlogs
rotate 4  ★ 4回分のログを保存

# create new (empty) log files after rotating old ones
create

# use date as a suffix of the rotated file
#dateext

# uncomment this if you want your log files compressed
#compress

# packages drop log rotation information into this directory
include /etc/logrotate.d

# system-specific logs may be also be configured here.
```

特定のログごとの設定は、`/etc/logrotate.d/`を触る。
syslogの保存設定を変えたい場合は`rsyslog`を編集

```text
/var/log/syslog
{
        rotate 7              # 7世代保管
        daily
        dateext               ★ syslog-20160608 となる
        dateformat _%Y-%m-%d  ★ さらにドーマットを変更したい場合 syslog_2016-06-08 となる
        missingok             # ログファイルがなくてもエラーを出さない
        notifempty
        delaycompress
        compress              # 圧縮
        postrotate
                /usr/lib/rsyslog/rsyslog-rotate
        endscript
}
```

## メモ

### WSL (Windows Subsystem for Linux)あれこれ

インストールは、
- ①「Windowsの機能の有効化または無効化」で、Windows Subsystem for Linuxを有効化 > 再起動
- ② Microsoft Storeから、Ubuntu 18.04をインストール
- 仮想マシンとかでなく、Windowsと共存してるってこと？
- WSL2も出たらしいがまだ試していない
```
# WindowsのCドライブへのアクセス
cd /mnt/c  # /mntにWindowsのCドライブがマウントされている。

# ネットワークドライブマウント
mkdir /mnt/share
mount -t drvfs //192.168.xxx.xxx/share /mnt/share
    #「-t cifs」ではマウントできず。
    #「-t drvfs」を使うといいみたい。
```

### ユーザー名の表示色変更

[Linuxのターミナルに出力される$の左側の色や文字列をカスタマイズする | Hodalog](https://hodalog.com/customize-prompt-of-linux/)

```sh
vi ~/.bashrc

[追記例]
PS1="\[\e[1;34m\][\u@\h \W]\[\e[m\]\$ "
```


### RDPでリモート接続

[第621回　Ubuntu 20.04 LTSでxrdpを使用する：Ubuntu Weekly Recipe｜gihyo.jp … 技術評論社](https://gihyo.jp/admin/serial/01/ubuntu-recipe/0621)

```sh
apt install -y xrdp
# これだけだと、Dockが表示されない不具合があるので、スクリプトを実行する。
bash ./enhanced-session-mode.sh
reboot
```

```sh
#!/bin/sh

# Add script to setup the ubuntu session properly
if [ ! -e /etc/xrdp/startubuntu.sh ]; then
cat >> /etc/xrdp/startubuntu.sh << EOF
#!/bin/sh
export GNOME_SHELL_SESSION_MODE=ubuntu
export XDG_CURRENT_DESKTOP=ubuntu:GNOME
exec /etc/xrdp/startwm.sh
EOF
chmod a+x /etc/xrdp/startubuntu.sh
fi

sed -i_orig -e 's/startwm/startubuntu/g' /etc/xrdp/sesman.ini

# rename the redirected drives to 'shared-drives'
sed -i -e 's/FuseMountName=thinclient_drives/FuseMountName=shared-drives/g' /etc/xrdp/sesman.ini

# Changed the allowed_users
sed -i_orig -e 's/allowed_users=console/allowed_users=anybody/g' /etc/X11/Xwrapper.config

# Configure the policy xrdp session
cat > /etc/polkit-1/localauthority/50-local.d/45-allow-colord.pkla <<EOF
[Allow Colord all Users]
Identity=unix-user:*
Action=org.freedesktop.color-manager.create-device;org.freedesktop.color-manager.create-profile;org.freedesktop.color-manager.delete-device;org.freedesktop.color-manager.delete-profile;org.freedesktop.color-manager.modify-device;org.freedesktop.color-manager.modify-profile
ResultAny=no
ResultInactive=no
ResultActive=yes
EOF

# https://askubuntu.com/questions/1193810/authentication-required-to-refresh-system-repositories-in-ubuntu-19-10
cat > /etc/polkit-1/localauthority/50-local.d/46-allow-update-repo.pkla<<EOF
[Allow Package Management all Users]
Identity=unix-user:*
Action=org.freedesktop.packagekit.system-sources-refresh
ResultAny=yes
ResultInactive=yes
ResultActive=yes
EOF
```

## cifsクライアントとして使用した際の文字化け

1. ubuntuからcifsサーバに日本語名のファイルを保存した場合、
2. 同ファイルを他のホスト(Windowsなど)で見ると文字化けしている

対処方法: マウントオプションで`iocharset=utf8`を指定

単に指定すると以下のようなエラーが出る
```text
mount error(79): Can not access a needed shared library
```

事前に以下のコマンドでライブラリのインストールが必要
```sh
apt install -y linux-generic
reboot
```

### vmfs iSCSI マウント

認証なし
```sh
apt install vmfs-tools
apt -y install open-iscsi

# 確認
iscsiadm -m discovery -t sendtargets -p 10.xx.xx.xx
> 10.xx.xx.xx:3260,1 iqn.2005-10.org.xxxxx.xxxxx:xxxxx.xxxxx

# iSCSI接続
iscsiadm -m node -T iqn.2005-10.org.xxxxx.xxxxx:xxxxx.xxxxx -p 10.xx.xx.xx --login

# マウント確認
iscsiadm -m session
> tcp: [1] 10.xx.xx.xx:3260,1 iqn.2005-10.org.xxxxx.xxxxx:xxxxx.xxxxx (non-flash)

# iSCSIがどこにマウントされているか確認 もっといい方法は？？
lsblk
> 今回は sdb1 にマウントされている模様(容量から推測)

# vmfsマウント --> 失敗 マウントしようとしたら以下の通知
vmfs-fuse /dev/sdb1 /mnt/vmfs/
> VMFS: Unsupported version 6
```