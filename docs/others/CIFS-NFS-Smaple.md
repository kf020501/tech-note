---
title: "CIFSおよびNFSのログサンプル"
tags: ["memo"]
date: 2022-01-27
weight: 100
draft: false
---

## はじめに

CIFSおよびNFSの、マウントやファイル読み書きなどのログサンプルを作成した。  
障害発生時のログと比較することで、障害の切り分けに役立てる。

採取した各種ログはソートやフィルタがしやすいように別途Excelにまとめ、
本PDFにはログ採取時の構成や設定等を記載する。   

ファイルサーバはQunatum社のDXi V5000 Community Editionを使用する(仮想アプライアンス)    
DXiシリーズはCentOSベースの製品のため、DXiシリーズ独自のweb管理画面で設定後、    
内部的にどのような設定値になっているか確認を行う。  

※ web管理画面での操作方法は本資料の趣旨と異なるため割愛     

[DXi-Series Backup Appliances](https://www.quantum.com/en/products/backup-appliances/)

また、ローカルのNTPサーバを用い、ログの時間ずれを極力抑える構成とした。


## CIFS

### 構成

<!-- <img src=".\cifs-env.jpg" style="zoom: 50%; float: left;" /> -->

### 採取するログ

今回はサーバ側でのみログ採取を行う。

**ログレベル3までのsambaログ**

サーバ側で、sambaログレベルを3に設定することで、    
`/var/log/samba/log.smbd`に出力されるログの詳細レベルを上げる。
(出力個所は環境によって異なる)

一般的なLinuxであればsamba設定ファイル`/etc/samba/smb.conf`の `debug level = n` を書き換えるが、    
DXiシリーズにはログレベル変更のコマンドが用意されているため、今回はそれを利用する。       

補足: DXiシリーズでは、"cliadmin" ユーザにsshログインしてコマンドを実行する
```sh
syscli --get smbsetting --dbglevel      # 現在のsambaデバッグレベルを確認 初期値は0
syscli --set smbsetting --dbglevel 3    # sambaデバッグレベルを3に変更 作業完了後戻す
```

**パケットキャプチャ**

`tcpdump` コマンドでパケットキャプチャを採取する。     
検証完了後、Ctrl + C でキャプチャを終了する。     
構文: `tcpdump -i <キャプチャするインターフェイス名> -w <出力ファイル名> [追加条件]`  

```sh
tcpdump -i ens192:1 -w cifs-server.cap not port 22
```

### 検証内容(クライアントの操作)

```
1 共有を開く
     1-1 エクスプローラのアドレスバーに "\\10.30.0.73\test-cifs" を入力しEnter
     1-2 認証情報を入力しEnter(正しいユーザ名"testuser"、間違ったパスワード"hoge")
     1-3 認証情報を入力しEnter(正しいユーザ名"testuser"、正しいパスワード"P@ssw0rd")
2 ローカルの`sample.txt`をコピーし、共有フォルダに貼り付け
3 "sample.txt"を編集
     3-1 "sample.txt"をダブルクリックで開く(メモ帳)
     3-2 "hello" と書き込み保存
     3-3 メモ帳を閉じる
4 "sample.txt" をコピー
     4-1 "sample.txt"を右クリック
     4-2 "コピー"をクリック
     4-3 共有を右クリック
     4-4 "貼り付け"をクリック("sample - コピー.txt"が作成される)
5 "sample - コピー.txt"をリネーム
     5-1 "sample - コピー.txt"を左クリック(ファイル名が編集できる状態になる)
     5-2 "sample2.txt"にリネームしEnter
6 "sample2.txt"を削除
     6-1 "sample2.txt"を選択している状態でDeleteキーを押下
     6-2 "このファイルを完全に削除しますか？"に"はい"を回答
7 フォルダを作成
     7-1 共有を右クリックし、フォルダを新規作成("新しいフォルダ"が作成される)
     7-2 "新しいフォルダ"を"testfolder"にリネーム
8 フォルダ移動(存在しないフォルダ)
     8-1 エクスプローラのアドレスバーに "\\10.30.0.73\test-cifs\hoge" を入力しEnter
     8-2 "\\10.30.0.73\test-cifs\hoge にアクセスできません"にキャンセルを回答
9 フォルダ移動
     9-1 エクスプローラのアドレスバーに "\\10.30.0.73\test-cifs\testfolder" を入力しEnter
10 エクスプローラを「×」で閉じる
```


### 設定情報(サーバ)

事前にweb管理画面でCIFS共有の作成と、CIFSアクセス用ユーザー "testuser" の作成を行った。(web管理画面の操作方法は割愛)    
sshでログインし、以下の確認を行う。

- OSバージョン (`/etc/redhat-release` の確認)
- 共有ディレクトリ `/Q/shares/test-cifs` のパーミッション
- samba設定 (`/etc/samba/smb.conf` の確認)
- Linuxユーザおよびsambaユーザに登録された"testuser"の確認


OSバージョン、共有ディレクトリパーミッション
```
[ServiceLogin@dxi-v5000 ~]$ cat /etc/redhat-release
CentOS Linux release 7.9.2009 (Core)
[ServiceLogin@dxi-v5000 ~]$
[ServiceLogin@dxi-v5000 ~]$ ls -l /Q/shares/
total 0
drwxrwxrwx 2 root root 0 Jan 10 08:30 test-cifs
drwxrwxrwx 3 root root 0 Jan 23 03:26 test-nfs
[ServiceLogin@dxi-v5000 ~]$
```

/etc/samba/smb.conf
```
# Samba Local User Configuration
[global]
     server string = node-1 File Server
     workgroup = WORKGROUP
     security = user
     netbios name = NODE-1
     domain master = no
     local master = no
     dos filemode = yes
     name cache timeout = 0
     passdb backend = smbpasswd:/snfs/common/galaxy-config/nas/smbpasswd

# A hard way to turn off CUPS; the best way is to not compile CUPS in smbd.
     load printers = no
     printing = bsd
     printcap name = /dev/null
     disable spoolss = yes

# Disable the LPQ background process for clustered samba.
     smbd:backgroundqueue = false

# All additional parameters entered manually should be placed
# in include file to avoid being wiped out when smb.conf is regenerated.

include = /snfs/common/galaxy-config/nas/smb.conf.extra

# This file is optional; it may come from a patch Quantum sent to customers.
include = /snfs/common/galaxy-config/nas/smb.conf.patch

#############################################
#       SHARE CONFIGURATIONS FOLLOW!!!!!
#############################################

include = /etc/samba/smb.shares
```

以下3ファイルがincludeとなっているので追加で確認。
- /snfs/common/galaxy-config/nas/smb.conf.extra
- /snfs/common/galaxy-config/nas/smb.conf.patch --> 存在しなかった
- /etc/samba/smb.shares

/snfs/common/galaxy-config/nas/smb.conf.extra (smb.confにincludeされていたため確認)
```
##########################################################################
# To debug samba, set debug level to n > 0, say 10. Otherwise, reset to 0.
     debug level = 0
##########################################################################

     kernel oplocks = no
# By default, "oplocks" is set to true.
# You may want to disable this option for unreliable network environments.
# Run 'testparm -v -s' to verify the change.
     oplocks = yes
     change notify = no
     nt acl support = yes
     stat cache = no
     strict sync = yes
     client ldap sasl wrapping = plain
     max smbd processes = 100
     max log size = 0
     interfaces =  ens192:1
     client ntlmv2 auth = yes
     restrict anonymous = 2
     server signing = disabled
```

/etc/samba/smb.shares  (smb.confにincludeされていたため確認)
```
##########################################################
#       CIFS SHARE CONFIGURATION (node1 ALONE) !!!!!
##########################################################

[test-cifs]
volume = NODE-1-test-cifs
path = /shares/test-cifs
writeable = yes
browseable = yes
oplocks = yes
level2 oplocks = yes
create mask = 0777
directory mask = 0777
map readonly = yes
map archive = yes
map hidden = yes
map system = yes
store dos attributes = no
ea support = no
vfs objects = vfs_quantum_acl  vfs_quantum_ddup

#############################################
```
Linuxユーザ確認
```
[ServiceLogin@dxi-v5000 ~]$ cat /etc/passwd | grep testuser
testuser:x:1000:550::/home/testuser:/bin/false
[ServiceLogin@dxi-v5000 ~]$ cat /etc/group | grep 550
backup:x:550:
[ServiceLogin@dxi-v5000 ~]$
```

sambaユーザ確認 `pdbedit -L -v` 
```
[ServiceLogin@dxi-v5000 ~]$ sudo pdbedit -L -v
---------------
Unix username:        testuser
NT username:
Account Flags:        [U          ]
User SID:             S-1-5-21-532354722-4204859287-2794821787-3000
Primary Group SID:    S-1-5-21-532354722-4204859287-2794821787-513
Full Name:
Home Directory:       \\node-1\testuser
HomeDir Drive:
Logon Script:
Profile Path:         \\node-1\testuser\profile
Domain:               NODE-1
Account desc:
Workstations:
Munged dial:
Logon time:           0
Logoff time:          never
Kickoff time:         never
Password last set:    Mon, 10 Jan 2022 08:33:51 JST
Password can change:  Mon, 10 Jan 2022 08:33:51 JST
Password must change: never
Last bad password   : 0
Bad password count  : 0
Logon hours         : FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
[ServiceLogin@dxi-v5000 ~]$
```

### 設定情報(クライアント)

特になし。





## NFS

### 構成

<img src=".\nfs-env.jpg" style="zoom:50%;float: left;" />

### 採取するログ

今回はサーバ側でのみログ採取を行う。

**NFSログ**

サーバ側で、NFSログの出力を有効にする `rpcdebug` コマンドを実施する。      
(`/var/log/messages`にNFSログが出力されるようになる)    

**パケットキャプチャ**

`tcpdump` コマンドでパケットキャプチャを採取する。     
構文:  `tcpdump -i <キャプチャするインターフェイス名> -w <出力ファイル名> [追加条件]`  
検証完了後、Ctrl + C でキャプチャを終了する。

```sh
rpcdebug -m nfsd -s all  # rpcdebug 開始
tcpdump -i ens192:1 -w nfs-server.cap not port 22

     # この間 検証作業実施(クライアント側)
     # 終了したら Ctrl + C で tcpdumpコマンドを終了する

rpcdebug -m nfsd -c all  # rpcdebug 終了
```

補足: クライアントのNFSログ
`rpcdebug -m nfs -s all` で採取可能だが、今回は未実施。     
`rpcdebug -m nfs -c all ` で停止。


### 検証内容(クライアントの操作)

NFSマウント後に、ファイルの読み書きなど基本的なコマンドを実行する(rootユーザ)
```sh
mount -v /mnt/test-nfs   # マウント
mount | grep test-nfs    # マウント状態確認
df -h                    # ディスク容量確認

echo "hello" > /mnt/test-nfs/testdata.txt    # ファイル作成・書き込み
cat /mnt/test-nfs/testdata.txt               # ファイル読み込み
cp /mnt/test-nfs/testdata.txt /mnt/test-nfs/testdata-cp.txt   # ファイルコピー
mv /mnt/test-nfs/testdata.txt /mnt/test-nfs/testdata-mv.txt   # ファイル移動(名前変更)
rm -f /mnt/test-nfs/testdata-mv.txt          # ファイル削除

ls -l /mnt/test-nfs           # ディレクトリ確認
ls -l /mnt/test-nfs/hoge      # ディレクトリ確認(存在しないディレクトリ)

umount -v /mnt/test-nfs       # アンマウント
mount | grep test-nfs         # マウント状態確認
```

### 設定情報(サーバ)

事前にweb管理画面でNFS共有の作成を行った。(web管理画面の操作方法は割愛)    
sshでログインし、NFSサーバ側で以下の設定確認を行う。

- OSバージョン (`/etc/redhat-release`の確認)
- 共有ディレクトリ `/Q/shares/test-nfs` のパーミッション
- NFS設定 (`/etc/exports` の確認)

```
[ServiceLogin@dxi-v5000 ~]$ cat /etc/redhat-release
CentOS Linux release 7.9.2009 (Core)
[ServiceLogin@dxi-v5000 ~]$
[ServiceLogin@dxi-v5000 ~]$ ls -l /Q/shares/
total 0
drwxrwxrwx 2 root root 0 Jan 10 08:30 test-cifs
drwxrwxrwx 3 root root 0 Jan 23 03:26 test-nfs
[ServiceLogin@dxi-v5000 ~]$
[ServiceLogin@dxi-v5000 ~]$ cat /etc/exports
/Q/shares/test-nfs *(sync,rw,root_squash,anonuid=4294967294,anongid=4294967294,no_subtree_check,fsid=6971)
[ServiceLogin@dxi-v5000 ~]$
```

### 設定情報(クライアント)

事前に `nfs-utils` のインストールを実施。  
また、マウント用ディレクトリ `/mnt/test-nfs` の作成と、`/etc/fstab` への設定記載を実施した。   

実施後、以下のようになっている。
```
[user@redhat8 ~]$ cat /etc/redhat-release
Red Hat Enterprise Linux release 8.5 (Ootpa)
[user@redhat8 ~]$
[user@redhat8 ~]$ ls -l /mnt/
合計 0
drwxrwxrwx. 2 root root 6  1月 22 09:02 test-nfs
[user@redhat8 ~]$
[user@redhat8 ~]$ cat /etc/fstab | grep test-nfs
10.30.0.73:/Q/shares/test-nfs   /mnt/test-nfs   nfs     defaults        0 0
[user@redhat8 ~]$
```

補足: /etc/fstab の defaultsオプションとは？      
`rw,suid,dev,exec,auto,nouser,async` と同義。     
man mountに以下のように記載がある
> defaults  
> Use the default options: rw, suid, dev, exec, auto, nouser, and async.

※ `auto` のためOS起動時に自動マウントする設定だが、今回の検証はマウントしていない状態から開始している。


### 参考資料

NFSシステムコール (ファイル作成、削除など)   
[NFSと分散オブジェクト - 筑波大学システム情報工学研究科](http://www.coins.tsukuba.ac.jp/~yas/coins/dsys-2007/2008-01-22/)

## ログ整形について

種類の異なるログをExcelにひとまとめにした際の備考を記載する。    

Excelにひとまとめにすることで、ログ全体の時系列表示(=処理の流れ)がわかりやすくなり、           
障害発生時のログと比較した際、原因となっている処理が見つけやすくなる事を期待している。

### パケットキャプチャ

パケットキャプチャはWiresharkというパケット解析ツールで内容確認し、      
サーバ-クライアント間の通信のみをExcelに記載している。   
(`ip.addr == <サーバIPアドレス> && ip.addr == <クライアントIPアドレス>` でフィルタ)

<img src=".\2022-01-25.png" style="zoom: 33%; float: left;" />

### 各ログの記録秒数の差異

各ログごとに記録されるデフォルトの時刻桁数が異なるため、不足分は0埋めした。

- パケットキャプチャ: マイクロ秒
- log.smb: マイクロ秒
- `/var/log/messages` : ミリ秒
- Windowsの手動実行(ステップ記録ツールで記録): 1秒

### log.smb 整形

log.smb は各行に時刻が記載されているわけではなく、そのままだとExcelにまとめにくい。  
そのため、Pythonで整形ツールを作成した。

以下はlog.smb の内容。各行の頭に時刻が記載されているわけではないので、     
他のログとフォーマットを合わせてExcelに転記するのが困難だった。

```
[2022/01/25 22:56:00.191947,  3] ../source3/lib/access.c:338(allow_access)
  Allowed connection from 10.30.0.23 (10.30.0.23)
[2022/01/25 22:56:00.192103,  3] ../source3/smbd/oplock.c:1322(init_oplocks)
  init_oplocks: initializing messages.
[2022/01/25 22:56:00.192213,  3] ../source3/smbd/process.c:1957(process_smb)
  Transaction 0 of length 178 (0 toread)
```

↓ 整形ツールに読み込ませると、`時刻 ログレベル 生のログ内容` の順でcsv(タブ区切り)が作成される。
```
2022-01-25 22:56:00.191947	 3	[2022/01/25 22:56:00.191947,  3] ../source3/lib...
2022-01-25 22:56:00.191947	 3	  Allowed connection from 10.30.0.23 (10.30.0.23)
2022-01-25 22:56:00.192103	 3	[2022/01/25 22:56:00.192103,  3] ../source3/smbd...
2022-01-25 22:56:00.192103	 3	  init_oplocks: initializing messages.
2022-01-25 22:56:00.192213	 3	[2022/01/25 22:56:00.192213,  3] ../source3/smbd...
2022-01-25 22:56:00.192213	 3	  Transaction 0 of length 178 (0 toread)
```









成形ツール コード内容 (Windows/Linux)

```python
#!/usr/bin/env python3

import sys
import os
import re
import codecs

# ----------------------------------------
# 引数 など事前処理
# ----------------------------------------

# 引数なしで実行するとパスを聞かれるので入力 or 第1引数にファイルのパスを指定して実行
try:
    path = sys.argv[1]
except IndexError:
    path = input('sambaログのフルパスを入力してください: ')
    path = path.replace('"','') # Windonwsでパスのコピーをすると ” が入ってしまうので除去。

log_file_name = os.path.basename(path)  # ファイルパス(拡張子付き)を取得 -> sample.txt
log_dir_path = os.path.dirname(path)    # ディレクトリパスを取得 -> /foo/bar

# ----------------------------------------
# ファイルを読み込み、1行ずつ読み取り処理していく
# ----------------------------------------

# 最終的にファイルに吐き出す内容を格納する変数
contens_list = []   

print('ファイルを読み込んでいます...')

# ファイルを開いて、変数 lines に格納  ※codecsで変換できない文字を無視
with codecs.open(path, 'r', 'utf-8','ignore') as f:
    lines = f.readlines()

# 1行ずつ処理
for line in lines:

    # 時刻記載のある行の場合、logdateとloglevelを更新
    if re.search('^\[', line):

        li = line.replace('[','').replace(']',', ').split(', ')
        logdate = li[0].replace('/','-')
        loglevel = li[1]

    line = line.replace('\t','  ')                            # ログ内容のタブを置換
    contens_list += [logdate + '\t' + loglevel + '\t' + line] # contens_listにデータ格納

# ----------------------------------------
# contens_list をファイルに出力 
# ----------------------------------------

# 作成した contens_list をファイルに書き込み 
with open(log_dir_path + '/' + log_file_name + '.csv', 'w', encoding="utf-8") as f:
    f.writelines(contens_list)

input("Press Enter...")
```



## 備考: 通信経路上のbonding設定について

今回の検証では無関係だが、NFS、iSCSI、CIFSの通信経路上に round-robin(mode0)を使用するのは最適ではない。   
TCPの送信順序が保障されず、不要な再送が行われ帯域圧迫する場合があるため、       
順序が保障されるactive-backup(mode1)もしくはLACP(mode4)を使用するのが無難。

参考: Red Hat Customer Portal(要ログイン)   
[What is the best bonding or teaming mode for TCP traffic such as NFS, ISCSI, CIFS, etc?](https://access.redhat.com/solutions/2217521)