# Oracle Database 21c XE

## そもそもExpress Editionってどんな感じなのか？

- [Linux用Oracle Database 21c Express Editionがリリースされました | コーソルDatabaseエンジニアのBlog](https://cosol.jp/techdb/2021/09/oracle_21c_xe_linux_released/)
- [Oracle Database 21c Express Editionの紹介(Linux編) - Qiita](https://qiita.com/nakaie/items/5c7f5ccd0a70ca66b189)

リソース的には以下

> - 2スレッドまでのCPU
> - 2GBまでのRAM
> - 12GBまでのユーザーデータ


## ダウンロード

ダウンロードはここから  
[Oracle Database Express Editionクイック・スタート | Oracle 日本](https://www.oracle.com/jp/database/technologies/appdev/xe/quickstart.html)

今回はAlmaLinux 8.7にインストールするので、以下のファイルが必要。

- oracle-database-preinstall-21c-1.0-1.el8.x86_64.rpm
- oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm



## 設定・インストール

```sh
# ユーザー作成
# oinstallグループとdbaグループを作成
groupadd oinstall
groupadd dba

# oracleユーザーの作成(作成済みグループに所属させる)
useradd -m oracle -g oinstall -G dba -s /bin/bash
passwd oracle

# oracleユーザーに環境変数を追加
cat << '__EOF__' >> /home/oracle/.bash_profile
export ORACLE_SID=XE
export ORACLE_BASE=/opt/oracle
export ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
export PATH=$ORACLE_HOME/bin:$PATH
__EOF__


# ファイル配置を確認
ls
    # 実行例:
    # [root@oracle-test ~]# ls
    # oracle-database-preinstall-21c-1.0-1.el8.x86_64.rpm  oracle-database-xe-21c-1.0-1.ol8.x86_64.rpm

# インストール
dnf install -y oracle-database-*

# hostsにIP追加
echo '10.30.0.xx oracle21c-xe oracle21c-xe.local' >> /etc/hosts

    # これをやっておかないと"No valid IP Address returned for the host"のようなエラーが出る。

# 初期設定 実行
/etc/init.d/oracle-xe-21c configure

    # 実行例:
    # [root@oracle21cxe ~]# /etc/init.d/oracle-xe-21c configure
    # Specify a password to be used for database accounts. Oracle recommends that the password entered should be at least 8 characters in length, contain at least 1 uppercase character, 1 lower case character and 1 digit [0-9]. Note that the same password will be used for SYS, SYSTEM and PDBADMIN accounts: 
    # Confirm the password:         ★ SYS, SYSTEM , PDBADMIN のパスワードを入力
    # Configuring Oracle Listener.  ★ SYS, SYSTEM , PDBADMIN のパスワードを入力
    # Listener configuration succeeded.
    # Configuring Oracle Database XE.
    # Enter SYS user password:
    # ...
    # Look at the log file "/opt/oracle/cfgtoollogs/dbca/XE/XE.log" for further details.

    # Connect to Oracle Database using one of the connect strings:
    #      Pluggable database: oracle21cxe.local:1539/XEPDB1
    #      Multitenant container database: oracle21cxe.local:1539
    # Use https://localhost:5500/em to access Oracle Enterprise Manager for Oracle Database XE
    # [root@oracle21cxe ~]#
```

## 設定確認

```
[oracle@oracle21cxe ~]$ lsnrctl status

LSNRCTL for Linux: Version 21.0.0.0.0 - Production on 02-JUL-2023 08:26:42

Copyright (c) 1991, 2021, Oracle.  All rights reserved.

Connecting to (DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=oracle21cxe.local)(PORT=1539)))
STATUS of the LISTENER
------------------------
Alias                     LISTENER
Version                   TNSLSNR for Linux: Version 21.0.0.0.0 - Production
Start Date                02-JUL-2023 08:06:24
Uptime                    0 days 0 hr. 20 min. 19 sec
Trace Level               off
Security                  ON: Local OS Authentication
SNMP                      OFF
Default Service           XE
Listener Parameter File   /opt/oracle/homes/OraDBHome21cXE/network/admin/listener.ora
Listener Log File         /opt/oracle/diag/tnslsnr/oracle21cxe/listener/alert/log.xml
Listening Endpoints Summary...
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcp)(HOST=oracle21cxe.local)(PORT=1539)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=ipc)(KEY=EXTPROC1521)))
  (DESCRIPTION=(ADDRESS=(PROTOCOL=tcps)(HOST=oracle21cxe.local)(PORT=5500))(Security=(my_wallet_directory=/opt/oracle/admin/XE/xdb_wallet))(Presentation=HTTP)(Session=RAW))
Services Summary...
Service "XE" has 1 instance(s).
  Instance "XE", status READY, has 1 handler(s) for this service...
Service "XEXDB" has 1 instance(s).
  Instance "XE", status READY, has 1 handler(s) for this service...
Service "ff7daebe9f230d27e0530100007fedb6" has 1 instance(s).
  Instance "XE", status READY, has 1 handler(s) for this service...
Service "xepdb1" has 1 instance(s).
  Instance "XE", status READY, has 1 handler(s) for this service...
The command completed successfully
[oracle@oracle21cxe ~]$
[oracle@oracle21cxe ~]$
[oracle@oracle21cxe ~]$
[oracle@oracle21cxe ~]$
[oracle@oracle21cxe ~]$ sqlplus / as sysdba

SQL*Plus: Release 21.0.0.0.0 - Production on Sun Jul 2 08:27:36 2023
Version 21.3.0.0.0

Copyright (c) 1982, 2021, Oracle.  All rights reserved.


Connected to:
Oracle Database 21c Express Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0

SQL> Disconnected from Oracle Database 21c Express Edition Release 21.0.0.0.0 - Production
Version 21.3.0.0.0
[oracle@oracle21cxe ~]$
```


## 接続

SQL Developerで以下の情報を入力し、接続できることを確認した。

| 項目       | 値                                                       |
| ---------- | -------------------------------------------------------- |
| ユーザー名 | system                                                      |
| ロール     | デフォルト                                                   |
| パスワード | `# /etc/init.d/oracle-xe-21c configure` 時に入力したもの |
| ホスト名   | サーバのIPアドレス                                       |
| ポート     | 1521 `$ lsnrctl status` で確認                           |
| SID        | xe `$ lsnrctl status` で確認                             |


## インスタンスの自動起動

- やっておかないと、サーバー起動の度にDB/リスナーを起動しなければいけなくてだるい。
- リスナーも自動で起動するみたい

### SE Linux 設定

```sh
# permissiveに変更
sed -i -e "s/^SELINUX=.*$/SELINUX=permissive/g" /etc/selinux/config
# 確認
cat /etc/selinux/config | grep -e '^SELINUX=' 

# 一時的に無効化 -> Permissive
setenforce 0
```

### /etc/oratab

```
orcl:/u01/app/oracle/product/19.3.0/dbhome_1:N
↓
orcl:/u01/app/oracle/product/19.3.0/dbhome_1:Y
```

### service作成

/etc/systemd/system/oracledb.service 新規作成
```sh
[Unit]
Description=Oracle Database service
After=network.target

[Service]
Type=forking
TimeoutStopSec=5min
Environment=ORACLE_BASE=/opt/oracle
Environment=ORACLE_HOME=/opt/oracle/product/21c/dbhomeXE
Environment=ORACLE_SID=XE
ExecStart=/opt/oracle/product/21c/dbhomeXE/bin/dbstart $ORACLE_HOME
ExecStop=/opt/oracle/product/21c/dbhomeXE/bin/dbshut $ORACLE_HOME
User=oracle

[Install]
WantedBy=multi-user.target
```

```sh
# 再読み込み
systemctl daemon-reload

# 自動起動 許可
systemctl enable oracledb.service
systemctl start oracledb.service
```

## 参考   
[Installing Oracle Database XE](https://docs.oracle.com/en/database/oracle/oracle-database/21/xeinl/installing-oracle-database-free.html#GUID-728E4F0A-DBD1-43B1-9837-C6A460432733)

[Oracle Database 21c Express Editionの紹介(Linux編) - Qiita](https://qiita.com/nakaie/items/5c7f5ccd0a70ca66b189)