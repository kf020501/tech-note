# Disk & Partition

## ディスク追加 ～ ファイルシステム作成

ESXi上のRHEL8にディスクを追加し、ファイルシステム作成までやってみる。

### ディスク新規追加後の確認


`lsblk`
```text
[root@redhat8 ~]# lsblk
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda             8:0    0   16G  0 disk
├─sda1          8:1    0  600M  0 part /boot/efi
├─sda2          8:2    0    1G  0 part /boot
└─sda3          8:3    0 14.4G  0 part
  ├─rhel-root 253:0    0 12.8G  0 lvm  /
  └─rhel-swap 253:1    0  1.6G  0 lvm  [SWAP]
sdb             8:16   0   16G  0 disk          ★ sdb が追加された
sr0            11:0    1 1024M  0 rom
[root@redhat8 ~]#
```
`parted -l`
```text
[root@redhat8 ~]# parted -l
モデル: VMware Virtual disk (scsi)
ディスク /dev/sda: 17.2GB
セクタサイズ (論理/物理): 512B/512B
パーティションテーブル: gpt
ディスクフラグ:

番号  開始    終了    サイズ  ファイルシステム  名前                  フラグ
 1    1049kB  630MB   629MB   fat32             EFI System Partition  boot, esp
 2    630MB   1704MB  1074MB  xfs
 3    1704MB  17.2GB  15.5GB                                          lvm


エラー: /dev/sdb: ディスクラベルが認識できません。
モデル: VMware Virtual disk (scsi)
ディスク /dev/sdb: 17.2GB
セクタサイズ (論理/物理): 512B/512B
パーティションテーブル: unknown
ディスクフラグ:

[root@redhat8 ~]#
```
`df -h` 
```text
[root@redhat8 ~]# df -h
ファイルシス          サイズ  使用  残り 使用% マウント位置
devtmpfs                386M     0  386M    0% /dev
tmpfs                   405M     0  405M    0% /dev/shm
tmpfs                   405M  5.7M  399M    2% /run
tmpfs                   405M     0  405M    0% /sys/fs/cgroup
/dev/mapper/rhel-root    13G  2.4G   11G   19% /
/dev/sda2              1014M  274M  741M   27% /boot
/dev/sda1               599M  5.8M  594M    1% /boot/efi
tmpfs                    81M     0   81M    0% /run/user/1000  ★ここにはまだsdbが表示されない
[root@redhat8 ~]#
```

### パーティションの作成(parted)

fdiskコマンド と partedコマンド どちらがいいのか？

- fdisk はMBRのみ(GPTを扱えない) 最後に決定するまで変更は実行されない
- parted はGTPも扱える サブコマンド実行時点で変更が実行される。

今回はpartedで実施

```sh 
parted /dev/sdb       # partedに入る
(parted) mklabel gpt  # 
(parted) print        # 確認 pでも可
(parted) mkpart       # パーティション/ファイルシステム作成
    パーティションの名前?  []?
    ファイルシステムの種類?  [ext2]? xfs
    開始? 0%
    終了? 100%
(parted) print        # 確認 pでも可
(parted) q            # 抜ける
```
実行例
```text
[root@redhat8 ~]# parted /dev/sdb
GNU Parted 3.2
/dev/sdb を使用
GNU Parted へようこそ！ コマンド一覧を見るには 'help' と入力してください。
(parted) mklabel gpt
(parted) print
モデル: VMware Virtual disk (scsi)
ディスク /dev/sdb: 17.2GB
セクタサイズ (論理/物理): 512B/512B
パーティションテーブル: gpt     ★ GTPになっている
ディスクフラグ:

番号  開始  終了  サイズ  ファイルシステム  名前  フラグ

(parted) mkpart
パーティションの名前?  []?
ファイルシステムの種類?  [ext2]? xfs
開始? 0%
終了? 100%
(parted) p
モデル: VMware Virtual disk (scsi)
ディスク /dev/sdb: 17.2GB
セクタサイズ (論理/物理): 512B/512B
パーティションテーブル: gpt
ディスクフラグ:

番号  開始    終了    サイズ  ファイルシステム  名前  フラグ
 1    1049kB  17.2GB  17.2GB  xfs

(parted) quit
通知: 必要であれば /etc/fstab を更新するのを忘れないようにしてください。

[root@redhat8 ~]#
```
確認    
lsblk
```text
[root@redhat8 ~]# lsblk
NAME          MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
sda             8:0    0   16G  0 disk
├─sda1          8:1    0  600M  0 part /boot/efi
├─sda2          8:2    0    1G  0 part /boot
└─sda3          8:3    0 14.4G  0 part
  ├─rhel-root 253:0    0 12.8G  0 lvm  /
  └─rhel-swap 253:1    0  1.6G  0 lvm  [SWAP]
sdb             8:16   0   16G  0 disk
└─sdb1          8:17   0   16G  0 part    ★ 追加されている
sr0            11:0    1 1024M  0 rom
[root@redhat8 ~]#
```
parted -l
```text
[root@redhat8 ~]# parted -l
モデル: VMware Virtual disk (scsi)
ディスク /dev/sda: 17.2GB
セクタサイズ (論理/物理): 512B/512B
パーティションテーブル: gpt
ディスクフラグ:

番号  開始    終了    サイズ  ファイルシステム  名前                  フラグ
 1    1049kB  630MB   629MB   fat32             EFI System Partition  boot, esp
 2    630MB   1704MB  1074MB  xfs
 3    1704MB  17.2GB  15.5GB                                          lvm

★ 追加されている

モデル: VMware Virtual disk (scsi)
ディスク /dev/sdb: 17.2GB
セクタサイズ (論理/物理): 512B/512B
パーティションテーブル: gpt
ディスクフラグ:

番号  開始    終了    サイズ  ファイルシステム  名前  フラグ
 1    1049kB  17.2GB  17.2GB


[root@redhat8 ~]#
```
df -h
```text
[root@redhat8 ~]# df -h
ファイルシス          サイズ  使用  残り 使用% マウント位置
devtmpfs                386M     0  386M    0% /dev
tmpfs                   405M     0  405M    0% /dev/shm
tmpfs                   405M  5.8M  399M    2% /run
tmpfs                   405M     0  405M    0% /sys/fs/cgroup
/dev/mapper/rhel-root    13G  2.4G   11G   19% /
/dev/sda2              1014M  274M  741M   27% /boot
/dev/sda1               599M  5.8M  594M    1% /boot/efi
tmpfs                    81M     0   81M    0% /run/user/1000   ★ ここにはまだ /dev/sdbはいない(マウントしていないので)
[root@redhat8 ~]#
```

### ファイルシステム作成

```sh
mkfs.xfs /dev/sdb1

mkdir /mnt/testpart
mount /dev/sdb1 /mnt/testpart/

# ラベルに名前を付けていれば以下でも可
# mount /dev/disk/by-partlabel/xxx /mnt/testpart/
```

RHELのマニュアルには以下のように書いてある

> XFS は、デフォルトでディスク上のロケーションを反映するために inode を割り当てます。
> 
> ただし、32 ビットのユーザー空間アプリケーションには、inode 番号が 232 を超える inode との互換性がないため、   
> XFS はディスクロケーションに inode をすべて割り当て、32 ビットの inode 番号になります。   
> これにより、非常に大きなファイルシステム（2 テラバイトより大きい）のパフォーマンスが低下する可能性があります。    
> 
> これに対処するには、inode64 マウントオプションを使用します。    
> このオプションを使用すると、ファイルシステム全体で inode とデータを割り当てるように XFS を設定します。    
> これにより、パフォーマンスを向上できます。    
> `mount -o inode64 /dev/device /mount/point`

[8.2. XFS ファイルシステムのマウント Red Hat Enterprise Linux 6 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/6/html/storage_administration_guide/xfsmounting)


### 自動マウント設定

```sh
# UUIDの確認
blkid

# fstabの編集
vi /etc/fstab

    # 記載例
    # UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /mnt xfs defaults 1 2

# マウント
mount -a

# 確認
df -h
```

### 補足: /etc/fstabのパラメータについて

| 数字の位置      | 値  | 意味                                                                                               |
| --------------- | --- | -------------------------------------------------------------------------------------------------- |
| 5番目（ダンプ） | 0   | ファイルシステムはダンプされません。                                                               |
|                 | 1   | ファイルシステムがダンプされます。                                                                 |
| 6番目（fsck）   | 0   | 起動時にファイルシステムはチェックされません。                                                     |
|                 | 1   | 起動時に最初にチェックされるファイルシステム（主にルートファイルシステム用）。                     |
|                 | 2   | 起動時にルートファイルシステムの後でチェックされるファイルシステム（非ルートファイルシステム用）。 |

----------

Dockerで使っていたVMのUbuntu Server 20.04のディスクを拡張する。

本当は一回100%になってしまい、上手く動かなくなってしまった。(apt使えなくなった。。)
復旧を試みたが上手くいかなかったため、スナップショットでタイムスリップ。

事前にESXi側でvmdkを拡張しておく。

## df -T でファイルシステムのタイプを確認

```text
user@docker:~$ sudo su -
[sudo] user のパスワード:
root@docker:~#
root@docker:~# df -h
Filesystem                         Size  Used Avail Use% Mounted on
udev                               951M     0  951M   0% /dev
tmpfs                              199M  1.5M  198M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   20G  9.4G  9.2G  51% /
tmpfs                              994M     0  994M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
tmpfs                              994M     0  994M   0% /sys/fs/cgroup
/dev/sda2                          976M  104M  806M  12% /boot
/dev/loop1                          56M   56M     0 100% /snap/core18/1988
/dev/loop2                          33M   33M     0 100% /snap/snapd/11107
/dev/loop0                          56M   56M     0 100% /snap/core18/1944
/dev/loop3                          70M   70M     0 100% /snap/lxd/19188
/dev/loop4                          32M   32M     0 100% /snap/snapd/10707
tmpfs                              199M     0  199M   0% /run/user/1000
overlay                             20G  9.4G  9.2G  51% /var/lib/docker/overlay2/xxxxxxxxx/merged
overlay                             20G  9.4G  9.2G  51% /var/lib/docker/overlay2/xxxxxxxxx/merged
overlay                             20G  9.4G  9.2G  51% /var/lib/docker/overlay2/xxxxxxxxx/merged
overlay                             20G  9.4G  9.2G  51% /var/lib/docker/overlay2/xxxxxxxxx/merged
shm                                 64M     0   64M   0% /var/lib/docker/containers/xxxxxxxxx/mounts/shm
shm                                 64M     0   64M   0% /var/lib/docker/containers/xxxxxxxxx/mounts/shm
shm                                 64M     0   64M   0% /var/lib/docker/containers/xxxxxxxxx/mounts/shm
/dev/loop5                          33M   33M     0 100% /snap/snapd/13640
/dev/loop6                          56M   56M     0 100% /snap/core18/2253
root@docker:~#
root@docker:~# lsblk
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
loop1                       7:1    0 55.5M  1 loop /snap/core18/1988
loop2                       7:2    0 32.3M  1 loop /snap/snapd/11107
loop3                       7:3    0 69.9M  1 loop /snap/lxd/19188
loop5                       7:5    0 32.5M  1 loop /snap/snapd/13640
loop6                       7:6    0 55.5M  1 loop /snap/core18/2253
sda                         8:0    0   40G  0 disk
├─sda1                      8:1    0    1M  0 part
├─sda2                      8:2    0    1G  0 part /boot
└─sda3                      8:3    0   39G  0 part
  └─ubuntu--vg-ubuntu--lv 253:0    0   20G  0 lvm  /
sr0                        11:0    1 1024M  0 rom
root@docker:~#
root@docker:~#
root@docker:~# lvextend -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
  Size of logical volume ubuntu-vg/ubuntu-lv changed from 20.00 GiB (5120 extents) to <39.00 GiB (9983 extents).
  Logical volume ubuntu-vg/ubuntu-lv successfully resized.
root@docker:~#
root@docker:~#
root@docker:~# df -h
Filesystem                         Size  Used Avail Use% Mounted on
udev                               951M     0  951M   0% /dev
tmpfs                              199M  1.5M  198M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   20G  9.6G  9.1G  52% /
tmpfs                              994M     0  994M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
tmpfs                              994M     0  994M   0% /sys/fs/cgroup
/dev/sda2                          976M  104M  806M  12% /boot
/dev/loop1                          56M   56M     0 100% /snap/core18/1988
/dev/loop2                          33M   33M     0 100% /snap/snapd/11107
/dev/loop3                          70M   70M     0 100% /snap/lxd/19188
tmpfs                              199M     0  199M   0% /run/user/1000
overlay                             20G  9.6G  9.1G  52% /var/lib/docker/overlay2/431f822ec3bfc8bcf6fb6c81f65a9260ac5f1966cef4a4e88dc54f6cd657c5cb/merged
overlay                             20G  9.6G  9.1G  52% /var/lib/docker/overlay2/b56e3e12525c0cdb2467cf032502df4fde44acebceba22a16c3aad22619fb309/merged
overlay                             20G  9.6G  9.1G  52% /var/lib/docker/overlay2/4e3357db982e86bf3260f6008a8af44bb07dcc95f7e84afdc5c093b937e31a77/merged
overlay                             20G  9.6G  9.1G  52% /var/lib/docker/overlay2/4817731b8e2ad4927c1fcb669267632b6bac0e0df7389e6e60737ba9999e1f1d/merged
shm                                 64M     0   64M   0% /var/lib/docker/containers/9a6fe434b2c88233da631d7490b3c6a859b6eba11475ebc1091b4936dbc80676/mounts/shm
shm                                 64M     0   64M   0% /var/lib/docker/containers/66a5a225065b27d75e98b1f2e7f2da011e734e9833c98a80d0f23467f2244a4d/mounts/shm
shm                                 64M     0   64M   0% /var/lib/docker/containers/6489f7d8373c69cecd36b3e21eda96e2aa304ac960708d9b54c542394b5e28d9/mounts/shm
/dev/loop5                          33M   33M     0 100% /snap/snapd/13640
/dev/loop6                          56M   56M     0 100% /snap/core18/2253
/dev/loop0                          62M   62M     0 100% /snap/core20/1242
/dev/loop4                          68M   68M     0 100% /snap/lxd/21835
root@docker:~# resize2fs /dev/mapper/ubuntu--vg-ubuntu--lv
resize2fs 1.45.5 (07-Jan-2020)
Filesystem at /dev/mapper/ubuntu--vg-ubuntu--lv is mounted on /; on-line resizing required
old_desc_blocks = 3, new_desc_blocks = 5
The filesystem on /dev/mapper/ubuntu--vg-ubuntu--lv is now 10222592 (4k) blocks long.

root@docker:~# df -h
Filesystem                         Size  Used Avail Use% Mounted on
udev                               951M     0  951M   0% /dev
tmpfs                              199M  1.5M  198M   1% /run
/dev/mapper/ubuntu--vg-ubuntu--lv   39G  9.6G   27G  27% /
tmpfs                              994M     0  994M   0% /dev/shm
tmpfs                              5.0M     0  5.0M   0% /run/lock
tmpfs                              994M     0  994M   0% /sys/fs/cgroup
/dev/sda2                          976M  104M  806M  12% /boot
/dev/loop1                          56M   56M     0 100% /snap/core18/1988
/dev/loop2                          33M   33M     0 100% /snap/snapd/11107
/dev/loop3                          70M   70M     0 100% /snap/lxd/19188
tmpfs                              199M     0  199M   0% /run/user/1000
overlay                             39G  9.6G   27G  27% /var/lib/docker/overlay2/431f822ec3bfc8bcf6fb6c81f65a9260ac5f1966cef4a4e88dc54f6cd657c5cb/merged
overlay                             39G  9.6G   27G  27% /var/lib/docker/overlay2/b56e3e12525c0cdb2467cf032502df4fde44acebceba22a16c3aad22619fb309/merged
overlay                             39G  9.6G   27G  27% /var/lib/docker/overlay2/4e3357db982e86bf3260f6008a8af44bb07dcc95f7e84afdc5c093b937e31a77/merged
overlay                             39G  9.6G   27G  27% /var/lib/docker/overlay2/4817731b8e2ad4927c1fcb669267632b6bac0e0df7389e6e60737ba9999e1f1d/merged
shm                                 64M     0   64M   0% /var/lib/docker/containers/9a6fe434b2c88233da631d7490b3c6a859b6eba11475ebc1091b4936dbc80676/mounts/shm
shm                                 64M     0   64M   0% /var/lib/docker/containers/66a5a225065b27d75e98b1f2e7f2da011e734e9833c98a80d0f23467f2244a4d/mounts/shm
shm                                 64M     0   64M   0% /var/lib/docker/containers/6489f7d8373c69cecd36b3e21eda96e2aa304ac960708d9b54c542394b5e28d9/mounts/shm
/dev/loop5                          33M   33M     0 100% /snap/snapd/13640
/dev/loop6                          56M   56M     0 100% /snap/core18/2253
/dev/loop0                          62M   62M     0 100% /snap/core20/1242
/dev/loop4                          68M   68M     0 100% /snap/lxd/21835
root@docker:~# shutdown now
```

## 参考

[LVM を空き容量いっぱいまで拡張する | ytyng.com](https://www.ytyng.com/blog/lvm-partition-extend-full-remain-volume/)

[パーティションとか、ファイルシステムとか+ファイル管理基礎 · GitHub](https://gist.github.com/261shimizu/c5ab9cd712ef15d7a6223253e0eaed8a)

[IT pass HikiWiki - [TEBIKI]Linux に新しくディスクを追加する方法](https://itpass.scitec.kobe-u.ac.jp/hiki/hiki.cgi?%5BTEBIKI%5DLinux+%E3%81%AB%E6%96%B0%E3%81%97%E3%81%8F%E3%83%87%E3%82%A3%E3%82%B9%E3%82%AF%E3%82%92%E8%BF%BD%E5%8A%A0%E3%81%99%E3%82%8B%E6%96%B9%E6%B3%95)

## ディスク初期化

### wipefsコマンド

ファイルシステム,RAID,パーティションテーブルの情報を削除するコマンド。    
ファイルシステムそのものや、ファイルシステムのデータは消去しない模様。

/dev/sdb を初期化する例   
各種確認を行い、`wipefs -a /dev/sdb` で初期化する。
```sh
lsblk | grep sdb  # 削除前 確認(1)

    sdb      8:16   0 698.7G  0 disk
    └─sdb1   8:17   0 698.7G  0 part  ★ sdb1 が作成されている

fdisk -l /dev/sdb # 削除前 確認(2)

    ディスク /dev/sdb: 698.65 GiB, 750156374016 バイト, 1465149168 セクタ
    Disk model: WDC WD7500BPVT-1
    単位: セクタ (1 * 512 = 512 バイト)
    セクタサイズ (論理 / 物理): 512 バイト / 4096 バイト
    I/O サイズ (最小 / 推奨): 4096 バイト / 4096 バイト
    ディスクラベルのタイプ: gpt
    ディスク識別子: 36242FE2-94C8-465B-9E28-525034D41C29

    デバイス   開始位置   最後から     セクタ サイズ タイプ
    /dev/sdb1      2048 1465145344 1465143297 698.7G VMware VMFS

wipefs -a /dev/sdb  # 初期化 なお、wipefs -an /dev/sdb でテスト実行

    /dev/sdb: オフセット 0x00000200 にある 8 バイト (gpt) を消去しました: 45 46 49 20 50 41 52 54
    /dev/sdb: オフセット 0xaea8cdde00 にある 8 バイト (gpt) を消去しました: 45 46 49 20 50 41 52 54
    /dev/sdb: オフセット 0x000001fe にある 2 バイト (PMBR) を消去しました: 55 aa
    /dev/sdb: ioctl() を呼び出してパーティション情報を再読み込みします: 成功です

lsblk | grep sdb  # 削除後 確認(1)

    sdb      8:16   0 698.7G  0 disk ★ sdb1 が削除されている

 fdisk -l /dev/sdb  # 削除後 確認(2)

    ディスク /dev/sdb: 698.65 GiB, 750156374016 バイト, 1465149168 セクタ
    Disk model: WDC WD7500BPVT-1
    単位: セクタ (1 * 512 = 512 バイト)
    セクタサイズ (論理 / 物理): 512 バイト / 4096 バイト
    I/O サイズ (最小 / 推奨): 4096 バイト / 4096 バイト

    # "ディスクラベルのタイプ: gpt" 以下、パーティション情報がが削除されている
```
### prob: 再利用HDDのFS種別が消えない

過去VMFS6で使用していたディスクを再利用したときエラーが出たのでメモ   
wipefsしても、過去のFS情報がどこかに残っているのか、エラーが出る。    
wipefs → partedで再作成(xfs) してから以下を実施したところ、、、
```text
root@ubuntu20:~# mkfs.xfs/dev/sdb1
    --> 控え忘れたが、-fをつけろと怒られた
root@ubuntu20:~# mkfs.xfs -f /dev/sdb1
    --> ここでは成功するが、、、
root@ubuntu20:~# mount /dev/sdb1 /mnt/temp/
mount: /mnt/temp: 未知のファイルシステムタイプ 'VMFS_volume_member' です.
    --> また怒られる
mount -t xfs /dev/sdb1 /mnt/temp/ 
    --> タイプ指定で成功
```
正しい解決策は不明。(まぁ上記でもいいが...)   
ddコマンドなどで消す方法もあるみたい。
> ファイルシステムのシグネーチャは、冒頭にあることが多いので、先頭だけクリアするという方法もあります。    
> [ALL about Linux: ファイルシステムの痕跡（メタデータ）をクリアする方法あれこれ（wipefsほか）](https://luna2-linux.blogspot.com/2015/04/wipefs.html)
```
dd if=/dev/zero of=/dev/sda10 bs=1M count=1
```

## HDD 物理情報確認
シリアルなど確認できる
```sh
sudo hdparm -i /dev/sda
sudo hdparm -I /dev/sdb # こちらのほうが詳細
```


## パーティションのサイズ変更

[3.5.2. parted でパーティションのサイズ変更 Red Hat Enterprise Linux 8 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/8/html/managing_storage_devices/proc_resizing-a-partition-with-parted_assembly_resizing-a-partition)

[8.4. XFS ファイルシステムのサイズの拡大 Red Hat Enterprise Linux 6 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/6/html/storage_administration_guide/xfsgrow)

## LVMのサイズ変更

VMのディスク拡張などしたとき向け？
パーティションまでは拡張しておく。
以下はそれ以降の作業

### 物理ボリューム(PV)拡張
```sh
pvdisplay           # PV確認 作業前
pvresize /dev/sda3  # PVリサイズ
pvdisplay           # PV確認 作業後
```
実行例
```text
[root@redhat8 ~]# pvdisplay     ★作業前 確認
  --- Physical volume ---
  PV Name               /dev/sda3   ★ 確認
  VG Name               rhel_rhel8
  PV Size               14.41 GiB / not usable 2.00 MiB     ★ 現在値
  Allocatable           yes (but full)
  PE Size               4.00 MiB
  Total PE              3689
  Free PE               0
  Allocated PE          3689
  PV UUID               Rv8xt1-nhz4-jvdf-Ijyv-BVt5-mRhE-whHspz
   
[root@redhat8 ~]# 
[root@redhat8 ~]# pvresize /dev/sda3    ★ リサイズ
  Physical volume "/dev/sda3" changed
  1 physical volume(s) resized or updated / 0 physical volume(s) not resized
[root@redhat8 ~]# 
[root@redhat8 ~]# pvdisplay     ★作業後 確認
  --- Physical volume ---
  PV Name               /dev/sda3
  VG Name               rhel_rhel8
  PV Size               38.41 GiB / not usable 1.98 MiB      ★ 現在値
  Allocatable           yes 
  PE Size               4.00 MiB
  Total PE              9833
  Free PE               6144
  Allocated PE          3689
  PV UUID               Rv8xt1-nhz4-jvdf-Ijyv-BVt5-mRhE-whHspz
   
[root@redhat8 ~]# 
```
### ボリュームグループ(VG)拡張 → PV拡張時点で増えている

```sh
vgdisplay   VG確認
``` 
実行例
```text
[root@redhat8 ~]# vgdisplay 
  --- Volume group ---
  VG Name               rhel_rhel8
  System ID             
  Format                lvm2
  Metadata Areas        1
  Metadata Sequence No  4
  VG Access             read/write
  VG Status             resizable
  MAX LV                0
  Cur LV                2
  Open LV               2
  Max PV                0
  Cur PV                1
  Act PV                1
  VG Size               38.41 GiB   ★ 増えてる
  PE Size               4.00 MiB
  Total PE              9833
  Alloc PE / Size       3689 / 14.41 GiB
  Free  PE / Size       6144 / 24.00 GiB
  VG UUID               q0zhv2-Gt7g-LCyL-L5oa-NzWo-bbj7-EijpMT
   
[root@redhat8 ~]# 
```
### 論理ボリューム(LV) 拡張

[Linuxのディスク拡張手順 (KVM, LVM, EXT4)](https://endy-tech.hatenablog.jp/entry/extend_linux_disks#LV%E6%8B%A1%E5%BC%B5--File-System%E6%8B%A1%E5%BC%B5)

```sh
lvdisplay   # LV確認
lvextend --test --resizefs --extents +100%FREE /dev/rhel_rhel8/root # テスト実行
            # --test        テストモードで実行
            # --resizefs    ファイルシステムもリサイズ(ext2, ext3, ext4, xfs はOK)
            # --extents     拡張後のサイズを指定    +100%FREE で空き容量を全て割り当て
lvextend --resizefs --extents +100%FREE /dev/rhel_rhel8/root        # 拡張を実行
lvdisplay   # LV確認
``` 
実行例
```text
[root@redhat8 ~]# lvdisplay     ★ 確認
  --- Logical volume ---
  LV Path                /dev/rhel_rhel8/swap
  LV Name                swap
  VG Name                rhel_rhel8
  LV UUID                5HjsNY-CR43-HczS-b3b9-m0hg-0HZ6-q47xKo
  LV Write Access        read/write
  LV Creation host, time rhel8, 2021-04-11 02:19:26 +0900
  LV Status              available
  # open                 2
  LV Size                1.60 GiB
  Current LE             410
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:1
   
  --- Logical volume ---
  LV Path                /dev/rhel_rhel8/root   ★ これを指定する
  LV Name                root
  VG Name                rhel_rhel8
  LV UUID                k9bPnA-ndUy-dbwY-aBFp-DpOW-RlxY-ASLG2w
  LV Write Access        read/write
  LV Creation host, time rhel8, 2021-04-11 02:19:26 +0900
  LV Status              available
  # open                 1
  LV Size                <12.81 GiB     ★ 現在サイズ確認
  Current LE             3279
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
   
[root@redhat8 ~]# 
[root@redhat8 ~]# lvextend --test --resizefs --extents +100%FREE /dev/rhel_rhel8/root   ★ テスト実行
  TEST MODE: Metadata will NOT be updated and volumes will not be (de)activated.
  Size of logical volume rhel_rhel8/root changed from <12.81 GiB (3279 extents) to <36.81 GiB (9423 extents).
  Logical volume rhel_rhel8/root successfully resized.
[root@redhat8 ~]# 
[root@redhat8 ~]# lvextend --resizefs --extents +100%FREE /dev/rhel_rhel8/root  ★ 拡張を実行
  Size of logical volume rhel_rhel8/root changed from <12.81 GiB (3279 extents) to <36.81 GiB (9423 extents).
  Logical volume rhel_rhel8/root successfully resized.
meta-data=/dev/mapper/rhel_rhel8-root isize=512    agcount=4, agsize=839424 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=1, sparse=1, rmapbt=0
         =                       reflink=1    bigtime=0 inobtcount=0
data     =                       bsize=4096   blocks=3357696, imaxpct=25
         =                       sunit=0      swidth=0 blks
naming   =version 2              bsize=4096   ascii-ci=0, ftype=1
log      =internal log           bsize=4096   blocks=2560, version=2
         =                       sectsz=512   sunit=0 blks, lazy-count=1
realtime =none                   extsz=4096   blocks=0, rtextents=0
data blocks changed from 3357696 to 9649152
[root@redhat8 ~]# 
[root@redhat8 ~]# lvdisplay     ★確認
  --- Logical volume ---
  LV Path                /dev/rhel_rhel8/swap
  LV Name                swap
  VG Name                rhel_rhel8
  LV UUID                5HjsNY-CR43-HczS-b3b9-m0hg-0HZ6-q47xKo
  LV Write Access        read/write
  LV Creation host, time rhel8, 2021-04-11 02:19:26 +0900
  LV Status              available
  # open                 2
  LV Size                1.60 GiB
  Current LE             410
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:1
   
  --- Logical volume ---
  LV Path                /dev/rhel_rhel8/root
  LV Name                root
  VG Name                rhel_rhel8
  LV UUID                k9bPnA-ndUy-dbwY-aBFp-DpOW-RlxY-ASLG2w
  LV Write Access        read/write
  LV Creation host, time rhel8, 2021-04-11 02:19:26 +0900
  LV Status              available
  # open                 1
  LV Size                <36.81 GiB     ★ 拡張されている
  Current LE             9423
  Segments               1
  Allocation             inherit
  Read ahead sectors     auto
  - currently set to     8192
  Block device           253:0
   
[root@redhat8 ~]# 
[root@redhat8 ~]# df -h     ★ dfでも確認
ファイルシス                   サイズ  使用  残り 使用% マウント位置
devtmpfs                         1.9G     0  1.9G    0% /dev
tmpfs                            1.9G     0  1.9G    0% /dev/shm
tmpfs                            1.9G  8.8M  1.9G    1% /run
tmpfs                            1.9G     0  1.9G    0% /sys/fs/cgroup
/dev/mapper/rhel_rhel8-root       37G  4.4G   33G   12% /   ★ 増えている
/dev/sda2                       1014M  318M  697M   32% /boot
/dev/sda1                        599M  5.9M  594M    1% /boot/efi
10.30.0.10:/mnt/tank/nfs.esxi     1.0T  200G  824G   20% /mnt/nfs.esxi
10.30.0.10:/mnt/tank/multi.true   1.0T  100G  924G   10% /mnt/multi.true
192.168.10.110:/export/vault      2.0T  400G  1.6T   20% /mnt/vault
//192.168.10.110/data             2.0T  400G  1.6T   20% /mnt/smb.data
//192.168.10.110/share            500G  100G  400G   20% /mnt/share
tmpfs                            374M     0  374M    0% /run/user/1001
[root@redhat8 ~]# 
```