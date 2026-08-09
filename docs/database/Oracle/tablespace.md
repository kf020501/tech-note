表領域
================================================================================


データファイルの確認
--------------------------------------------------------------------------------

DBA_DATA_FILES 静的データ・ディクショナリ・ビューで確認する。

```sql
SET linesize 200;
COLUMN FILE_NAME FORMAT a80;

SELECT file_name,
       tablespace_name,
       autoextensible,
       TO_CHAR(bytes / 1024 / 1024, '999,999.9') AS size_mb,
       TO_CHAR(maxbytes / 1024 / 1024, '999,999.9') AS max_size_mb,
       TO_CHAR(bytes / maxbytes * 100, '999.9')  AS usage_per
FROM dba_data_files;
```
実行結果例
```
FILE_NAME                                                                        TABLESPACE_NAME                AUT SIZE_MB    MAX_SIZE_M USAGE_
-------------------------------------------------------------------------------- ------------------------------ --- ---------- ---------- ------
/opt/oracle/oradata/ORCL/datafile/o1_mf_system_m0mqsj7r_.dbf                     SYSTEM                         YES      950.0   32,768.0    2.9
/opt/oracle/oradata/ORCL/datafile/o1_mf_sysaux_m0mqt9bk_.dbf                     SYSAUX                         YES    1,420.0   32,768.0    4.3
/opt/oracle/oradata/ORCL/datafile/o1_mf_undotbs1_m0mqtrdt_.dbf                   UNDOTBS1                       YES   17,840.0   32,768.0   54.4
/opt/oracle/oradata/ORCL/datafile/o1_mf_users_m0mqtsgq_.dbf                      USERS                          YES        5.0   32,768.0     .0
/opt/oracle/oradata/ORCL/datafile/o1_mf_sample_m0qc6ntx_.dbf                     SAMPLE                         YES      400.0   32,768.0    1.2
/opt/oracle/oradata/ORCL/datafile/o1_mf_usertbs_m102771w_.dbf                    USERTBS                        YES   32,768.0   32,768.0  100.0
/opt/oracle/oradata/ORCL/datafile/o1_mf_usertbs_mw5vzk59_.dbf                    USERTBS                        YES    1,620.0   32,768.0    4.9
```

表領域の拡張
--------------------------------------------------------------------------------

```sql
ALTER TABLESPACE <表領域名>
  ADD DATAFILE '<データファイルのパス>'
  SIZE 10M
  AUTOEXTEND ON
  MAXSIZE UNLIMITED;
```

表領域使用率の確認
--------------------------------------------------------------------------------

よいSQL検討中

```sql
SET linesize 200;
COLUMN FILE_NAME FORMAT a80;

SELECT tablespace_name,
       TO_CHAR(SUM(bytes) / 1024 / 1024, '999,999.9') AS size_mb,
       TO_CHAR(SUM(maxbytes) / 1024 / 1024, '999,999.9') AS max_size_mb,
       TO_CHAR(SUM(bytes) / SUM(maxbytes) * 100, '999.9')  AS usage_per
FROM dba_data_files
GROUP BY tablespace_name;
```