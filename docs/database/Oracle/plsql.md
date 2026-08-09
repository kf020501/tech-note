# PL/SQL

あんまり触りたいわけではないけど、管理コマンドをぐるぐるしたいときなど知らないと不便なのでやむを得ず覚える。


## Hello World

```sql
-- サーバー出力を有効にする
SET SERVEROUTPUT ON

-- BEGIN ... ENDの形で記載
BEGIN
    DBMS_OUTPUT.PUT_LINE('Hello World');
END;
/

-- 以下でもOK
BEGIN DBMS_OUTPUT.PUT_LINE('Hello World'); END;
```

実行結果
```text
SQL> SET SERVEROUTPUT ON
SQL> BEGIN
  2      DBMS_OUTPUT.PUT_LINE('Hello World');
  3  END;
  4  /
Hello World ★指定した文字列が出力されている

PL/SQLプロシージャが正常に完了しました。

SQL>
```

## 以降で使用する使用するサンプルテーブル

```sql
set line 200
select * from users;
```
```
        ID NAME        EMAIL                                 BIRTHDAY
---------- ----------- ------------------------------------- -------------------
         1 Alice       alice@example.com                     1990-01-01 00:00:00
         2 Bob         bob@example.com                       1985-02-15 00:00:00
         3 Charlie     charlie@example.com                   1980-03-20 00:00:00
```

## サンプル: usersテーブルのnameをloopで表示

select結果をuser_cursorに格納し、ぐるぐるする

```sql
-- サーバー出力を有効にする
SET SERVEROUTPUT ON

-- DECLARE: 変数、定数などの宣言を記載(任意)
DECLARE
   CURSOR user_cursor IS
      SELECT name FROM users;
   
   v_name VARCHAR2(50);
-- BEGIN: メインの処理を記載
BEGIN
   FOR user_record IN user_cursor LOOP
      -- 現在のレコードから名前を取得
      v_name := user_record.name;
      
      -- 名前を表示
      DBMS_OUTPUT.PUT_LINE('Name: ' || v_name);
   END LOOP;
-- EXCEPTION: 例外処理を記載(任意)
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/
```

## サンプル: usersテーブルを元にDBユーザーを作成

usersテーブルをselectして、CREATE USERをぐるぐるするサンプル

```sql
-- サーバー出力を有効にする
SET SERVEROUTPUT ON

-- DECLARE: 変数、定数などの宣言を記載(任意)
DECLARE
   CURSOR user_cursor IS
      SELECT name, email FROM users;
   
   v_username   VARCHAR2(30);
   v_email      VARCHAR2(100);
   v_password   VARCHAR2(30);

-- BEGIN: メインの処理を記載
BEGIN
   FOR user_record IN user_cursor LOOP
      -- 現在のレコードから名前とメールを取得
      v_username := user_record.name;
      v_email := user_record.email;

      -- パスワードを生成（メールの一部を使用）
      v_password := SUBSTR(v_email, 1, INSTR(v_email, '@') - 1) || '123';
      
      -- ユーザーを作成
      EXECUTE IMMEDIATE 'CREATE USER ' || v_username || ' IDENTIFIED BY ' || v_password;
      
      -- 必要な権限をユーザーに付与
      EXECUTE IMMEDIATE 'GRANT CONNECT TO ' || v_username;
      EXECUTE IMMEDIATE 'GRANT RESOURCE TO ' || v_username;
      
      -- 作成したユーザー情報を出力
      DBMS_OUTPUT.PUT_LINE('Created user: ' || v_username || ' with password: ' || v_password);
   END LOOP;

-- EXCEPTION: 例外処理を記載(任意)   
EXCEPTION
   WHEN OTHERS THEN
      DBMS_OUTPUT.PUT_LINE('An error occurred: ' || SQLERRM);
END;
/
```
確認
```test
SQL> select username from dba_users where username in (select upper(name) from users);

USERNAME
------------------------------------------------------------------------------
ALICE
BOB
CHARLIE
```

## 変数の命名規則

ChatGPTより

| 要素         | プレフィックス | 例                  | 説明                                                   |
| ------------ | -------------- | ------------------- | ------------------------------------------------------ |
| 変数         | `v_`           | `v_name`, `v_age`   | 変数を列、パラメータなどと区別するために使用されます。 |
| 定数         | `c_`           | `c_max_attempts`    | 定数値のために使用されます。                           |
| カーソル     | `cur_`         | `cur_user_cursor`   | カーソル名に使用されます。                             |
| パラメータ   | `p_`           | `p_id`, `p_name`    | プロシージャや関数のパラメータに使用されます。         |
| 型とレコード | `t_`           | `t_employee_record` | ユーザー定義の型とレコードに使用されます。             |
| 例外名       | `ex_`          | `ex_no_data_found`  | 例外処理名に使用されます。                             |
