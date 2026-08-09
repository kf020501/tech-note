ASH(Active Session History)
================================================================================


v$session
------------------------------------------------------------

```sql
set line 200
col username format a20
col event format a80
select SID, SERIAL#, USER#, USERNAME, STATUS, EVENT from v$session;
```


DBA_HIST_ACTIVE_SESS_HISTORY
------------------------------------------------------------

10秒ごとのセッション情報を確認可能なデータディクショナリビュー。  
それほど細かくないが、インスタンス再起動後も確認可能。(初期値は8日保尊)  

[DBA_HIST_ACTIVE_SESS_HISTORY](https://docs.oracle.com/cd/F19136_01/refrn/DBA_HIST_ACTIVE_SESS_HISTORY.html)

```sql
set line 200
col sample_time format a30

SELECT sample_time, session_id, session_serial#, event
    FROM dba_hist_active_sess_history
    ORDER BY sample_time;
```

CSVに出力する場合
```sql
-- 出力をcsv形式に、不要なものは表示しない
SET MARKUP CSV ON
SET FEEDBACK OFF ECHO OFF
set termout off

-- spool開始
SPOOL /home/oracle/dba_hist_active_sess_history.csv

-- ここで任意のコマンドを実行 以下の例はユーザー一覧
select 
    sample_time,
    session_id,
    session_serial#,
    event,
    seq#,
    sql_id,
    program,
    machine,
    blocking_session,
    blocking_session_serial#
from dba_hist_active_sess_history
order by sample_time ;

-- 終了処理
SPOOL OFF;
SET FEEDBACK ON ECHO ON
EXIT
```

shellから直接
```sh
sqlplus -s -M 'CSV ON' / as sysdba << __EOF__ | sed '/^$/d' > dba_hist_active_sess_history_$(date +%Y%m%d_%H%M%S).csv
set feedback off
ALTER SESSION SET NLS_TIMESTAMP_FORMAT='yy-mm-dd hh24:mi:ss.ff3';
select 
    sample_time,
    session_id,
    session_serial#,
    event,
    seq#,
    sql_id,
    program,
    machine,
    blocking_session,
    blocking_session_serial#
from dba_hist_active_sess_history
order by sample_time ;
__EOF__

sqlplus -s -M 'CSV ON' / as sysdba << __EOF__ | sed '/^$/d' > dba_hist_active_sess_history_all_$(date +%Y%m%d_%H%M%S).csv
set feedback off
ALTER SESSION SET NLS_TIMESTAMP_FORMAT='yy-mm-dd hh24:mi:ss.ff3';
select *
from dba_hist_active_sess_history
order by sample_time ;
__EOF__
```

v$active_session_history
------------------------------------------------------------

[V$ACTIVE_SESSION_HISTORY](https://docs.oracle.com/cd/F19136_01/refrn/V-ACTIVE_SESSION_HISTORY.html)

- リアルタイムのアクティブセッションのデータを保持する動的パフォーマンスビュー
- 1秒間隔で取得されるセッション情報を提供
- 現在進行中のパフォーマンス問題のリアルタイム診断に使用する
- メモリ内で保持されるデータであり、一定期間経過後には消去される

```sql
set line 200
column sample_time format a30

SELECT sample_time, session_id, session_serial#, event
FROM v$active_session_history
ORDER BY sample_time;
```


ASHレポート
------------------------------------------------------------

```sql
@?/rdbms/admin/ashrpt.sql
```