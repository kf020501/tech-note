# CentOS6 初期設定

LPIC勉強するにあたり触る必要があったので、簡単に。

## ssh 

インストール済みのため、追加インストールは不要。

```sh
# 起動状態確認
service sshd status

    # openssh-daemon (pid  2148) を実行中...
```

## パッケージ管理

```sh
# インストール済み および 利用可能なパッケージ 一覧表示
yum list

# インストール済みパッケージ 表示
yum list installed
```

## DVDからパッケージをインストール

[yum を使って DVDからパッケージをインストールする | レンタルサーバー・自宅サーバー設定・構築のヒント](https://server-setting.info/centos/yum-install-from-dvd.html)

```sh
# DVDマウント
mkdir /mnt/dvd              # DVDマウント先を作成
mount /dev/dvd /mnt/dvd     # DVDマウント
ls /mnt/dvd                 # 確認

# リポジトリに追加(以下を追記)
vi /etc/yum.repos.d/CentOS-Media.repo
----------
[dvd]
name=dvd
baseurl=file:///mnt/dvd
gpgcheck=1
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-6
----------

# まずはupdate
yum update

# インストール
yum --disablerepo=* --enablerepo=dvd install -y openldap openldap-client openldap-servers
```
