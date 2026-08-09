# 実行計画の固定

## はじめに: 実行計画の確認方法

SQLレポートとかでも確認できるが。
```sql
set line 200
set pagesize 100

-- 対象のSQSLを実行
select * from sample_users where id = 1;
-- 実行計画の確認
select * from table(dbms_xplan.display_cursor);
```

実行例:
```
SQL> select * from table(dbms_xplan.display_cursor);

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  cxzamm8bsb185, child number 0
-------------------------------------
select * from sample_users where id = 1

Plan hash value: 1774215885

--------------------------------------------------------------------------------------------
| Id  | Operation                   | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
--------------------------------------------------------------------------------------------
|   0 | SELECT STATEMENT            |              |       |       |     3 (100)|          |
|   1 |  TABLE ACCESS BY INDEX ROWID| SAMPLE_USERS |     1 |    75 |     3   (0)| 00:00:01 |
|*  2 |   INDEX UNIQUE SCAN         | SYS_C007998  |     1 |       |     2   (0)| 00:00:01 |
--------------------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   2 - access("ID"=1)


19行が選択されました。
```


## ヒント句

SQL文にヒント句を挿入する方法。  
シンプルd差が、SQL文を書き換える必要があるのがデメリット。  
また、SQL_IDが変わる。

```sql
-- ヒント句を指定して、強制的にフルスキャンに
select /*+ FULL(SAMPLE_USERS) */ * from sample_users where id = 1;
-- 実行計画の確認
select * from table(dbms_xplan.display_cursor);
```
実行例
```text
SQL> select * from table(dbms_xplan.display_cursor);

PLAN_TABLE_OUTPUT
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
SQL_ID  1yghnm9gw2u66, child number 0
-------------------------------------
select /*+ FULL(SAMPLE_USERS) */ * from sample_users where id = 1

Plan hash value: 3964565270

----------------------------------------------------------------------------------
| Id  | Operation         | Name         | Rows  | Bytes | Cost (%CPU)| Time     |
----------------------------------------------------------------------------------
|   0 | SELECT STATEMENT  |              |       |       |   301K(100)|          |
|*  1 |  TABLE ACCESS FULL| SAMPLE_USERS |     1 |    75 |   301K  (1)| 00:00:12 | ★ TABLE ACCESS FULLとなっている
----------------------------------------------------------------------------------

Predicate Information (identified by operation id):
---------------------------------------------------

   1 - filter("ID"=1)


18行が選択されました。
```

19c時点で最新(?)の実行計画の固定方法


## プランスタビリティ

※ 11g以降非推奨  
SQLを書き換えなくともOKな機能。  
アウトラインとかを作る方式。

## SPM (SQL Plan Management)

19cで最新の(?)固定方法。  
ベースラインを使用。

以下、19cではうまくいかない・・なぜ？
```sql
-- ベースラインの作成を有効化(デフォルトでFALSE)
show parameter optimizer_capture_sql_plan_baseline;
alter session set optimizer_capture_sql_plan_baseline=true;

-- ベースラインを使用するか(デフォルトでTRUE)
show parameter optimizer_use_sql_plan_baseline;
alter session set optimizer_use_sql_plan_baseline=true;
```

ベースラインの確認
```sql
set line 200
set pagesize 100
col sql_text for a50
col plan_name for a50
col sql_handle for a20
col sql_name for a50
select sql_text, plan_name, sql_handle, enabled, accepted, fixed from dba_sql_plan_baselines;
```

実行計画識別用のSQL_ID, PLAM_HASH_VALUE確認
```sql
select sql_id, plan_hash_value from v$sql_plan where sql_id = 'xxx';
```
実行例
```
SQL_ID        PLAN_HASH_VALUE
------------- ---------------
1kb56hd6c73bv       532132364
1kb56hd6c73bv       532132364
1kb56hd6c73bv       532132364
1kb56hd6c73bv       532132364
   :
   :
```
```sql
declare
   int number;
begin 
   int := dbms_spm.load_plans_fromcursor_chache(sql_id=>'xxx', plan_hash_value=>'xxxxx')
end;
/
```
[【Oracle Database】パフォーマンス④【実行計画の固定方法】#021 - YouTube](https://www.youtube.com/watch?v=sN1JRg4oopU)