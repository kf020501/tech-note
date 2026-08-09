
# 自動診断リポジトリ(ADR)

Automatic Diagnostic Repository（ADR）は、トレースファイル、インシデントダンプ、アラートログなどを集中管理する。    
ADRの実体は、あるディレクトリ以下にある、階層構造で整理されたファイルの集合体。     
このため、DBが動作していなくとも参照可能。


## 階層構造

diagnostic_dest初期化パラメータによってADR_BASEが設定される。

```sql
show parameter diagnostic_dest

-- 実行結果
-- NAME                                 TYPE        VALUE
-- ------------------------------------ ----------- ------------------------------
-- diagnostic_dest                      string      /u01/app/oracle
```

```
ADR_BASEの初期値(初期値は$ORACLE_BASE)
└── diag
    ├── asm         ASM関連のログ
    ├── clients     Orcle Client関連のログ
    ├── tnslsnr     リスナー関連のログ
    └── rdbms
        └── orcl
            └── orcl ★ 自動診断リポジトリ(ADR)HOME
                    ├── alert    XMK形式のアラート
                    ├── cdump    コアダンプ
                    ├── hm       ヘルスモニタの結果
                    ├── incident インシデントダンプ
                    ├── incpkg   インシデントパッケージ
                    ├── ir       データリカバリアドバイザーの修復スクリプト
                    ├── trace    テキスト形式のアラートログ、トレースファイル
                    ｜  └── alert_orcl.log ★とりあえず見る
                    ：
```


## v$diag_info ビュー

ADR関連ディレクトリのパスなどを確認

```sql
set line 200;
column NAME format a20;
column value format a80;
select name, value from v$diag_info;
```

| NAME                  | VALUE(検証環境での値)                                          | 説明                                                           |
| --------------------- | -------------------------------------------------------------- | -------------------------------------------------------------- |
| Diag Enabled          | TRUE                                                           | ADRが有効かどうか                                              |
| ADR Base              | /u01/app/oracle                                                | ADRのベースディレクトリ                                        |
| ADR Home              | /u01/app/oracle/diag/rdbms/orcl/orcl                           | ADRのホームディレクトリ(インスタンス単位)                      |
| Diag Trace            | /u01/app/oracle/diag/rdbms/orcl/orcl/trace                     | テキスト形式のアラートログ、トレースファイルの場所             |
| Diag Alert            | /u01/app/oracle/diag/rdbms/orcl/orcl/alert                     | XML形式のアラートログの場所                                    |
| Diag Incident         | /u01/app/oracle/diag/rdbms/orcl/orcl/incident                  | インシデントダンプファイルの場所                               |
| Diag Cdump            | /u01/app/oracle/diag/rdbms/orcl/orcl/cdump                     | コアダンプファイルの場所                                       |
| Health Monitor        | /u01/app/oracle/diag/rdbms/orcl/orcl/hm                        | ヘルスモニターの結果ファイルの場所                             |
| Default Trace File    | /u01/app/oracle/diag/rdbms/orcl/orcl/trace/orcl_ora_824634.trc | 現在のセッションで作成されるユーザートレースファイルへのパス   |
| Active Problem Count  | 0                                                              | インスタンスのアクティブな問題の数(類似インシデントグループ化) |
| Active Incident Count | 0                                                              | インスタンスのアクティブな問題の数(致命的エラー)               |
| ORACLE_HOME           | /u01/app/oracle/product/19.3.0/dbhome_1                        | Oracleホームディレクトリ                                       |


## adrciコマンド

エディタなどでも確認できるが、このコマンドでも調査可能。

実行例
```text
[oracle@syslog ~]$ adrci

ADRCI: Release 19.0.0.0.0 - Production on Sun Aug 20 12:38:13 2023

Copyright (c) 1982, 2019, Oracle and/or its affiliates.  All rights reserved.

ADR base = "/u01/app/oracle"
adrci> 
adrci> show problem ★現在発生している問題を一覧表示(類似インシデントグループ化)

ADR Home = /u01/app/oracle/diag/rdbms/orcl/orcl:
*************************************************************************
PROBLEM_ID           PROBLEM_KEY                                                 LAST_INCIDENT        LASTINC_TIME                             
-------------------- ----------------------------------------------------------- -------------------- ---------------------------------------- 
1                    ORA 600 [ksb_shut_detached_process3]                        41065                2023-08-20 12:06:13.748000 +09:00       

ADR Home = /u01/app/oracle/diag/tnslsnr/syslog/listener:
*************************************************************************
0 rows fetched

adrci> 
adrci> show incident ★現在発生している致命的な問題を一覧表示(類似インシデントグループ化)

ADR Home = /u01/app/oracle/diag/rdbms/orcl/orcl:
*************************************************************************
INCIDENT_ID          PROBLEM_KEY                                                 CREATE_TIME                              
-------------------- ----------------------------------------------------------- ---------------------------------------- 
41065                ORA 600 [ksb_shut_detached_process3]                        2023-08-20 12:06:13.748000 +09:00       

ADR Home = /u01/app/oracle/diag/tnslsnr/syslog/listener:
*************************************************************************
0 rows fetched

adrci> 
adrci> show alert ★アラートログをエディタで表示

Choose the home from which to view the alert log:

1: diag/rdbms/orcl/orcl
2: diag/tnslsnr/syslog/listener
Q: to quit

Please select option: 
```

インシデントをクローズする場合、`PURGE -i <incident_id>`を実行する。    
実行前にADRホームの指定が必要。

```
adrci> SHOW HOMES ★ ADR HOME一覧確認
ADR Homes: 
diag/rdbms/orcl/orcl ★ 
diag/tnslsnr/syslog/listener
adrci> 
adrci> 
adrci> SET HOME diag/rdbms/orcl/orcl ★ HOME指定
adrci> SHOW INCIDENT ★ incident_id確認

ADR Home = /u01/app/oracle/diag/rdbms/orcl/orcl:
*************************************************************************
INCIDENT_ID          PROBLEM_KEY                                                 CREATE_TIME                              
-------------------- ----------------------------------------------------------- ---------------------------------------- 
41065                ORA 600 [ksb_shut_detached_process3]                        2023-08-20 12:06:13.748000 +09:00       
1 row fetched

adrci> 
adrci> PURGE -i 41065 ★ 削除
adrci> 
adrci> SHOW INCIDENT ★ 削除された事を確認

ADR Home = /u01/app/oracle/diag/rdbms/orcl/orcl:
*************************************************************************
0 rows fetched

adrci> 
```