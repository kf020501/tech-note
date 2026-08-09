# パフォーマンスチューニング

## AWRレポート

Automatic Workload Repository 自動ワークロードリポジトリ

### 事前設定1: 

レポートを作成するためには、AWRスナップショットが必要。  
STATISTICS_LEVEL初期化パラメータを、TYPICAL(デフォルト)またはALLにする必要がある
```sql
-- 確認
show parameter statistics_level

-- 変更する場合
alter system set statistics_level=all scope=both;

-- インスタンス再起動
shutdown immediate
startup
```
スナップショットはデフォルトで60分間隔。  
変更する場合は以下の手順(動的変更OK)

```sql
set lines 180
col SNAP_INTERVAL for a30
col RETENTION for a30

-- 現在の状態を確認
select snap_interval, retention from DBA_HIST_WR_CONTROL;

    -- 1時間間隔、8日保存の例(デフォルト)
    -- SNAP_INTERVAL                  RETENTION
    -- ------------------------------ ------------------------------
    -- +00000 01:00:00.0              +00008 00:00:00.0

-- 変更 15分間隔 14日保存の例 単位は分
exec DBMS_WORKLOAD_REPOSITORY.MODIFY_SNAPSHOT_SETTINGS(interval => 15, retention => 20160);
select snap_interval, retention from DBA_HIST_WR_CONTROL;

    -- SNAP_INTERVAL                  RETENTION
    -- ------------------------------ ------------------------------
    -- +00000 00:15:00.0              +00014 00:00:00.0
```

### レポートの作成

```sql
@?/rdbms/admin/awrrpt.sql
```

実行例
```
SQL> @?/rdbms/admin/awrrpt.sql
2024-02-07 01:59:20.744 
Specify the Report Type
~~~~~~~~~~~~~~~~~~~~~~~
AWR reports can be generated in the following formats.  Please enter the
name of the format at the prompt.  Default value is 'html'.
2024-02-07 01:59:20.767 
'html'          HTML format (default)
'text'          Text format
'active-html'   Includes Performance Hub active report
2024-02-07 01:59:20.817 
report_typeに値を入力してください: html ★
旧   1: select 'Type Specified: ',lower(nvl('&&report_type','html')) report_type from dual
新   1: select 'Type Specified: ',lower(nvl('html','html')) report_type from dual
2024-02-07 02:07:11.512 
Type Specified:  html
2024-02-07 02:07:11.512 
旧   1: select '&&report_type' report_type_def from dual
新   1: select 'html' report_type_def from dual
2024-02-07 02:07:11.512 
2024-02-07 02:07:11.512 
2024-02-07 02:07:11.516 
旧   1: select '&&view_loc' view_loc_def from dual
新   1: select 'AWR_PDB' view_loc_def from dual
2024-02-07 02:07:11.520 
2024-02-07 02:07:11.520 
2024-02-07 02:07:11.522 
Current Instance
~~~~~~~~~~~~~~~~
DB Id          DB Name        Inst Num       Instance       Container Name
-------------- -------------- -------------- -------------- --------------
 1671612288     ORCL                        1 orcl           orcl
2024-02-07 02:07:11.525 
2024-02-07 02:07:11.525 
2024-02-07 02:07:11.526 
2024-02-07 02:07:11.526 
2024-02-07 02:07:11.527 
2024-02-07 02:07:11.527 
2024-02-07 02:07:11.529 
2024-02-07 02:07:11.529 
2024-02-07 02:07:11.529 
Instances in this Workload Repository schema
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  DB Id      Inst Num   DB Name      Instance     Host
------------ ---------- ---------    ----------   ------
* 1671612288     1      ORCL         orcl         syslog.local
2024-02-07 02:07:11.534 
Using 1671612288 for database Id
Using          1 for instance number
2024-02-07 02:07:11.536 
2024-02-07 02:07:11.536 
Specify the number of days of snapshots to choose from
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
Entering the number of days (n) will result in the most recent
(n) days of snapshots being listed.  Pressing <return> without
specifying a number lists all completed snapshots.
2024-02-07 02:07:11.542 
2024-02-07 02:07:11.543 
num_daysに値を入力してください: 2 ★ スナップショット一覧を表示する日数を入力
2024-02-07 02:07:15.516 
Listing the last 2 days of Completed Snapshots
Instance     DB Name      Snap Id       Snap Started    Snap Level
------------ ------------ ---------- ------------------ ----------
2024-02-07 02:07:15.518 
orcl         ORCL              1637  06 2月  2024 00:00   1
    :
    :
                               1662  07 2月  2024 01:00   1
                               1663  07 2月  2024 01:39   1
                               1664  07 2月  2024 02:00   1
2024-02-07 02:07:15.634 
2024-02-07 02:07:15.637 
Specify the Begin and End Snapshot Ids
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
begin_snapに値を入力してください: 1663 ★解析するスナップショットの開始番号を入力
Begin Snapshot Id specified: 1663
2024-02-07 02:07:26.270 
end_snapに値を入力してください: 1664 ★解析するスナップショットの終了番号を入力
End   Snapshot Id specified: 1664
2024-02-07 02:07:28.524 
2024-02-07 02:07:28.525 
2024-02-07 02:07:28.525 
Specify the Report Name
~~~~~~~~~~~~~~~~~~~~~~~
The default report file name is awrrpt_1_1663_1664.html.  To use this name,
press <return> to continue, otherwise enter an alternative.
2024-02-07 02:07:28.532 
report_nameに値を入力してください: ★レポートのファイル名を入力(ブランクの場合、デフォルトの名前が使われる)
2024-02-07 02:07:30.198 
Using the report name awrrpt_1_1663_1664.html
2024-02-07 02:07:34.264 
<html lang="en"><head><title>AWR Report for DB: ORCL, Inst: orcl, Snaps: 1663-1664</title>
    :
    :
Report written to awrrpt_1_1654_1655.html

SQL>
```


export NLS_LANG=Japanese_Japan.AL32UTF8
export NLS_DATE_FORMAT='YYYY-MM-DD HH24:MI:SS'
export NLS_TIMESTAMP_FORMAT='YYYY-MM-DD HH24:MI:SS.FF'

## テーブル統計情報

OralceのサンプルスキーマHRでの確認例

[ALL_TAB_STATISTICS](https://docs.oracle.com/cd/F19136_01/refrn/ALL_TAB_STATISTICS.html#GUID-C567F729-3748-4DFE-A22C-115CB7575D63)

### 確認

```sql
-- 表示変更
set pages 1000
set lines 200
col owner for a30
col table_name for a30
col index_name for a30
col last_analyzed for a30
col stats_update_time for a40
ALTER SESSION SET nls_date_format = 'YYYY/MM/DD HH24:MI:SS';

--確認
SELECT owner, table_name, stattype_locked, last_analyzed, stale_stats, num_rows
FROM dba_tab_statistics
WHERE owner = 'HR'
ORDER BY table_name;
```
 
確認結果例:
```
OWNER                          TABLE_NAME                       NUM_ROWS STATT LAST_ANALYZED                  STALE_S
------------------------------ ------------------------------ ---------- ----- ------------------------------ -------
HR                             COUNTRIES                              25       2024/04/02 15:59:43            NO
HR                             DEPARTMENTS                            27       2024/04/02 15:59:43            NO
HR                             EMPLOYEES                             107       2024/04/02 15:59:44            NO
    :
```
- stattype_locked: 統計情報がロックされているか(ロックされている場合、ALLなどが表示される)
- last_analyzed: 統計の最終取得日時
- stale_stats: 統計情報が無効かどうか(最後に取得した時点から10%ほど変動があるとYESになる)


### 取得

```sql
SET SERVEROUTPUT ON
DECLARE
    CURSOR c_table IS SELECT owner, table_name FROM dba_tab_statistics WHERE owner = 'HR';
BEGIN 
    FOR r_table IN c_table LOOP
        DBMS_OUTPUT.PUT_LINE(r_table.table_name ||' の処理を実施');
        DBMS_STATS.GATHER_TABLE_STATS(ownname => r_table.owner, tabname => r_table.table_name);
    END LOOP;
END;
/
```

確認すると、LAST_ANALYZEDが実行日次になっている
```text
OWNER                          TABLE_NAME                       NUM_ROWS STATT LAST_ANALYZED                  STALE_S
------------------------------ ------------------------------ ---------- ----- ------------------------------ -------
HR                             COUNTRIES                              25       2024/05/31 00:14:11            NO
HR                             DEPARTMENTS                            27       2024/05/31 00:14:12            NO
HR                             EMPLOYEES                             107       2024/05/31 00:14:12            NO
```

### 削除

```sql
SET SERVEROUTPUT ON
DECLARE
    CURSOR c_table IS SELECT owner, table_name FROM dba_tab_statistics WHERE owner = 'HR';
BEGIN 
    FOR r_table IN c_table LOOP
        DBMS_OUTPUT.PUT_LINE(r_table.table_name ||' の処理を実施');
        DBMS_STATS.DELETE_TABLE_STATS(ownname => r_table.owner, tabname => r_table.table_name);
    END LOOP;
END;
/
```

確認結果：
```text
OWNER                          TABLE_NAME                       NUM_ROWS STATT LAST_ANALYZED                  STALE_S
------------------------------ ------------------------------ ---------- ----- ------------------------------ -------
HR                             COUNTRIES
HR                             DEPARTMENTS
HR                             EMPLOYEES
    :
```

## インデックス統計情報

### 確認

テーブルを更新する際に、一緒に更新されている場合がある

各列の詳細: [ALL_IND_STATISTICS](https://docs.oracle.com/cd/F19136_01/refrn/ALL_IND_STATISTICS.html)


```sql
-- 表示変更
set pages 1000
set lines 200
col owner for a30
col table_name for a30
col index_name for a30
col last_analyzed for a30
col stats_update_time for a40
ALTER SESSION SET nls_date_format = 'YYYY/MM/DD HH24:MI:SS';

-- 確認
SELECT owner, index_name, table_name, stattype_locked, last_analyzed, stale_stats,  blevel
FROM dba_ind_statistics
WHERE owner= 'HR'
ORDER BY index_name;
```

```text
OWNER                          INDEX_NAME                     TABLE_NAME                     STATT LAST_ANALYZED                  STA
------------------------------ ------------------------------ ------------------------------ ----- ------------------------------ ---
HR                             COUNTRY_C_ID_PK                COUNTRIES                            2024/04/02 15:59:43            NO
HR                             DEPT_ID_PK                     DEPARTMENTS                          2024/04/02 15:59:44            NO
HR                             DEPT_LOCATION_IX               DEPARTMENTS                          2024/04/02 15:59:43            NO
    :
```

### 取得

```sql
SET SERVEROUTPUT ON
DECLARE
    CURSOR c_index IS SELECT owner, index_name FROM dba_ind_statistics WHERE owner = 'HR';
BEGIN
    FOR r_index IN c_index LOOP
        DBMS_OUTPUT.PUT_LINE(r_index.index_name ||' の処理を実施');
        DBMS_STATS.GATHER_INDEX_STATS(ownname => r_index.owner, indname => r_index.index_name);
    END LOOP;
END;
/
```

```text
OWNER                          INDEX_NAME                     TABLE_NAME                     STATT LAST_ANALYZED                  STA
------------------------------ ------------------------------ ------------------------------ ----- ------------------------------ ---
HR                             COUNTRY_C_ID_PK                COUNTRIES                            2024/05/31 00:21:46
HR                             DEPT_ID_PK                     DEPARTMENTS                          2024/05/31 00:21:46
HR                             DEPT_LOCATION_IX               DEPARTMENTS                          2024/05/31 00:21:46
    :
```

### 削除

```sql
SET SERVEROUTPUT ON
DECLARE
    CURSOR c_index IS SELECT owner, index_name FROM dba_ind_statistics WHERE owner = 'HR';
BEGIN
    FOR r_index IN c_index LOOP
        DBMS_OUTPUT.PUT_LINE(r_index.index_name ||' の処理を実施');
        DBMS_STATS.DELETE_INDEX_STATS (ownname => r_index.owner, indname => r_index.index_name);
    END LOOP;
END;
/
```

```text
OWNER                          INDEX_NAME                     TABLE_NAME                     STATT LAST_ANALYZED                  STA
------------------------------ ------------------------------ ------------------------------ ----- ------------------------------ ---
HR                             COUNTRY_C_ID_PK                COUNTRIES
HR                             DEPT_ID_PK                     DEPARTMENTS
HR                             DEPT_LOCATION_IX               DEPARTMENTS
    :
```

### INDEX_STATS

前回のANALYZE INDEX ... VALIDATE STRUCTURE文の情報を表示する。

[津島博士のパフォーマンス講座　 第6回　パフォーマンスの基礎である索引について 2011.04.20公開](https://blogs.oracle.com/otnjp/post/tsushima-hakushi-6)  
> HEIGHT が4以上でDEL_LF_ROW/LF_ROWSが0.2を超える場合は効率が悪いので、索引の再構築を行うことを検討して下さい。

19ではALANYZ文が非推奨だが、INDEX_STATSのドキュメントにはINDEX_STATSを使用するためにはANALYZE INDEXしてねと書いてある。  
[INDEX_STATS](https://docs.oracle.com/cd/F19136_01/refrn/INDEX_STATS.html)
> INDEX_STATSは、前回のANALYZE INDEX ... VALIDATE STRUCTURE文の情報を示します。

```sql
-- 解析
ANALYZE INDEX INDEX名 VALIDATE STRUCTURE;

-- 確認
col name for a30
SELECT name, height, lf_rows, del_lf_rows, del_lf_rows / lf_rows AS del_lf_ratio FROM index_stats;
```

一気に確認する用
```sql
SET SERVEROUTPUT ON
DECLARE
    CURSOR c_index IS SELECT owner, index_name FROM dba_ind_statistics WHERE owner = 'HR' ORDER BY owner, index_name;
    v_name VARCHAR2(40);
    v_height NUMBER;
    v_lf_rows NUMBER;
    v_del_lf_rows NUMBER;
    v_del_lf_ratio NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE(RPAD('NAME', 30) || RPAD('HEIGHT', 10) || RPAD('LF ROWS', 10) || RPAD('DEL LF ROWS', 15) || 'DEL LF RATIO');
    DBMS_OUTPUT.PUT_LINE(RPAD('-', 30, '-') || RPAD('-', 10, '-') || RPAD('-', 10, '-') || RPAD('-', 15, '-') || '-------------');
    
    FOR r_index IN c_index LOOP
        BEGIN
            EXECUTE IMMEDIATE 'ANALYZE INDEX ' || r_index.owner || '.' || r_index.index_name || ' VALIDATE STRUCTURE';

            BEGIN
                EXECUTE IMMEDIATE 'SELECT name, height, lf_rows, del_lf_rows, 
                                  CASE 
                                    WHEN lf_rows = 0 THEN -1 
                                    ELSE del_lf_rows / lf_rows 
                                  END AS del_lf_ratio 
                                  FROM index_stats' 
                INTO v_name, v_height, v_lf_rows, v_del_lf_rows, v_del_lf_ratio;
                
                DBMS_OUTPUT.PUT_LINE(RPAD(v_name, 30) || 
                                     RPAD(v_height, 10) || 
                                     RPAD(v_lf_rows, 10) || 
                                     RPAD(v_del_lf_rows, 15) || 
                                     TO_CHAR(v_del_lf_ratio, '0.0000'));
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    -- If no data found, output only the name
                    DBMS_OUTPUT.PUT_LINE(RPAD(r_index.index_name, 30) || RPAD(' ', 10) || RPAD(' ', 10) || RPAD(' ', 15) || ' ');
            END;
        EXCEPTION
            WHEN OTHERS THEN
                -- Handle other exceptions if necessary
                DBMS_OUTPUT.PUT_LINE('Error analyzing index ' || r_index.index_name || ': ' || SQLERRM);
        END;
    END LOOP;
END;
/
```

## SQLチューニングアドバイザ

EMではなくSQL Plusで実行する方法

```sql
-- チューニングタスクの登録
var w_task_name VARCHAR2(255) ;
BEGIN
    :w_task_name := DBMS_SQLTUNE.CREATE_TUNING_TASK(
    task_name => 'SAMPLE_TASK',
    -- スナップショットから拾う場合は以下
    -- begin_snap => <開始のスナップショット番号> ,
    -- end_snap => <終了ののスナップショット番号> , 
    sql_id => '対象のsql_id' ) ;
END;
/

-- チューニングタスクの実行
BEGIN
    DBMS_SQLTUNE.EXECUTE_TUNING_TASK(
    task_name => :w_task_name);
END ;
/

-- アドバイザの表示
set long 100000
set longchunksize 100000
set linesize 200
set pages 50000
SELECT DBMS_SQLTUNE.REPORT_TUNING_TASK(:w_task_name) FROM DUAL ;

-- チューニングタスクの削除
EXECUTE DBMS_SQLTUNE.DROP_TUNING_TASK(:w_task_name );
```