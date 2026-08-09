Oracle 19c NOTE
========================================

公式ドキュメント
----------------------------------------

- [Oracle Database Documentation - Oracle Database](https://docs.oracle.com/en/database/oracle/oracle-database/index.html)
- [Oracle Databaseデータベース・リファレンス, 19c](https://docs.oracle.com/cd/F19136_01/refrn/)


表示変更
----------------------------------------

### 日本語表示

```sh
export NLS_LANG=Japanese_Japan.AL32UTF8
```

### 日付フォーマット

```sh
export NLS_DATE_FORMAT='yyyy-mm-dd hh24:mi:ss'
```

### 列幅など

```
set line 200;
column MEMBER format a80;
```

### 区切り文字

```
set colsep |
```

### 実行結果をCSVで表示

`SET MARKUP CSV ON`をすることで、実行結果がcsvとなる。

```sql
-- 出力をcsv形式に
SET MARKUP CSV ON

-- 不要なものは表示しない
SET FEEDBACK OFF ECHO OFF
set termout off

-- spool開始
SPOOL /home/oracle/dba_tables.csv

-- ここで任意のコマンドを実行 以下の例はユーザー一覧
select * from dba_tables where owner = 'DBUSER';

-- 終了処理
SPOOL OFF;
SET FEEDBACK ON ECHO ON
EXIT
```

何か余計な表示が入る。。  
もっとよくできないかな？



### 実行結果をhtmlで出力

`SET MARKUP HTML ON`をすることで、実行結果がhtmlとなる。

```sql
-- 出力をhtml形式に
SET MARKUP HTML ON;
-- 必要に応じてページサイズ(区切り行数)変更
SET pagesize 10000;

-- 実行したコマンド自体もspoolされるように
SET ECHO ON

-- ファイル名を作成してスプールを開始
COLUMN dt NEW_VALUE dt_var
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS"_spooltest.html"') AS dt FROM DUAL;
SPOOL /home/oracle/&dt_var

-- ここで任意のコマンドを実行 以下の例はユーザー一覧
SELECT USERNAME, DEFAULT_COLLATION FROM dba_users;

-- 終了処理
SPOOL OFF;
SET MARKUP HTML OFF;
EXIT
```

<table border='1' width='90%' align='center' summary='Script output'>
<tr><th scope="col">USERNAME</th><th scope="col">DEFAULT_COLLATION</th></tr>
<tr><td>SYS</td><td>USING_NLS_COMP</td></tr>
<tr><td>SYSTEM</td><td>USING_NLS_COMP</td></tr>
</table>
以下略


確認: 動的パフォーマンスビュー(v$xxx)
----------------------------------------

データベースの内部パフォーマンスカウンター、状態、およびメトリックへのウィンドウを提供。

```
$v$session
$v$instance
$v$parameter
```


### 現在のインスタンス

```sql
SELECT instance_name, status FROM v$instance;

-- INSTANCE_NAME    STATUS
-- ---------------- ------------
-- orcl             OPEN
```

### 初期化パラメータの確認

`show parameter <パラメータ名>` で確認

```sql
-- ADRの確認
show parameter diagnostic_dest
```

### REDOログ系

```sql
set line 200;
SELECT * FROM V$LOG;

    --     GROUP#    THREAD#  SEQUENCE#      BYTES  BLOCKSIZE    MEMBERS ARC STATUS           FIRST_CHANGE# FIRST_TIME          NEXT_CHANGE# NEXT_TIME               CON_ID
    -- ---------- ---------- ---------- ---------- ---------- ---------- --- ---------------- ------------- ------------------- ------------ ------------------- ----------
    --          1          1         34  209715200        512          2 YES INACTIVE               2588438 2024-03-24 03:53:44      2588905 2024-03-24 04:01:08          0
    --          2          1         35  209715200        512          2 YES INACTIVE               2588905 2024-03-24 04:01:08      2588934 2024-03-24 04:01:12          0
    --          3          1         36  209715200        512          2 NO  CURRENT                2588934 2024-03-24 04:01:12   1.8447E+19                              0

column MEMBER format a80;
SELECT * FROM V$LOGFILE;

    --     GROUP# STATUS  TYPE    MEMBER                                                                           IS_     CON_ID
    -- ---------- ------- ------- -------------------------------------------------------------------------------- --- ----------
    --          3         ONLINE  /u01/app/oracle/oradata/ORCL/onlinelog/o1_mf_3_lzjzhmpp_.log                     NO           0
    --          3         ONLINE  /u01/app/oracle/fast_recovery_area/ORCL/onlinelog/o1_mf_3_lzjzhotd_.log          YES          0
    --          2         ONLINE  /u01/app/oracle/oradata/ORCL/onlinelog/o1_mf_2_lzjzhmpf_.log                     NO           0
    --          2         ONLINE  /u01/app/oracle/fast_recovery_area/ORCL/onlinelog/o1_mf_2_lzjzhp2n_.log          YES          0
    --          1         ONLINE  /u01/app/oracle/oradata/ORCL/onlinelog/o1_mf_1_lzjzhmp5_.log                     NO           0
    --          1         ONLINE  /u01/app/oracle/fast_recovery_area/ORCL/onlinelog/o1_mf_1_lzjzhpth_.log          YES          0

```

確認: 静的データ・ディクショナリ・ビュー
----------------------------------------

### テーブル

```sql
-- テーブル一覧
set line 200;
column OWNER FORMAT a20
column table_name FORMAT a40
SELECT owner, table_name, tablespace_name FROM dba_tables;
```


### ユーザー

```sql
-- ユーザー一覧表示
set linesize 200;
column USERNAME format a40;
column DEFAULT_COLLATION format a40;
SELECT USERNAME, DEFAULT_COLLATION FROM DBA_USERS ORDER BY username;

    -- USERNAME                                 DEFAULT_COLLATION
    -- ---------------------------------------- ----------------------------------------
    -- ANONYMOUS                                USING_NLS_COMP
    -- APPQOSSYS                                USING_NLS_COMP
    -- AUDSYS                                   USING_NLS_COMP
    -- CTXSYS                                   USING_NLS_COMP
```

### 表領域

```sql
-- 表領域一覧
SELECT TABLESPACE_NAME, CONTENTS FROM DBA_TABLESPACES;

    -- TABLESPACE_NAME                CONTENTS
    -- ------------------------------ ---------------------
    -- SYSTEM                         PERMANENT
    -- SYSAUX                         PERMANENT
    -- UNDOTBS1                       UNDO
    -- TEMP                           TEMPORARY
    -- USERS                          PERMANENT
    -- USERTBS                        PERMANENT

-- データファイル確認
SET linesize 200;
COLUMN FILE_NAME FORMAT a100;
SELECT FILE_NAME, TABLESPACE_NAME, AUTOEXTENSIBLE FROM DBA_DATA_FILES;

    -- FILE_NAME                                                                                            TABLESPACE_NAME                AUT
    -- ---------------------------------------------------------------------------------------------------- ------------------------------ ---
    -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_system_ldo9sb38_.dbf                                     SYSTEM                         YES
    -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_sysaux_ldo9t362_.dbf                                     SYSAUX                         YES
    -- /u01/app/oracle/usertbs.dbf                                                                          USERTBS                        YES
    -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_users_ldo9tmb7_.dbf                                      USERS                          YES
    -- /u01/app/oracle/oradata/ORCL/datafile/o1_mf_undotbs1_ldo9tl89_.dbf                                   UNDOTBS1                       YES
```

### 統計情報系

#### 統計情報の自動収集が有効になっているか

```sql
SELECT CLIENT_NAME, STATUS FROM DBA_AUTOTASK_CLIENT WHERE CLIENT_NAME = 'auto optimizer stats collection';
```

STATUS列がENABLEDを返す場合、自動統計情報の収集が有効になっています。DISABLEDを返す場合、有効になっていません。

#### 最後に統計情報が収集された日時の確認

```sql
set line 200

-- テーブル
column OWNER FORMAT a20
column TABLE_NAME FORMAT a40
SELECT OWNER, TABLE_NAME, LAST_ANALYZED FROM DBA_TAB_STATISTICS;

-- インデックス
column OWNER FORMAT a20
column INDEX_NAME FORMAT a40
SELECT OWNER, INDEX_NAME, LAST_ANALYZED FROM DBA_IND_STATISTICS;
```


ディレクト関連
----------------------------------------

### ディレクトリ構造構造

```
$ORACLE_BASE (+ ADR_BASEの初期値)
├── admin
├── audit 
├── cfgtoollogs
├── checkpoints
├── diag
│  ├── asm         ASM関連のログ
│  ├── clients     Orcle Client関連のログ
│  ├── tnslsnr     リスナー関連のログ
│  ├── rdbms
│  │  └── orcl
│  │      └── orcl ★ 自動診断リポジトリ(ADR)HOME
│  │              ├── alert    XMK形式のアラート
│  │              ├── cdump    コアダンプ
│  │              ├── hm       ヘルスモニタの結果
│  │              ├── incident インシデントダンプ
│  │              ├── incpkg   インシデントパッケージ
│  │              ├── ir       データリカバリアドバイザーの修復スクリプト
│  │              ├── trace    テキスト形式のアラートログ、トレースファイル
│  ：              ：
├── fast_recovery_area ★フラッシュリカバリ領域 
│  └── ORCL
│      ├── archivelog   アーカイブログ
│      ├── controlfile  制御ファイル?
│      └── onlinelog    REDOログ
├── oradata ★データベースファイルの保存先
│  └── ORCL
│      ├── controlfile  制御ファイル?
│      ├── datafile     データファイル
│      └── onlinelog    REDOログ
└── product
    └── 19.3.0
        └── dbhome_1 ★$ORACLE_HOME
```

### ディレクトリ関連の設定値

| パスの種類              | 定義場所                  | 説明                                                                     |
| ----------------------- | ------------------------- | ------------------------------------------------------------------------ |
| ORACLE_BASE             | 環) $ORACLE_BASE          | Oracle関連ファイルの基準となるパス。                                     |
| ORACLE_HOME             | 環) $ORACLE_HOME          | Oracleのソフトウェアを配置するパスを指定                                 |
| データベースファイル    | 初) db_create_file_dest   | データベースファイルのデフォルトの作成先を指定                           |
| フラッシュリカバリ領域  | 初) db_recovery_file_dest | リカバリ関連ファイルを一元管理するための領域                             |
| 自動診断リポジトリ(ADR) | 初) diagnostic_dest       | トレースファイル、インシデントダンプ、アラートログなどを集中管理する領域 |

- (環)はOSの環境変数 `echo $環境変数名` で確認
- (初)はOracleの初期化パラメータ `show parameter 初期化パラメータ名` で確認

### /etc/fstab

データファイルを別ディスクに保存する際、fstabのダンプ/チェックはどうすればいいか？  
Chat-GPTに聞いてみたものを要約すると、結論は `0 0`

- ダンプ: ファイルシステムをダンプする必要はないので0がよい。
- チェック: 自動システム修復が意図しないデータの破損を引き起こす可能性があるため、修復やチェックはデータベース管理者による手動での介入が望ましいとされています。

/etc/fstabの例:
```sh
UUID=xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx /opt xfs defaults 0 0
```

メモリ管理系
----------------------------------------

### SGA (System Global Area)


インスタンス起動時に割り当てられるメモリ領域。複数の役割がある(コンポーネント)

| 役割(コンポーネント)     | 説明                                                                                                    |
| ------------------------ | ------------------------------------------------------------------------------------------------------- |
| DBバッファキャッシュ     | ディスク上のデータファイル読み書き時のキャッシュ/バッファ(バッファはDBWnによってファイルに書き込まれる) |
| REDOログバッファ         | そのまま。ログファイルへの書き込みはログライター(LGWR)が行う。                                          |
| 共有プール               | 性能向上のための様々な情報をキャッシュ(解析済みSQL、データディクショナリなど)                           |
| PGA(Program Grobal Area) | 特定のOracleプロセス専用のメモリ領域。プロセス間で共有されない。                                        |
| Javaプール               |                                                                                                         |


### PGA (Program Global Area)

サーバープロセス、バックグラウンドプロセスが使用するメモリ領域。  


 | 名称 | 名称                 | 説明                                                                             |
 | ---- | -------------------- | -------------------------------------------------------------------------------- |
 | DBWn | データベースライター | データベースバッファキャッシュから変更ブロックをログファイルに書き込み。         |
 | LGWR | ログライター         | ディスクにREDOログエントリを書き込みます。                                       |
 | CKPT | チェックポイント     |                                                                                  |
 | SMON | システムモニター     | 障害インスタンスが再開すると、システム監視でインスタンス・リカバリが実行される。 |
 | PMON | プロセスモニター     |                                                                                  |
 | MMON | 管理性モニター       |                                                                                  |
 | ARCn | アーカイバ           |                                                                                  |


### 参考

- [Oracle Databaseメモリ管理方式について - 協栄情報ブログ](https://cloud5.jp/oracledatabase_20210419/)
- [インストレーション・ガイドfor Linux](https://docs.oracle.com/cd/E82638_01/ladbi/about-automatic-memory-management-installation-options.html#GUID-38F46564-B167-4A78-A974-8C7CEE34EDFE)
- 参考: [バックグラウンド・プロセスについて](https://docs.oracle.com/cd/E57425_01/121/ADMQS/GUID-9E50C7A8-0230-4074-AD61-2DB17DC2AB78.htm)


> データベース・インスタンスの合計物理メモリーが4GBを超える場合、データベースのインストールおよび作成時にOracle自動メモリー管理オプションは選択できません。


SELECT ANY DICTIONARY 権限
----------------------------------------

データ・ディクショナリに対するSELECT権限 をユーザーに付与する。
[データ・ディクショナリ](https://docs.oracle.com/cd/E15817_01/server.111/e05765/datadict.htm)


```sql
set linesize 200;

-- DBA_SYS_PRIVS でシステム権限を確認する
SELECT * FROM DBA_SYS_PRIVS WHERE GRANTEE = 'USER01';

    -- GRANTE PRIVILEGE                                ADM COM INH
    -- ------ ---------------------------------------- --- --- ---
    -- USER01 UNLIMITED TABLESPACE                     NO  NO  NO

-- 権限を付与 (上手くいかない)
GRANT SELECT ANY DICTIONARY TO USER01;

-- 付与されたか確認
SELECT * FROM DBA_SYS_PRIVS WHERE GRANTEE = 'USER01';

-- 剥奪する場合
REVOKE SELECT ANY DICTIONARY TO USER01;
```

[DBA_SYS_PRIVS](https://docs.oracle.com/cd/F19136_01/refrn/DBA_SYS_PRIVS.html)

`echo 'SELECT * FROM DBA_SYS_PRIVS;' | sqlplus -s / as sysdba | grep -i 'user01'`

| 項目      | 説明                                               |
| --------- | -------------------------------------------------- |
| GRANTEE   | 権限を付与されているユーザー(ロール)               |
| PRIVILEGE | 権限                                               |
| ADM       | ADMINオプション付きでロールが付与されている場合YES |


spoolでファイル名を日付に
----------------------------------------

- `COLUMN dt NEW_VALUE dt_var`は、`dt`という名前の列エイリアスを作成し、その列から取得された値を`dt_var`という名前の新しい代入変数に割り当てる。
- `SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS') AS dt FROM DUAL;`クエリが実行されると、`TO_CHAR`関数の結果が`dt`としてエイリアスされ、その値が`dt_var`変数に割り当てられる。
- スクリプトの後半で、`&dt_var`を参照して、それに割り当てられた値を使用できる。たとえば、`SPOOL /tmp/&dt_var`行など。


```sql
-- 実行したコマンド自体もspoolされるように
SET ECHO ON

-- ファイル名を作成してスプールを開始
COLUMN dt NEW_VALUE dt_var
SELECT TO_CHAR(SYSDATE, 'YYYYMMDD_HH24MISS"_spooltest.log"') AS dt FROM DUAL;
SPOOL /tmp/&dt_var

-- 実行したいコマンドを記載 
SELECT USERNAME, DEFAULT_COLLATION FROM dba_users;

-- 終了処理
SPOOL OFF;
EXIT
```


他ユーザーのオブジェクト権限
----------------------------------------

```sql
GRANT SELECT ON UserName.TableName TO RoleName;
```


id自動採番
----------------------------------------

[Oracle も 12c から自動採番ができるようになった - bnote](https://www.bnote.net/oracle/generated_identity.html)

- **GENERATED ALWAYS AS IDENTITY**: 自動採番列に対するUPDATEが 不可
- **GENERATED BY DEFAULT AS IDENTITY**: 自動採番列に対するUPDATEが 可能

 CREATE TABLE T_GENERATE_ID (id NUMBER GENERATED ALWAYS AS IDENTITY, name VARCHAR2(32));

```sql
-- テストテーブル作成
CREATE TABLE test_table (
    id          NUMBER GENERATED ALWAYS AS IDENTITY,
    time        TIMESTAMP,
    message     VARCHAR2(100)
);

desc test_table;

-- 試しにinsert
INSERT INTO test_table (time, message) VALUES (SYSTIMESTAMP, 'foo');
INSERT INTO test_table (time, message) VALUES (SYSTIMESTAMP, 'bar');

-- 確認
select * from test_table;

    -- 実行結果
    -- ID TIME                          MESSAGE
    -- -- ----------------------------- ----------
    -- 1 22-JUL-23 08.42.45.117788 PM  foo
    -- 2 22-JUL-23 08.42.45.947121 PM  bar
```

用語
----------------------------------------

### スキーマ(Schema)

ユーザーに関連付けられた、データを含むオブジェクトなどの集まり。ユーザー作成時に自動的に作成される。

### ストアドプロシージャ(Stored Procedure)

1つ以上のSQL文と手続き的ロジックをコンパイルして一つにまとめ、DBサーバに保存したオブジェクト。      
トリガー、他のプロシージャ、またはアプリケーションによって呼び出すことが出来る。        
ロジックのカプセル化、セキュリティの強化、ネットワークトラフィックを削減してパフォーマンスを向上させるのに役立つ。  
