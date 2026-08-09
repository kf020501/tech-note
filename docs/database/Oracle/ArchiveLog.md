# アーカイブログ設定

## memo

- 設定変更にはDB停止が必要
- 確認は `select log_mode from v$database`
- 出力場所は `$ORACLE_BASE/fast_recovery_area/ORCL/archivelog` ?
- ちなみにREDO LOG保存場所は
    - `$ORACLE_BASE/oradata/ORCL/onlinelog/*.log`
    - `$ORACLE_BASE/fast_recovery_area/ORCL/onlinelog/*.log`

※ ORCL はインスタンス名

## アーカイブログモードに変更

動的変更 不可

```sql
-- 現在の状態を確認
select log_mode from v$database;

        -- LOG_MODE
        -- ------------
        -- NOARCHIVELOG ★ 現在ノーアーカイブログモードだと確認

-- モードを変更するために一旦shutdownし、mount状態で起動

shutdown immediate
startup mount

-- モード変更 アーカイブログモードに
ALTER DATABASE archivelog;

        -- 補足: ノーアーカイブにするには以下
        -- ALTER DATABASE noarchivelog;

-- DBをOPEN
ALTER DATABASE open;

-- 設定確認 パターン1
select log_mode from v$database;

        -- LOG_MODE
        -- ------------
        -- ARCHIVELOG  ★ アーカイブログモードに変更された

-- 設定確認 パターン2
archive log list

        -- Database log mode              Archive Mode  ★ アーカイブログモードに変更された
        -- Automatic archival             Enabled
        -- Archive destination            USE_DB_RECOVERY_FILE_DEST
        -- Oldest online log sequence     39
        -- Next log sequence to archive   41
        -- Current log sequence           41
```


## アーカイブログ出力先変更
動的変更 可能

```sql
set linesize 400;

-- 現在の状態を確認
archive log list

        -- Database log mode              Archive Mode ★ アーカイブログモードになっている
        -- Automatic archival             Enabled
        -- Archive destination            USE_DB_RECOVERY_FILE_DEST
        -- Oldest online log sequence     39
        -- Next log sequence to archive   41
        -- Current log sequence           41


-- 現在の出力先を確認
column dest_name format a20
column destination format a60
select dest_id,dest_name,destination from v$archive_dest;

        --    DEST_ID DEST_NAME            DESTINATION
        -- ---------- -------------------- ------------------------------------------------------------
        --          1 LOG_ARCHIVE_DEST_1   USE_DB_RECOVERY_FILE_DEST
        --          2 LOG_ARCHIVE_DEST_2
        --            (以下略)

-- USE_DB_RECOVERY_FILE_DEST となっている場合、保存先は以下を確認
show parameter db_recovery_file_dest

        -- NAME                                 TYPE        VALUE
        -- ------------------------------------ ----------- ------------------------------
        -- db_recovery_file_dest                string      /u01/app/oracle/fast_recovery_area ★
        -- db_recovery_file_dest_size           big integer 8256M


-- 設定変更
ALTER SYSTEM SET log_archive_dest_1='location=/database/orcl/REDO_1' scope=both;
ALTER SYSTEM SET log_archive_dest_2='location=/database/orcl/REDO_2' scope=both;

-- 設定変更 確認
select dest_id,dest_name,destination from v$archive_dest;

        --    DEST_ID DEST_NAME            DESTINATION
        -- ---------- -------------------- ------------------------------------------------------------
        --          1 LOG_ARCHIVE_DEST_1   /database/orcl/REDO_1
        --          2 LOG_ARCHIVE_DEST_2   /database/orcl/REDO_2
        --          3 LOG_ARCHIVE_DEST_3
        --          (以下略)

-- 強制的にログスイッチし動作確認
alter system archive log current;

-- ファイルが出来たか確認
!ls -lh /database/orcl/REDO_1
!ls -lh /database/orcl/REDO_2

-- 古いファイルを削除？

```
```sql
set linesize 400;
COLUMN NAME FORMAT a40;
COLUMN VALUE FORMAT a40;
SELECT NAME, VALUE FROM V$PARAMETER WHERE NAME LIKE 'log_archive%';

show parameter db_recovery_file_dest
```

[switch logfile と archive log current の違い ｜ Oracle使いのネタ帳](https://www.sql-dbtips.com/architecture/archive-log-current/)
> 強制的にログスイッチする点は共通しているが、 alter system switch logfile はアーカイブ完了までは見届けてくれないのだ。     
> ログスイッチが終わったら、後はアーカイバー(ARCH)に任せてお役放免というわけ。  
> 一方、 alter system archive log current はログスイッチだけでなく、アーカイブが済んでいないカレント以外の REDO ログまで全てアーカイブする。


[アーカイブログ出力先を変更する方法](http://database090212.com/oracle/manage3_6.html)

## 参考 REDOログの場所確認

```sql
-- REDOログのグループ、メンバーやステータスなど確認
column MEMBER format a80
select * from v$logfile;

        --     GROUP# STATUS  TYPE    MEMBER                                                                           IS_     CON_ID
        -- ---------- ------- ------- -------------------------------------------------------------------------------- --- ----------
        --         3         ONLINE  /u01/app/oracle/oradata/ORCL/onlinelog/o1_mf_3_k8o18b85_.log                     NO           0
        --         3         ONLINE  /u01/app/oracle/fast_recovery_area/ORCL/onlinelog/o1_mf_3_k8o18ddb_.log          YES          0
        --         2         ONLINE  /u01/app/oracle/oradata/ORCL/onlinelog/o1_mf_2_k8o18b6x_.log                     NO           0
        --         2         ONLINE  /u01/app/oracle/fast_recovery_area/ORCL/onlinelog/o1_mf_2_k8o18d6j_.log          YES          0
        --         1         ONLINE  /u01/app/oracle/oradata/ORCL/onlinelog/o1_mf_1_k8o18b5y_.log                     NO           0
        --         1         ONLINE  /u01/app/oracle/fast_recovery_area/ORCL/onlinelog/o1_mf_1_k8o18crf_.log          YES          0

select * from v$log;

        --     GROUP#    THREAD#  SEQUENCE#      BYTES  BLOCKSIZE    MEMBERS ARC STATUS           FIRST_CHANGE# FIRST_TIM NEXT_CHANGE# NEXT_TIME     CON_ID
        -- ---------- ---------- ---------- ---------- ---------- ---------- --- ---------------- ------------- --------- ------------ --------- ----------
        --          1          1         40  209715200        512          2 YES INACTIVE               4526878 18-AUG-22      4692815 21-AUG-22          0
        --          2          1         41  209715200        512          2 NO  CURRENT                4692815 21-AUG-22   1.8447E+19                    0
        --          3          1         39  209715200        512          2 YES INACTIVE               4452631 17-AUG-22      4526878 18-AUG-22          0
```