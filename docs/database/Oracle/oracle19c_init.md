# Oracle19c 初期設定

## 環境

- RHEL 8.x
- OracleDB 19c

## インストール

### OSユーザー/グループ作成

```sh
# oinstallグループとdbaグループを作成
groupadd oinstall
groupadd dba

# oracleユーザーの作成(作成済みグループに所属させる)
useradd -m oracle -g oinstall -G dba -s /bin/bash
passwd oracle # パスワード設定 今回は'oracle'を入力

# 作成できているか確認
cat /etc/group | grep -E 'oinstall|dba'
cat /etc/passwd | grep -E 'oracle'
```

### 環境変数設定

- linuxでは`~/.bash_profile`とかに記載すればいい感じ。
- ORACLE_SID には存在しないSIDを記載し、sqlplusする前に明示的に指定したほうがいい(って有識者が言ってた)
- `$ORACLE_HOME/bin` にはdbcaなどのコマンドの実体があるので、パスを通しておくといいかも。

```sh
# oracleユーザーの .bash_profile に環境変数を追記
cat << '__EOF__' >> /home/oracle/.bash_profile
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.3.0/dbhome_1
export ORACLE_SID=orcl
export PATH=$ORACLE_HOME/bin:$PATH
__EOF__

cat /home/oracle/.bash_profile # ⇒確認
```

### ディレクトリ作成

```sh
# ORACLE_HOMEに指定したディレクトリを作成し、所有者変更
mkdir -p /u01/app/oracle/product/19.3.0/dbhome_1
chown -R oracle.oinstall /u01
ls -l / | grep u01 # ⇒確認
```

### 必要パッケージ

以下を参考にインストール    
[x86-64でサポートされているRed Hat Enterprise Linux 8のディストリビューション](https://docs.oracle.com/cd/F19136_01/ladbi/supported-red-hat-enterprise-linux-8-distributions-for-x86-64.html)

```sh
dnf install -y \
bc binutils elfutils-libelf elfutils-libelf-devel \
fontconfig-devel glibc glibc-devel ksh libaio \
libaio-devel libXrender libX11 libXau libXi libXtst \
libgcc libnsl librdmacm libstdc++ libstdc++-devel libxcb \
libibverbs make policycoreutils policycoreutils-python-utils \
smartmontools sysstat
```

### 19c インストール

```sh
# 転送したzipファイルの展開
cd /u01/app/oracle/product/19.3.0/dbhome_1
unzip LINUX.X64_193000_db_home.zip

# エラー回避のための環境変数設定(インストール時のみ)
export LANG=C
export CV_ASSUME_DISTID=OL7

# OUI(Oracle Universal Installer)起動
./runInstaller  # ⇒GUIのインストール画面が起動します
```

GUI

※ 「Package: compat-libcap1-1.10」が解消しないのは、Oracleの不具合の模様。

[Oracle Database 19cのLinuxに影響する問題](https://docs.oracle.com/cd/F19136_01/rnrdm/linux-platform-issues.html#GUID-69942B7A-B662-48DC-8FC1-DFC56A3719D6)

## インスタンスの自動起動

- やっておかないと、サーバー起動の度にDB/リスナーを起動しなければいけなくてとてもだるい。
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
Environment=ORACLE_BASE=/u01/app/oracle
Environment=ORACLE_HOME=/u01/app/oracle/product/19.3.0/dbhome_1
Environment=ORACLE_SID=orcl
ExecStart=/u01/app/oracle/product/19.3.0/dbhome_1/bin/dbstart $ORACLE_HOME
ExecStop=/u01/app/oracle/product/19.3.0/dbhome_1/bin/dbshut $ORACLE_HOME
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

### 参考

- [Oracleソフトウェアの停止と起動](https://docs.oracle.com/cd/E57425_01/121/UNXAR/strt_stp.htm)
- [CentOS 8 : Oracle Database 19c : 自動起動の設定 : Server World](https://www.server-world.info/query?os=CentOS_8&p=oracle19c&f=5)
- [RHEL7からのサービス管理(systemd)を使ってオラクル自動起動設定をしてみた - Qiita](https://qiita.com/shimatter/items/05102d3dec367843ff1e)
- [Oracle Database 19cをOS起動時に自動起動させる設定手順(Oracle Linux7.7) - そういうのがいいブログ](https://souiunogaii.hatenablog.com/entry/Oracle19c-AutoStart#%E6%89%8B%E9%A0%86oratab%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%81%AE%E8%A8%AD%E5%AE%9A%E5%A4%89%E6%9B%B4)

## 補足: タイムゾーン

DBタイムゾーンはUTCになっているが、変更不要(らしい)。

```sql
-- セッションタイムゾーン
SELECT SESSIONTIMEZONE FROM DUAL;

    -- SESSIONTIMEZONE
    -- ---------------------------------------------------------------------------
    -- +09:00


SELECT DBTIMEZONE FROM DUAL;

    -- DBTIME
    -- ------
    -- +00:00
```

## 補足: 検証用設定

### systemユーザーのPW変更

SQL Developerで使いたいので、とりあえずsystemだけ変更しておく。
なお、SQL Developerでログインする際、systemのロールは「デフォルト」

```sql
-- systemのパスワードを変更 ※ 一般ユーザー
ALTER USER system IDENTIFIED BY system;
```


### firewall設定
```sh
# リスナーポートを許可
firewall-cmd --add-port=1521/tcp --permanent
# 再読み込み
firewall-cmd --reload
# 設定確認
firewall-cmd --list-all
```


### 表領域 作成

検証で雑に使用できるよう、defaulttbs という名前の表領域を作成する

```sql
-- 表領域 作成
CREATE TABLESPACE usertbs
  DATAFILE '/u01/app/oracle/usertbs.dbf'
  SIZE 100M AUTOEXTEND ON;

-- 表領域 確認
SELECT TABLESPACE_NAME, CONTENTS FROM DBA_TABLESPACES;
```


### ユーザー作成

```sql
-- ユーザー作成(パスワード dbuser)
CREATE USER dbuser
  IDENTIFIED BY dbuser
  DEFAULT TABLESPACE usertbs
  TEMPORARY TABLESPACE temp
  QUOTA 10M ON usertbs
  PROFILE default;

-- ユーザー一覧表示
set linesize 400;
column USERNAME format a40;
column DEFAULT_COLLATION format a40;
SELECT USERNAME, DEFAULT_COLLATION FROM dba_users ORDER BY username;

-- このままでは権限不足で接続やテーブル作成が行えない。別途権限付与をする必要がある。
-- 今回は、雑にDBA権限を付与。(接続、テーブル作成権限 含む)
GRANT DBA TO dbuser;

-- 確認
column GRANTEE format a40;
column GRANTED_ROLE format a40;
SELECT * FROM dba_role_privs WHERE GRANTED_ROLE = 'DBA';

    -- GRANTEE                                  GRANTED_ROLE                             ADM DEL DEF COM INH
    -- ---------------------------------------- ---------------------------------------- --- --- --- --- ---
    -- DBUSER                                   DBA                                      NO  NO  YES NO  NO
    -- SYS                                      DBA                                      YES NO  YES YES YES
    -- SYSTEM                                   DBA                                      NO  NO  YES YES YES
```

接続できることを確認
```sh
sqlplus dbuser/dbuser
```

- [CREATE USER、ユーザーの作成 - オラクル・Oracleをマスターするための基本と仕組み](https://www.shift-the-oracle.com/config/create-user.html)
- [新規ユーザー作成時に最低限割り当てるべき権限 | 技術情報 | 株式会社コーソル](https://cosol.jp/knowledge/knowledge_post/ob0003_new_user/)


### DEFAULTプロファイル

```sql
-- default プロファイルのパスワードを無期限に変更
ALTER PROFILE DEFAULT LIMIT password_life_time UNLIMITED;

-- DEFAULTプロファイルのパスワード有効期限を確認
column PROFILE format a40;
column RESOURCE_NAME format a40;
column LIMIT format a40;
SELECT PROFILE, RESOURCE_NAME, LIMIT FROM DBA_PROFILES WHERE RESOURCE_NAME = 'PASSWORD_LIFE_TIME' AND PROFILE = 'DEFAULT';
```


## 基本操作

### インスタンス起動

起動の流れは以下の通り


1. **SHUTDOWN**: インスタンスが停止し、DBが稼働していない状態
2. **NOMOUNT**: 初期パラメーターファイル読み込み ---> 、**インスタンス起動**。
3. **MOUNT**: 初期パラメータ情報を元に**制御ファイルをオープン**
4. **OPEN**: 制御ファイルの情報をもとに**REDOログファイル**、**データファイル**をオープン

```sql
-- SHUTDOWN のインスタンスを起動(openまで)
startup;

-- SHUTDOWN のインスタンスを、MOUNT状態に
startup mount;

-- インスタンスを 変更 (現在の状態が SHUTDOWN 以外)
alter database mount;
alter database open;

-- インスタンスをシャットダウン(immediate)
shutdown immediate;

-- 現在のインスタンスの状態を確認 (現在の状態が SHUTDOWN 以外)
select instance_name, status from v$instance;

    -- NOMOUNT の場合  STARTED
    -- MOUNT の場合    MOUNTED
    -- OPEN の場合     OPEN
```

### インスタンス停止

停止の種類

| コマンド               | 内容                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------- |
| shutdown               | すべてのセッションが切断されるまで待機                                                                  |
| shutdown normal        | すべてのセッションが切断されるまで待機                                                                  |
| shutdown transactional | 現行トランザクションの終了まで待機                                                                      |
| shutdown immediate     | ★ 現行トランザクションをすべてロールバックして停止                                                      |
| shutdown abort         | 強制終了 immediateで止まらない場合に使用 </br> 次回データベース起動時にインスタンス・リカバリが自動で走る |



### リスナーの起動停止


## その他

### 既存DB確認

起動していないDBはこの辺りを確認。
`spfile<ORACLE_SID>.ora` など、ファイル名にSIDが含まれるファイルから確認する。
```sh
[oracle@oracle19c ~]$ ls -l $ORACLE_HOME/dbs/
    :
-rw-r-----. 1 oracle oinstall     3584 Jul 10 11:19 spfileorcl.ora
-rw-r-----. 1 oracle oinstall     3584 Jun 18 05:41 spfiletest01.ora
```

起動しているDBはpsコマンドをgrepすることで確認。
```
[oracle@oracle19c ~]$ ps -ef | grep ora_pmon
oracle    145709       1  0 Jun11 ?        00:01:38 ora_pmon_orcl
oracle    311864    2378  0 Jun18 ?        00:01:19 ora_pmon_test01
oracle    726601  726430  0 02:42 pts/1    00:00:00 grep --color=auto ora_pmon
```

## Oracle Client

### インストール

ダウンロードはここから。

[Oracle Database 19c Download for Linux x86-64 | Oracle 日本](https://www.oracle.com/jp/database/technologies/oracle19c-linux-downloads.html)   
Oracle Database 19c Client (19.3) for Linux x86-64 -> LINUX.X64_193000_client.zip

```sh
# oinstallグループとdbaグループを作成
groupadd oinstall
groupadd dba

# oracleユーザーの作成(作成済みグループに所属させる)
useradd -m oracle -g oinstall -G dba -s /bin/bash
passwd oracle # パスワード設定 今回は'oracle'を入力

# 作成できているか確認
cat /etc/group | grep -E 'oinstall|dba'
cat /etc/passwd | grep -E 'oracle'

# oracleユーザーの .bash_profile に環境変数を追記
cat << '__EOF__' >> /home/oracle/.bash_profile
export ORACLE_BASE=/u01/app/oracle
export ORACLE_HOME=$ORACLE_BASE/product/19.3.0/client_1
export PATH=$ORACLE_HOME/bin:$PATH
__EOF__

# ORACLE_HOMEに指定したディレクトリを作成し、所有者変更
mkdir -p /u01/app/oracle/product/19.3.0/client_1
chown -R oracle.oinstall /u01

# 必要パッケージのインストール
dnf install -y \
bc binutils elfutils-libelf elfutils-libelf-devel \
fontconfig-devel glibc glibc-devel ksh libaio \
libaio-devel libXrender libX11 libXau libXi libXtst \
libgcc libnsl librdmacm libstdc++ libstdc++-devel libxcb \
libibverbs make policycoreutils policycoreutils-python-utils \
smartmontools sysstat

# 転送したzipファイルの展開
unzip LINUX.X64_193000_db_home.zip

# エラー回避のための環境変数設定(インストール時のみ)
export LANG=C
export CV_ASSUME_DISTID=OL7

# OUI(Oracle Universal Installer)起動
./runInstaller  # ⇒GUIのインストール画面が起動します
```

### 接続 (簡易接続ネーミング)

```sh
# データベースサーバにリモート接続(簡易接続ネーミング)
sqlplus user01/password01@10.30.0.68:1521/orcl
```

### 接続 (ローカルネーミング)

tnsnames.ora設定  
ネットサービス名が確認ポイント(以下の例では netservice01)

```text
NETSERVICE01 =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 10.30.0.68)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = orcl)
    )
  )
```
接続 sqlplus ユーザー名/パスワード@ネットサービス名

```sh
# データベースサーバにリモート接続(ローカルネーミング)
sqlplus user01/password01@netservice01
```

- [x86-64でサポートされているRed Hat Enterprise Linux 8のディストリビューション](https://docs.oracle.com/cd/F19136_01/lacli/supported-red-hat-enterprise-linux-8-distributions-for-x86-64.html#GUID-B1487167-84F8-4F8D-AC31-A4E8F592374B)


