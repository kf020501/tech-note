# PostgreSQL インストール&初期設定

(試行錯誤中)

## ライフサイクル

どのバージョンを使用すればいいかの確認。  
-> メジャーバージョンはどれも5年サポート。最新メジャーバージョンを使用すればよさそう。

[PostgreSQL: バージョン管理ポリシー](https://www.postgresql.org/support/versioning/)

翻訳

> PostgreSQL グローバル開発グループは、新機能を含む新しいメジャー バージョンを約 1 年に 1 回リリースします。各メジャー バージョンにはバグ修正が適用され、必要に応じて、少なくとも 3 か月に 1 回、「マイナー リリース」と呼ばれるセキュリティ修正がリリースされます。マイナー リリース スケジュールの詳細については、 マイナー リリース ロードマップを参照してください。
> 
> リリース チームが、重大なバグまたはセキュリティ修正が重要すぎて、定期的にスケジュールされているマイナー リリースまで待つことができないと判断した場合、マイナー リリース ロードマップ外でリリースを利用可能にすることがあります。
> 
> PostgreSQL Global Development Group は、メジャー バージョンを最初のリリースから 5 年間サポートします。メジャー バージョンの 5 周年が経過すると、修正を含む最後のマイナー リリースが 1 つ追加され、サポートが終了 (EOL) とみなされ、サポートされなくなります。


## インストール

[PostgreSQL: Linux ダウンロード (Red Hat ファミリー)](https://www.postgresql.org/download/linux/redhat/)


OS: AlmaLinux 9.x
DB: PostgreSQL 16.x 

```sh
# リポジトリ RPM をインストール
dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm

# 組み込みの PostgreSQL モジュールを無効に
dnf -qy module disable postgresql

# PostgreSQL をインストール
dnf install -y postgresql16-server

# データベースを初期化(必要なファイルが既に存在しているかチェック?)
/usr/pgsql-16/bin/postgresql-16-setup initdb

# 起動・自動起動有効化
systemctl enable postgresql-16
systemctl start postgresql-16

# ポート開放
firewall-cmd --add-port=5432/tcp --permanent
firewall-cmd --reload

# postgresユーザーが出来ていることを確認
cat /etc/passwd | grep postgres

    # 実行例:
    # postgres:x:26:26:PostgreSQL Server:/var/lib/pgsql:/bin/bash

# 必要に応じてpostgresユーザーのパスワードを変更
passwd postgres


# リモート接続の許可設定 
cp -p /var/lib/pgsql/16/data/postgresql.conf /var/lib/pgsql/16/data/postgresql.conf.org
sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '192.168.*' /g" /var/lib/pgsql/16/data/postgresql.conf
diff /var/lib/pgsql/16/data/postgresql.conf.org /var/lib/pgsql/16/data/postgresql.conf

# 許可する認証方法の設定
# pg_hba.confファイルで、接続を試みる各クライアントに使用される認証方法を指定
# peerとなっているのは、Oracleで言うところのOS認証?
cp -p /var/lib/pgsql/16/data/pg_hba.conf /var/lib/pgsql/16/data/pg_hba.conf.org
cat << '____EOF____' > /var/lib/pgsql/16/data/pg_hba.conf
# "local" is for Unix domain socket connections only
local   all             all                                     scram-sha-256
# IPv4 local connections:
host    all             all             192.168.10.0/24          scram-sha-256
# IPv6 local connections:
host    all             all             ::1/128                 scram-sha-256
# Allow replication connections from localhost, by a user with the
# replication privilege.
local   replication     all                                     scram-sha-256
host    replication     all             192.168.10.0/24          scram-sha-256
host    replication     all             ::1/128                 scram-sha-256
____EOF____

# 設定反映
systemctl restart postgresql-16
```

## 初期設定

### PostgreSQLのCLIに移行

```sh
# rootからpostgresユーザー権限で、PostgreSQLのCLIに移行
sudo -u postgres psql
```

現在のログインユーザーを確認
```sql
SELECT current_user;
```


### データベースと所有者について

PostgreSQLでは、ユーザー名はユーザーと同名のDBの所有者となるため、今回はセットで作成する。

所有者の権限は以下。

- ログイン時のデフォルトの接続先
- すべてのスキーマ、テーブル、関数、シーケンスの作成権限
- データベース全体に対する完全な操作権限
- 他のユーザーに対して権限を付与または剥奪

### ユーザーの作製

```sql
-- dbuserという名前のユーザーを作成
CREATE USER dbuser WITH ENCRYPTED PASSWORD 'dbuser';

-- ユーザー一覧の確認 パターン1
\du
-- ユーザー一覧の確認 パターン2
SELECT * FROM pg_catalog.pg_user;
```

実行例:
```
postgres=# CREATE USER dbuser WITH ENCRYPTED PASSWORD 'your_password';
CREATE ROLE
postgres=#
postgres=# \du
                             List of roles
 Role name |                         Attributes
-----------+------------------------------------------------------------
 dbuser    |
 postgres  | Superuser, Create role, Create DB, Replication, Bypass RLS

postgres=#
postgres=# SELECT * FROM pg_catalog.pg_user;
 usename  | usesysid | usecreatedb | usesuper | userepl | usebypassrls |  passwd  | valuntil | useconfig
----------+----------+-------------+----------+---------+--------------+----------+----------+-----------
 postgres |       10 | t           | t        | t       | t            | ******** |          |
 dbuser   |    16388 | f           | f        | f       | f            | ******** |          |
(2 rows)

postgres=#
```

### データベースの作成

```sql
-- dbuseという名前のデータベースを作成
CREATE DATABASE dbuser OWNER dbuser;

-- データベース一覧を確認
SELECT * FROM pg_database;
-- または
\l
```

### 作製したユーザーでデータベースに接続

```sh
# rootからpostgresユーザー権限で、PostgreSQLのCLIに移行
sudo -u postgres psql -U dbuser
# 接続先DBを指定するケース
sudo -u postgres psql -d mydatabase -U dbuser
```

```
GRANT CREATE ON SCHEMA public TO dbuser;
```

## SQL

### テーブルの作成・確認
```sql
-- usersテーブルの作成
CREATE TABLE users (
    ID       SERIAL PRIMARY KEY,
    name     VARCHAR(40),
    email    VARCHAR(80),
    birthday DATE
);

-- usersテーブルにデータを挿入
INSERT INTO users (name, email, birthday) VALUES ('Alice',   'alice@example.com',   '1990-01-01');
INSERT INTO users (name, email, birthday) VALUES ('Bob',     'bob@example.com',     '1985-02-15');
INSERT INTO users (name, email, birthday) VALUES ('Charlie', 'charlie@example.com', '1980-03-20');

-- テーブル一覧の確認
SELECT * FROM pg_database;
```

### INDEX関連

作成
```sql
-- メールアドレスに対するユニークインデックス
CREATE UNIQUE INDEX sample_users_email_address
ON sample_users (email_address);

-- 誕生日 (birthday) に対するインデックス
CREATE INDEX sample_users_birthday
ON sample_users (birthday);
```

確認
```sql
-- パターン1
SELECT indexname, indexdef
FROM pg_indexes
WHERE tablename = 'sample_users';

-- パターン2
\d sample_users
```

実行例
```text
dbuser=> SELECT indexname, indexdef
dbuser-> FROM pg_indexes
dbuser-> WHERE tablename = 'sample_users';
         indexname          |                                             indexdef
----------------------------+---------------------------------------------------------------------------------------------------
 sample_users_pkey          | CREATE UNIQUE INDEX sample_users_pkey ON public.sample_users USING btree (id)
 sample_users_email_address | CREATE UNIQUE INDEX sample_users_email_address ON public.sample_users USING btree (email_address)
 sample_users_birthday      | CREATE INDEX sample_users_birthday ON public.sample_users USING btree (birthday)
(3 rows)


dbuser=> \d sample_users
                                       Table "public.sample_users"
    Column     |          Type          | Collation | Nullable |                 Default
---------------+------------------------+-----------+----------+------------------------------------------
 id            | integer                |           | not null | nextval('sample_users_id_seq'::regclass)
 first_name    | character varying(50)  |           |          |
 middle_name   | character varying(50)  |           |          |
 last_name     | character varying(50)  |           |          |
 email_address | character varying(100) |           |          |
 birthday      | date                   |           |          |
 gender        | character(1)           |           |          |
 is_active     | boolean                |           |          |
Indexes:
    "sample_users_pkey" PRIMARY KEY, btree (id)
    "sample_users_birthday" btree (birthday)
    "sample_users_email_address" UNIQUE, btree (email_address)


dbuser=>
```


## ディレクトリ構成

```
/var/lib/pgsql/16/
├── backups/    # デフォルトで作られていたが空っぽ。バックアップ取るときに使っていいのか？
└── data/       # PostgreSQLのメインデータディレクトリ
    ├── base/           # 各データベースの実データを保存（各データベースのOIDのサブディレクトリ）
    ├── global/         # クラスター全体のメタデータ（ロールやシステムテーブル）を格納
    ├── pg_wal/         # WAL（Write-Ahead Log）ファイルを保存。クラッシュリカバリやPITRに使用
    ├── pg_hba.conf     # 認証の制御設定ファイル。どのIPアドレスやユーザーがどのデータベースに接続できるかを指定。
    └── postgresql.conf # メイン設定ファイル
```

## バックアップ/リストア

増分バックアップはないみたい(17からできる？)ので、  
フルバックアップ + WALアーカイブ(redoログアーカイブ相当)でバックアップする。

### 物理フルバックアップ

コマンドで実施
```
pg_basebackup -D /tmp/pg_basebackup/$(date +\%Y-\%m-\%d) -F tar -z -P
```

| オプション        | 説明                                                                      |
| ----------------- | ------------------------------------------------------------------------- |
| `-D /path/to/dir` | バックアップを保存する**出力ディレクトリ**を指定。                        |
| `-F tar`          | バックアップの**フォーマット**を指定。この場合は`tar`フォーマットで保存。 |
| `-z`              | バックアップを**圧縮**して、ストレージスペースを節約。                    |
| `-P`              | バックアップの進行状況を表示。                                            |
| `-U postgres`     | バックアップに使用する**ユーザー**（この場合は`postgres`）を指定。        |

### WALログをアーカイブさせる

```
archive_mode = on              # WALアーカイブを有効にする
archive_command = 'cp %p /mnt/backup/pg_wal_archive/%f'  # WALファイルをアーカイブ
archive_timeout = 600          # 10分ごとにWALをアーカイブ
```
## COPYによるCSV読み込み

### サーバ側ファイルを読み込む（`COPY`）

```sql
COPY table_name
FROM '/path/to/data.csv'
WITH (
  FORMAT csv,
  HEADER true,
  DELIMITER ',',
  ENCODING 'UTF8'
);
```

### クライアント側ファイルを読み込む

```bash
psql -d dbname -U user -c "\copy table_name FROM 'data.csv' WITH (FORMAT csv, HEADER true)"
```
### オプション

`WITH (...)` の各項目を **表形式**で整理します。

| 項目      | 設定値 | 意味・役割                            | 補足                   |
| --------- | ------ | ------------------------------------- | ---------------------- |
| FORMAT    | csv    | 入力ファイルがCSV形式であることを指定 | `text` も指定可能      |
| HEADER    | true   | 1行目をヘッダ行（カラム名）として扱う | ヘッダなしなら `false` |
| DELIMITER | `,`    | 区切り文字をカンマに指定              | TSVなら `E'\t'`        |
| ENCODING  | UTF8   | ファイルの文字コードをUTF-8として解釈 | 日本語CSVは要注意      |

## メモリ

設定ファイルはこちら: `/var/lib/pgsql/17/data/postgresql.conf`

### shared_buffers

テーブルキャッシュ。OS全体の25%くらいが推奨みたい。  
初期値が128MBと小さいので、設定変更が実質必須。  
設定ファイルに`change requires restart`とあるので、反映にはサービス再起動が必要っぽい。

```ini
# 初期値は128MB
shared_buffers = 128MB

# 4GBにする例
shared_buffers = 4GB
```

確認
```sql
SHOW shared_buffers;

    -- 実行例:
    --  shared_buffers
    -- ----------------
    --  4GB
```

## ログ

### 出力場所の設定

`${PGDATA}/{log_directory設定}/`にでる模様  
修正後は設定の再読み込みが必要 `systemctl reload postgresql-17`
```txt
[postgres@postgres17 17]$ cat /var/lib/pgsql/17/data/postgresql.conf | grep -A 1 log_directory
log_directory = 'log'                   # directory where log files are written,
                                        # can be absolute or relative to PGDATA
```

デフォルトだと`/var/lib/pgsql/17/data/log/`

### 雑調査コマンド

```
grep -E 'FATAL|ERROR' $(ls -1rt /var/lib/pgsql/17/data/log/* | tail -1)
```
## サンプルデータ

### 顧客・注文表

customers

| id  | name    | city    |
| --- | ------- | ------- |
| 1   | Alice   | Tokyo   |
| 2   | Bob     | Osaka   |
| 3   | Charlie | Nagoya  |
| 4   | David   | Fukuoka |
| 5   | Eve     | Sapporo |

orders

| id  | user_id | date       |
| --- | ------- | ---------- |
| 1   | 1       | 2024-09-01 |
| 2   | 1       | 2024-09-10 |
| 3   | 2       | 2024-09-05 |
| 4   | 3       | 2024-09-15 |
| 5   | 5       | 2024-09-20 |


```sql
-- usersテーブルを作成
CREATE TABLE users (
    id SERIAL PRIMARY KEY,
    name VARCHAR(50),
    city VARCHAR(50)
);

-- ordersテーブルを作成
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    user_id INT REFERENCES users(id),
    date DATE
);

-- customersテーブルにサンプルデータを挿入
INSERT INTO users (name, city) VALUES
('Alice', 'Tokyo'),
('Bob', 'Osaka'),
('Charlie', 'Nagoya'),
('David', 'Fukuoka'),
('Eve', 'Sapporo');

-- ordersテーブルにサンプルデータを挿入
INSERT INTO orders (user_id, date) VALUES
(1, '2024-09-01'),  -- Alice
(1, '2024-09-10'),  -- Alice
(2, '2024-09-05'),  -- Bob
(3, '2024-09-15'),  -- Charlie
(5, '2024-09-20');  -- Eve
```

## GUIツール

[ダウンロード](https://www.pgadmin.org/download/pgadmin-4-windows/)
