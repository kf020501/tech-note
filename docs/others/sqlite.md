SQLite
========================================


AlmaLinuxへのSQLiteのインストール
--------------------------------------------------------------------------------

AlmaLinuxにSQLiteをインストールするには、以下のコマンドを実行。

```bash
sudo yum install sqlite
```


基本的な使い方
--------------------------------------------------------------------------------

### コンソールに入る

コンソールに入るには、以下のコマンドを使用します。

```bash
sqlite3 [データベース名]
```

### CREATE TABLE

```sql
-- SQLiteでusersテーブルを作成
CREATE TABLE users (
    ID       INTEGER PRIMARY KEY,
    name     TEXT,
    email    TEXT,
    birthday TEXT
);
```

### INSERT

```sql
-- usersテーブルにデータを挿入
INSERT INTO users (ID, name, email, birthday) VALUES (1,  'Alice',   'alice@example.com',   '1990-01-01');
INSERT INTO users (ID, name, email, birthday) VALUES (2,  'Bob',     'bob@example.com',     '1985-02-15');
INSERT INTO users (ID, name, email, birthday) VALUES (3,  'Charlie', 'charlie@example.com', '1980-03-20');
INSERT INTO users (ID, name, email, birthday) VALUES (4,  'David',   'david@example.com',   '1992-04-10');
INSERT INTO users (ID, name, email, birthday) VALUES (5,  'Eva',     'eva@example.com',     '1993-05-05');
INSERT INTO users (ID, name, email, birthday) VALUES (6,  'Frank',   'frank@example.com',   '1988-06-15');
INSERT INTO users (ID, name, email, birthday) VALUES (7,  'Grace',   'grace@example.com',   '1995-07-20');
INSERT INTO users (ID, name, email, birthday) VALUES (8,  'Hannah',  'hannah@example.com',  '1983-08-25');
INSERT INTO users (ID, name, email, birthday) VALUES (9,  'Ivy',     'ivy@example.com',     '1991-09-10');
INSERT INTO users (ID, name, email, birthday) VALUES (10, 'Jack',    'jack@example.com',    '1987-10-30');

-- この操作に対して、SQLiteは明示的なCOMMITは不要
```

SQLiteはOracleDBのようなDATE型を持っていません。'YYYY-MM-DD'の形式で日付をTEXTで保存できます。      
また、SQLiteのトランザクションはデフォルトで自動コミットされるため、明示的なCOMMITは不要です。

```sql
INSERT INTO users VALUES (1, 'Alice', 'alice@example.com', '1990-01-01');
```

### SELECT

```sql
SELECT * FROM users WHERE name = 'Alice';
```


データ編集
--------------------------------------------------------------------------------

### ビューの作成

ビューは、以下のように作成できます。

```sql
CREATE VIEW user_emails AS
SELECT ID, name, email FROM users;
```

### カラム追加/削除/リネーム

削除/リネーム には対応していないので、tableの作り直しが必要。

```sql
-- データタイプが INTEGER の 'new_column' という新しいカラムを追加
ALTER TABLE table_name ADD COLUMN new_column INTEGER;
```

### 値の加算

```sql
UPDATE example_table SET count = count + 1 WHERE id = 1;
```

その他SQL文
--------------------------------------------------------------------------------

### テーブルの複製

列名を編集したい場合など。

テーブル作成後にコピー
```sql
INSERT INTO destination_table (column1, column2, column3)
SELECT column1, column2, column3 FROM source_table;
```

テーブル作成時にコピー
```sql
CREATE TABLE destination_table AS SELECT * FROM source_table;
```

BashからSQLiteにアクセス
--------------------------------------------------------------------------------

以下のコマンドでBashから直接SQLクエリを実行できます。

```bash
sqlite3 test.db "SELECT * FROM users WHERE name = 'Alice';"
```



結果の整列
--------------------------------------------------------------------------------

`sqlite3` コマンドに `-column` オプションと `-header` オプションを追加することで、結果を見やすく整列できます。      
※ -column をつけると、長い文字が切れる

```bash
sqlite3 -column -header test.db "SELECT * FROM users;"
sqlite3 -header test.db "SELECT * FROM users;" | column -t -s'|'
```

sqliteコンソール内だと以下
```sql
.mode column
.mode list
.headers on
.width 10 20 30
```


既存のテーブルの確認
--------------------------------------------------------------------------------

SQLiteデータベース内のすべてのテーブルを一覧表示するには、次のコマンドを使用します。

```bash
sqlite3 test.db "SELECT name FROM sqlite_master WHERE type='table';"
```


バックアップ
--------------------------------------------------------------------------------

単純な`.db`ファイルのコピーによるバックアップも可能ですが、書き込みが同時に行われている場合は注意が必要です。`.backup` コマンドを使うことで、アトミックなバックアップが可能です。

```bash
sqlite3 existing_db.db ".backup backup_db.db"
```



