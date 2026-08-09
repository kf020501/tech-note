# ローカルリポジトリ作成


## OSのインストールDVDを使用

RHEL8.6 のサンプル。
DVDを挿入して作業。

```sh
# DVDマウント用のディレクトリを作成
mkdir /mnt/cdrom

# DVDをマウント・確認
mount /dev/cdrom /mnt/cdrom
ls /mnt/cdrom

    # [manage@redhat8 ~]$ ls /mnt/cdrom/
    # AppStream  EFI   GPL                      RPM-GPG-KEY-redhat-release  extra_files.json  isolinux
    # BaseOS     EULA  RPM-GPG-KEY-redhat-beta  TRANS.TBL                   images            media.repo

# リポジトリ構成ファイルを作成。
cat << __EOF__ > /etc/yum.repos.d/rhel8-dvd.repo
[dvd-BaseOS]
name=Red Hat Enterprise Linux 8 - BaseOS
baseurl=file:///mnt/cdrom/BaseOS
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[dvd-AppStream]
name=Red Hat Enterprise Linux 8 - AppStream
baseurl=file:///mnt/cdrom/AppStream
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
__EOF__

# 有効なリポジトリを確認
dnf repolist enabled

    # [root@redhat8 ~]# dnf repolist enabled
    # サブスクリプション管理リポジトリーを更新しています。
    # repo id                               repo の名前
    # dvd-AppStream                         Red Hat Enterprise Linux 8 - AppStream
    # dvd-BaseOS                            Red Hat Enterprise Linux 8 - BaseOS
    # rhel-8-for-x86_64-appstream-rpms      Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
    # rhel-8-for-x86_64-baseos-rpms         Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)

# キャッシュクリア (必須?)
dnf clean all

# dvd-* のリポジトリのみを有効にしてインストール
dnf install httpd --disablerepo="*" --enablerepo="dvd-*"
```

### 補足

必要に応じて実施
```sh
# DVDを起動時に自動マウントするように設定
cat << __EOF__ >> /etc/fstab
/dev/cdrom /mnt/cdrom iso9660 defaults 0 0
__EOF__

# 既存のリポジトリを無効化 (dnf install 時に--disablerepo="*"が不要になる)
cd /etc/yum.repos.d/
cp redhat.repo redhat.repo.bk
sed -i 's/enabled = .*$/enabled = 0/g' redhat.repo
```

## オンラインのリポジトリを複製

[reposync(1) - Linux マニュアルページ](https://man7.org/linux/man-pages/man1/reposync.1.html)

以下のような配置にしたい

```text
/var/www/repo
+---almalinux8
|   +---appstream
|   |   +---Packages
|   |   +---mirrorlist
|   |   +---repodata
|   +---baseos/
|   |   +---Packages
|   |   +---mirrorlist
|   |   +---repodata
|   +---extras/
|       +---Packages
|       +---mirrorlist
|       +---repodata
+---redhat8
|   +---appstream
|   |   +---Packages
|   |   +---repodata
|   +---rhel-8-for-x86_64-baseos-rpms
|   |   +---Packages
|   |   +---repodata
```

### 複製するリポジトリを確認

- 通常のリポジトリは /etc/yum.repos.d/ 配下に設定ファイルがあるので、これを確認。
- RHELの場合、/etc/yum.repos.d/redhat.repo
- ebnabledとなっているものが有効

```sh
cat /etc/yum.repos.d/redhat.repo | grep 'enabled = 1' -4

    # 実行結果
    #
    # [rhel-8-for-x86_64-appstream-rpms]  ★これがリポジトリ名
    # name = Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
    # baseurl = https://cdn.redhat.com/content/dist/rhel8/$releasever/x86_64/appstream/os
    # enabled = 1
    # gpgcheck = 1
    # gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
    # sslverify = 1
    # sslcacert = /etc/rhsm/ca/redhat-uep.pem
    # --
    #
    # [rhel-8-for-x86_64-baseos-rpms]
    # name = Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)
    # baseurl = https://cdn.redhat.com/content/dist/rhel8/$releasever/x86_64/baseos/os
    # enabled = 1
    # gpgcheck = 1
    # gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
    # sslverify = 1
    # sslcacert = /etc/rhsm/ca/redhat-uep.pem
```

```sh
reposync -p /var/www/repo/almalinux8 --repo=baseos --repo=appstream --repo=extras --download-metadata
reposync -p /var/www/repo/redhat8 --repo=rhel-8-for-x86_64-appstream-rpms --repo=rhel-8-for-x86_64-baseos-rpms  --download-metadata
```
### リポジトリファイルの作成

/etc/yum.repos.d/redhat8.x.repo
```
[rhel-8-for-x86_64-baseos-rpms]
name = Red Hat Enterprise Linux 8 for x86_64 - BaseOS (RPMs)
baseurl = http://10.30.0.102/redhat8.x/baseos
enabled = 1
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release

[rhel-8-for-x86_64-appstream-rpms]
name = Red Hat Enterprise Linux 8 for x86_64 - AppStream (RPMs)
baseurl = http://10.30.0.102/redhat8.x/appstream/
enabled = 1
gpgcheck = 1
gpgkey = file:///etc/pki/rpm-gpg/RPM-GPG-KEY-redhat-release
```

/etc/yum.repos.d/almalinux8.repo
```
[baseos]
name=AlmaLinux $releasever - BaseOS
baseurl = http://10.30.0.102/almalinux8/baseos
# mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/baseos
# baseurl=https://repo.almalinux.org/almalinux/$releasever/BaseOS/$basearch/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[appstream]
name=AlmaLinux $releasever - AppStream
baseurl = http://10.30.0.102/almalinux8/appstream
# mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/appstream
# baseurl=https://repo.almalinux.org/almalinux/$releasever/AppStream/$basearch/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux

[extras]
name=AlmaLinux $releasever - Extras
baseurl = http://10.30.0.102/almalinux8/extras
# mirrorlist=https://mirrors.almalinux.org/mirrorlist/$releasever/extras
# baseurl=https://repo.almalinux.org/almalinux/$releasever/extras/$basearch/os/
enabled=1
gpgcheck=1
countme=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
```

## SELinuxの解除(NFS利用時)

## 参考

- [CentOS 8 : DNF/Yum リポジトリのミラーを構成 : Server World](https://www.server-world.info/query?os=CentOS_8&p=localrepo)

