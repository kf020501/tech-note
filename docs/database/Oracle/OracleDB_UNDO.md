---
title: "Oracle UNDO表領域 設定変更"
tags: ["memo"]
date: 2022-08-21
weight: 100
draft: false
---

## 自動UNDO ---> ロールバックセグメント

ざっくり流れ

1. ロールバックセグメント用の表領域を作成 `CREATE TABLESPACE 表領域名 DATAFILE '表領域パス.dbf' size xxM;`
2. ロールバックセグメントを表領域上に指定 `CREATE ROLLBACK SEGMENT rbs_1 TABLESPACE 表領域名;`
3. 手動UNDO管理に変更 `ALTER SYSTEM SET UNDO_MANAGEMENT = 'MANUAL' scope=spfile;`
4. DB再起動
   
```sh
# 保存先作成
sudo mkdir -p /database/orcl/UNDO
sudo chown -R oracle.oinstall /database/

# orclデータベースにアクセス
export ORACLE_SID=orcl
sqlplus / as sysdba
```
```sql
-- 現在の UNDO_NAMAGEMENT を確認 AUTOなら自動UNDO, MANUALなら ロールバックセグメント
show parameter undo_management;
    -- NAME                                 TYPE        VALUE
    -- ------------------------------------ ----------- ------------------------------
    -- undo_management                      string      AUTO    ★ 自動UNDO
SHOW PARAMETER UNDO

-- 作業前の表領域の一覧を取得 (どれが過不足ない？)
COLUMN FILE_NAME FORMAT a100;
SELECT * FROM DBA_DATA_FILES;
SELECT FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES;

SELECT * FROM dba_tablespaces;
SELECT TABLESPACE_NAME, CONTENTS FROM dba_tablespaces;
SELECT TABLESPACE_NAME, CONTENTS FROM dba_tablespaces WHERE CONTENTS='UNDO';

-- ロールバックセグメント用の表領域を作成
CREATE TABLESPACE rbs_test DATAFILE '/database/orcl/UNDO/rbs01.dbf' size 10M;

-- 作成されたか確認
COLUMN FILE_NAME FORMAT a100;
SELECT FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES;
SELECT TABLESPACE_NAME, CONTENTS FROM dba_tablespaces;

-- ロールバック状況確認
SELECT SEGMENT_NAME, TABLESPACE_NAME, STATUS FROM DBA_ROLLBACK_SEGS;

-- ロールバックセグメントを表領域上に作成
CREATE ROLLBACK SEGMENT rbs_1 TABLESPACE rbs_test;

-- 手動UNDO管理にするため、UNDO_MANAGEMENT を MANUAL に変更
alter system set UNDO_MANAGEMENT = 'MANUAL' scope=spfile;

-- 変更を反映するため再起動
shutdown immediate
startup

-- 現在の UNDO_NAMAGEMENT を確認 AUTOなら自動UNDO, MANUALなら ロールバックセグメント
show parameter undo_management;
    -- NAME                                 TYPE        VALUE
    -- ------------------------------------ ----------- ------------------------------
    -- undo_management                      string      MANUAL  ★ ロールバックセグメントになっている

SELECT SEGMENT_NAME, TABLESPACE_NAME, STATUS FROM DBA_ROLLBACK_SEGS;

-- 元のUNDO表領域を削除
COLUMN FILE_NAME FORMAT a100;
SELECT FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES;
SELECT TABLESPACE_NAME, CONTENTS FROM dba_tablespaces;
drop tablespace undotbs1 including contents and datafiles cascade constraints;
SELECT FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES;
SELECT TABLESPACE_NAME, CONTENTS FROM dba_tablespaces;
```

## ロールバックセグメント ---> 自動UNDO

流れ

1. UNDO用の表領域の作成 `CREATE TABLESPACE 表領域名 DATAFILE '表領域パス.dbf' SIZE xxG AUTOEXTEND ON;`
2. UNDO 表領域を切り替え `alter system set undo_tablespace=<新規UNDO表領域名> scope=both;`
3. 手動UNDO管理に変更 `ALTER SYSTEM SET UNDO_MANAGEMENT = 'AUTO' scope=spfile;`
4. DB再起動

```sh
# 保存先ディレクトリを作成(必要に応じて)
mkdir -p /database/orcl/UNDO

# orclデータベースにアクセス
export ORACLE_SID=orcl
sqlplus / as sysdba
```
```sql
------------------------------------------------------------
-- 事前確認
------------------------------------------------------------

-- 現在の UNDO_NAMAGEMENT を確認 AUTOなら自動UNDO, MANUALなら ロールバックセグメント
show parameter undo
      -- NAME                                 TYPE        VALUE
      -- ------------------------------------ ----------- ------------------------------
      -- temp_undo_enabled                    boolean     FALSE
      -- undo_management                      string      MANUAL ★
      -- undo_retention                       integer     900
      -- undo_tablespace                      string      

------------------------------------------------------------
-- UNDO用の表領域の作成
------------------------------------------------------------

-- 事前確認
COLUMN FILE_NAME FORMAT a100;
SELECT FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES;
      -- FILE_NAME                                                                                            TABLESPACE_NAME                AUT
      -- ---------------------------------------------------------------------------------------------------- ------------------------------ ---
      -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_system_k8o1286d_.dbf                                     SYSTEM                         YES
      -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_sysaux_k8o15osf_.dbf                                     SYSAUX                         YES
      -- /database/orcl/UNDO/rbs01.dbf                                                                        RBS_TEST                       NO
      -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_users_k8o165yp_.dbf                                      USERS                          YES

SELECT TABLESPACE_NAME, CONTENTS FROM dba_tablespaces;
      -- TABLESPACE_NAME                CONTENTS
      -- ------------------------------ ---------------------
      -- SYSTEM                         PERMANENT
      -- SYSAUX                         PERMANENT
      -- TEMP                           TEMPORARY
      -- USERS                          PERMANENT
      -- RBS_TEST                       PERMANENT

-- 作成 CREATE TABLESPASE <表領域名> DATAFILE <表領域パス> SIZE <初期サイズ? AUTOEXTEND ON/OFF;
CREATE UNDO TABLESPACE UNDOTBS DATAFILE '/database/orcl/UNDO/undo1.dbf' SIZE 3G AUTOEXTEND ON;

-- 作業後確認
COLUMN FILE_NAME FORMAT a100;
SELECT FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES;
      -- FILE_NAME                                                                                            TABLESPACE_NAME                AUT
      -- ---------------------------------------------------------------------------------------------------- ------------------------------ ---
      -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_system_k8o1286d_.dbf                                     SYSTEM                         YES
      -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_sysaux_k8o15osf_.dbf                                     SYSAUX                         YES
      -- /database/orcl/UNDO/rbs01.dbf                                                                        RBS_TEST                       NO
      -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_users_k8o165yp_.dbf                                      USERS                          YES
      -- /database/orcl/UNDO/undo1.dbf ★追加されている                                                       UNDOTBS                        YES

SELECT TABLESPACE_NAME, CONTENTS FROM dba_tablespaces;
      -- TABLESPACE_NAME                CONTENTS
      -- ------------------------------ ---------------------
      -- SYSTEM                         PERMANENT
      -- SYSAUX                         PERMANENT
      -- TEMP                           TEMPORARY
      -- USERS                          PERMANENT
      -- RBS_TEST                       PERMANENT
      -- UNDOTBS                        UNDO ★ 追加されている

------------------------------------------------------------
-- UNDO_MANAGEMENT = 'AUTO' を設定 など
------------------------------------------------------------

-- AUTOを指定
ALTER SYSTEM SET UNDO_MANAGEMENT = 'AUTO' scope=spfile;

-- UNDO表領域に 作成した表領域(UNDOTBS) を指定
ALTER SYSTEM SET UNDO_TABLESPACE = 'UNDOTBS' SCOPE=spfile;

-- この時点では変更されていない？
show parameters dest undo

-- -- undo_tablespace 確認
-- COLUMN VALUE FORMAT a40;
-- COLUMN DISPLAY_VALUE FORMAT a40;
-- SELECT NAME, VALUE, DISPLAY_VALUE FROM v$parameter WHERE NAME = 'undo_tablespace';

------------------------------------------------------------
-- 再起動 ---> 起動後確認
------------------------------------------------------------

shutdown immediate
startup nomount

-- 現在の UNDO_NAMAGEMENT を確認 AUTOなら自動UNDO, MANUALなら ロールバックセグメント
show parameter undo
      -- NAME                                 TYPE        VALUE
      -- ------------------------------------ ----------- ------------------------------
      -- temp_undo_enabled                    boolean     FALSE
      -- undo_management                      string      AUTO ★ UNDOになっている
      -- undo_retention                       integer     900
      -- undo_tablespace                      string      UNDOTBS ★ 作成した表領域になっている

------------------------------------------------------------
-- 元の表領域を削除
------------------------------------------------------------
-- 実施前 確認
COLUMN FILE_NAME FORMAT a100;
SELECT FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES;
SELECT TABLESPACE_NAME, CONTENTS FROM dba_tablespaces;
-- 削除  DROP TABLESPACE <TABLESPACE_NAME> INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;
DROP TABLESPACE RBS_TEST INCLUDING CONTENTS AND DATAFILES CASCADE CONSTRAINTS;
-- 実施後 確認
SELECT FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES;
SELECT TABLESPACE_NAME, CONTENTS FROM dba_tablespaces;
```

## 参考


- [RBSとUNDOセグメントの違い](https://blogs.oracle.com/otnjp/post/tsushima-hakushi-19)
- [ロールバック・セグメントから自動UNDOモードへの移行](https://docs.oracle.com/cd/F19136_01/spuss/migrating-from-rollback-segments-to-automatic-undo-mode.html#GUID-7BBB2D85-E8FB-437B-BA21-6D08A04BB7AE)
- [[Oracle] UNDO表領域を再作成する方法 | Libproc](https://libproc.com/oracle-undo-recreate/)
- [自動UNDO管理から手動UNDO管理に変更したときの作業ログ - artz’s blog](https://artz.hatenadiary.com/entry/2021/01/14/233149)
- [Oracle 自動 UNDO 管理を使用している UNDO 表領域の変更、再作成方法 | Oracle与MySQL数据库修复和数据恢复服务 服务热线：13764045638](https://www.parnassusdata.com/zh-hans/node/531)
- [UNDOの管理](https://docs.oracle.com/cd/E16338_01/server.112/b56301/undo.htm)
  