# MySQL 初期設定

Oracleと比べて、selectしたとき自動で横幅調整されるのが死ぬほどうれしい。

## インストール

### MySQL (RHEL)

- [9.3.2. MySQL のインストール Red Hat Enterprise Linux 8 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/8/html/deploying_different_types_of_servers/installing-mysql_assembly_using-mysql)

```sh
yum module install mysql:8.0/server

systemctl start mysqld.service
systemctl enable mysqld.service
```

```text
[root@redhat8b ~]# hostnamectl
    :
  Operating System: Red Hat Enterprise Linux 8.7 (Ootpa)
       CPE OS Name: cpe:/o:redhat:enterprise_linux:8::baseos
            Kernel: Linux 4.18.0-425.3.1.el8.x86_64
      Architecture: x86-64
[root@redhat8b ~]# mysql -V
mysql  Ver 8.0.30 for Linux on x86_64 (Source distribution)
```

### MySQL (AlmaLinux)

```sh
dnf install -y mysql-server mysql

systemctl start mysqld.service
systemctl enable mysqld.service
systemctl status mysqld.service
```

```test
[root@mysql ~]# hostnamectl
    :
  Operating System: AlmaLinux 8.7 (Stone Smilodon)
       CPE OS Name: cpe:/o:almalinux:almalinux:8::baseos
            Kernel: Linux 4.18.0-348.2.1.el8_5.x86_64
      Architecture: x86-64
[root@mysql ~]# mysql -V
mysql  Ver 8.0.30 for Linux on x86_64 (Source distribution)
```

### mariadb (AlmaLinux)
```sh
dnf install -y mariadb-server

systemctl enable mariadb
systemctl start mariadb
```

```text
[root@AlmaLinux8 ~]# hostnamectl
    :
  Operating System: AlmaLinux 8.7 (Stone Smilodon)
       CPE OS Name: cpe:/o:almalinux:almalinux:8::baseos
            Kernel: Linux 4.18.0-348.2.1.el8_5.x86_64
      Architecture: x86-64
[root@AlmaLinux8 ~]# mysql -V
mysql  Ver 15.1 Distrib 10.3.35-MariaDB, for Linux (x86_64) using readline 5.1
```

設定ファイルは
/etc/my.cnf.d/


## rootパスワード設定

パスワード掛けないと、(OSのrootでなくとも) `mysql -u root` とかすると入れてしまう。

```sh
cat << '__EOF__' | mysql -u root
update mysql.user set password=password('P@ssw0rd') where user = 'root';
flush privileges;
__EOF__
```
mysql8以降だとこれ？
ALTER USER 'root'@'localhost' identified BY '任意のパスワード';

## ユーザー追加 権限付与
```sql
create user dbuser@"%" identified by 'dbuser';
grant all privileges on *.* to dbuser@"%" with grant option;

-- 確認
select * from mysql.user;
```

## DB 確認系

### DB一覧

```sql
show databases;
```
```text
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              | ★ 次はこれを確認
| performance_schema |
| sys                |
+--------------------+
```

### DBのテーブル一覧

```sql
show tables from mysql;
```
```text
+------------------------------------------------------+
| Tables_in_mysql                                      |
+------------------------------------------------------+
| columns_priv                                         |
| component                                            |
|    :                                                 |
| user                                                 | ★ 次はこれを確認
+------------------------------------------------------+
```

### テーブルのカラム

```sql
desc mysql.user;
```
```text
+--------------------------+-----------------------------------+------+-----+-----------------------+-------+
| Field                    | Type                              | Null | Key | Default               | Extra |
+--------------------------+-----------------------------------+------+-----+-----------------------+-------+
| Host                     | char(255)                         | NO   | PRI |                       |       | ★ 次はこれを確認
| User                     | char(32)                          | NO   | PRI |                       |       | ★ 次はこれを確認
|   :                      |   :                               |   :  |   : |   :                   |       |
| User_attributes          | json                              | YES  |     | NULL                  |       |
+--------------------------+-----------------------------------+------+-----+-----------------------+-------+
```

### テーブルのレコード

```sql
select host, user from mysql.user;
```
```text
+-----------+------------------+
| host      | user             |
+-----------+------------------+
| localhost | mysql.infoschema |
| localhost | mysql.session    |
| localhost | mysql.sys        |
| localhost | root             |
+-----------+------------------+
```

## MySQL クライアント

Oracleと異なり、クライアントOSに専用パッケージのインストールは必要なさそう。
(言語ごとのパッケージのみでOK)


## MySQL Workbench

- Oracle SQL Developer的なGUIツール
- MariaDBでも使える(完全互換ではなさそう)


### 起動した際、前回開いていたタブが再表示される

Edit > Preferences > SQL Editor     
Save snapshot of open editors on close のチェックを外せばOK

### MariDBでエラー

mariadbに接続すると、以下のように表示される。

```text
MySQL Workbench

Connection Warning (test)

Incompatible/nonstandard server version or connection protocol
detected (10.3.35).

> 非互換/非標準のサーバー バージョンまたは接続プロトコルが検出されました (10.3.35)。

A connection to this database can be established but some MySQL 
Workbench features may not work properly since the database is not 
fully compatible with the supported versions of MySQL.

> このデータベースへの接続は確立できますが、サポートされているバージョンの MySQL と
> データベースが完全に互換性がないため、一部の MySQL Workbench 機能が正しく動作しない場合があります。

MySQL Workbench is developed and tested for MySQL Server versions 
5.6 5.7 and 8.0. 
For MySQL Server older than 5.6, please use MySQL Workbench version 
6.3.

[ ] Don't show this message again   [Continue Anyway] [キャンセル]
```

### 日本語化

古いバージョンだと設定ファイルがあるようだが。。

ここの      
C:\Program Files\MySQL\MySQL Workbench 8.0 CE\data\main_menu.xml

key="caption" 属性の箇所を編集するといいらしい。grepして翻訳でもするか。

## phpMyAdmin

[serverあれこれ: CentOS8-StreamにphpMyAdminとMariaDBをインストールする](http://serverarekore.blogspot.com/2021/02/centos8-streamphpmyadminmariadb.html)


## 参考

- [CentOS8 MariaDB構築 – 手当たり次第に書くんだ](https://www.si1230.com/?p=42315)
