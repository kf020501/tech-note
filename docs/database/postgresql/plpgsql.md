
PL/pgSQL
================================================================================


Hello World
--------------------------------------------------------------------------------

Hello World と表示するだけ

```sql
DO $$
BEGIN
    RAISE NOTICE 'Hello World';
END
$$;
```
実行結果
```text
postgres=# DO $$
postgres$# BEGIN
postgres$#     RAISE NOTICE 'Hello World';
postgres$# END
postgres$# $$;
NOTICE:  Hello World
DO
```


サンプル: usersテーブルのnameをloopで表示
--------------------------------------------------------------------------------

このテーブルを使用する
```
 id |  name   |        email        |  birthday  
----+---------+---------------------+------------
  1 | Alice   | alice@example.com   | 1990-01-01
  2 | Bob     | bob@example.com     | 1985-02-15
  3 | Charlie | charlie@example.com | 1980-03-20
```

```sql
DO $$
DECLARE
  v_name TEXT;
BEGIN
  -- users テーブルの name 列を全件ループ
  FOR v_name IN
    SELECT name FROM users
  LOOP
    RAISE NOTICE 'Name: %', v_name;
  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    -- 例外発生時のメッセージ出力
    RAISE NOTICE 'An error occurred: %', SQLERRM;
END
$$;
```

実行結果
```text
NOTICE:  Name: Alice
NOTICE:  Name: Bob
NOTICE:  Name: Charlie
DO
```


サンプル: usersテーブルを元にDBユーザーを作成
--------------------------------------------------------------------------------

```sql
DO $$
DECLARE
  rec RECORD;
  pwd TEXT;
  dbname TEXT := current_database();
BEGIN
  FOR rec IN
    SELECT name, email
      FROM users
  LOOP
    -- メールアドレスの「@」前部分＋'123' をパスワードに
    pwd := substring(rec.email FROM '^[^@]+') || '123';

    -- ユーザー（ロール）を作成
    EXECUTE format(
      'CREATE ROLE %I WITH LOGIN PASSWORD %L',
      rec.name, pwd
    );

    -- データベース接続権限を付与
    EXECUTE format(
      'GRANT CONNECT ON DATABASE %I TO %I',
      dbname, rec.name
    );

    -- 作成結果を表示
    RAISE NOTICE 'Created user: % with password: %', rec.name, pwd;
  END LOOP;

EXCEPTION
  WHEN OTHERS THEN
    RAISE NOTICE 'An error occurred: %', SQLERRM;
END
$$;
```

結果

```text
NOTICE:  Created user: Alice with password: alice123
NOTICE:  Created user: Bob with password: bob123
NOTICE:  Created user: Charlie with password: charlie123
DO
```
