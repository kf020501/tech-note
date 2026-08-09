# ブロックメディアリカバリ

ブロックメディアリカバリは、破損したDBのブロックの修復を行ってくれる機能。    
実行するためにDBの停止などは不要。      

必要なのは以下。

- ArchiveLogモードでの運用
- EnterpriseEdition
- バックアップ or フラッシュバックログ or DataGridのフィジカルスタンバイDB (ここから正しいデータを持ってくる)


## 事前準備

```sql
sqlplus / as sysdba

-- アーカイブログモードに変更

-- 表領域をできるだけ小さく(大きいと該当箇所探すのが大変)
ALTER DATABASE DATAFILE '/u01/app/oracle/usertbs.dbf' RESIZE 10M;
```

サンプルデータ投入
```sql
sqlplus dbuser/dbuser

-- usersテーブルの作成 & 各列の定義作成
CREATE TABLE users (
    ID       NUMBER PRIMARY KEY,
    name     VARCHAR2(50),
    email    VARCHAR2(100),
    birthday DATE
);

-- usersテーブルにデータを挿入
INSERT INTO users (ID, name, email, birthday) VALUES (1,  'Alice',   'alice@example.com',   TO_DATE('1990-01-01', 'YYYY-MM-DD'));
INSERT INTO users (ID, name, email, birthday) VALUES (2,  'Bob',     'bob@example.com',     TO_DATE('1985-02-15', 'YYYY-MM-DD'));
INSERT INTO users (ID, name, email, birthday) VALUES (3,  'Charlie', 'charlie@example.com', TO_DATE('1980-03-20', 'YYYY-MM-DD'));
INSERT INTO users (ID, name, email, birthday) VALUES (4,  'David',   'david@example.com',   TO_DATE('1992-04-10', 'YYYY-MM-DD'));
INSERT INTO users (ID, name, email, birthday) VALUES (5,  'Eva',     'eva@example.com',     TO_DATE('1993-05-05', 'YYYY-MM-DD'));
INSERT INTO users (ID, name, email, birthday) VALUES (6,  'Frank',   'frank@example.com',   TO_DATE('1988-06-15', 'YYYY-MM-DD'));
INSERT INTO users (ID, name, email, birthday) VALUES (7,  'Grace',   'grace@example.com',   TO_DATE('1995-07-20', 'YYYY-MM-DD'));
INSERT INTO users (ID, name, email, birthday) VALUES (8,  'Hannah',  'hannah@example.com',  TO_DATE('1983-08-25', 'YYYY-MM-DD'));
INSERT INTO users (ID, name, email, birthday) VALUES (9,  'Ivy',     'ivy@example.com',     TO_DATE('1991-09-10', 'YYYY-MM-DD'));
INSERT INTO users (ID, name, email, birthday) VALUES (10, 'Jack',    'jack@example.com',    TO_DATE('1987-10-30', 'YYYY-MM-DD'));
COMMIT;

-- usersテーブルを表示
set line 200
SELECT * FROM users;
```

バックアップ作製
```sql
rman target /

BACKUP DATABASE PLUS ARCHIVELOG;
```

## ブロックを破壊

バイナリ編集し、わざと破損させる。  
データがある箇所の確認
```
hexdump -Cv /u01/app/oracle/usertbs.dbf | grep -v '00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00'
```

頑張ってそれっぽいところを探す
```
hexdump -Cv /u01/app/oracle/usertbs.dbf | grep -E '^0010de'

0010de00  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de10  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de20  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de30  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de40  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de50  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de60  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de70  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de80  00 00 00 00 00 00 00 00  2c 01 04 02 c1 0b 04 4a  |........,......J|
0010de90  61 63 6b 10 6a 61 63 6b  40 65 78 61 6d 70 6c 65  |ack.jack@example| ★ ここを壊す
0010dea0  2e 63 6f 6d 07 77 bb 0a  1e 01 01 01 2c 01 04 02  |.com.w......,...|
0010deb0  c1 0a 03 49 76 79 0f 69  76 79 40 65 78 61 6d 70  |...Ivy.ivy@examp|
0010dec0  6c 65 2e 63 6f 6d 07 77  bf 09 0a 01 01 01 2c 01  |le.com.w......,.|
0010ded0  04 02 c1 09 06 48 61 6e  6e 61 68 12 68 61 6e 6e  |.....Hannah.hann|
0010dee0  61 68 40 65 78 61 6d 70  6c 65 2e 63 6f 6d 07 77  |ah@example.com.w|
0010def0  b7 08 19 01 01 01 2c 01  04 02 c1 08 05 47 72 61  |......,......Gra|
```

10de90 = 1105552 個目のブロックに'\x00'を書き込む
```sh
echo -en '\x00' | dd of=/u01/app/oracle/usertbs.dbf bs=1 seek=1105552 conv=notrunc
```

```
hexdump -Cv /u01/app/oracle/usertbs.dbf | grep -E '^0010de'

0010de00  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de10  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de20  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de30  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de40  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de50  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de60  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de70  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de80  00 00 00 00 00 00 00 00  2c 01 04 02 c1 0b 04 4a  |........,......J|
0010de90  00 63 6b 10 6a 61 63 6b  40 65 78 61 6d 70 6c 65  |.ck.jack@example| ★
0010dea0  2e 63 6f 6d 07 77 bb 0a  1e 01 01 01 2c 01 04 02  |.com.w......,...|
0010deb0  c1 0a 03 49 76 79 0f 69  76 79 40 65 78 61 6d 70  |...Ivy.ivy@examp|
0010dec0  6c 65 2e 63 6f 6d 07 77  bf 09 0a 01 01 01 2c 01  |le.com.w......,.|
0010ded0  04 02 c1 09 06 48 61 6e  6e 61 68 12 68 61 6e 6e  |.....Hannah.hann|
0010dee0  61 68 40 65 78 61 6d 70  6c 65 2e 63 6f 6d 07 77  |ah@example.com.w|
0010def0  b7 08 19 01 01 01 2c 01  04 02 c1 08 05 47 72 61  |......,......Gra|
[oracle@oracle19c ~]$ 
```

## 確認・修復

```sh
export NLS_LANG=Japanese_Japan.AL32UTF8
rman target /
```

データファイルの破損チェックを実行
```text
RMAN> validate database;

validateを23-08-20で開始しています
リカバリ・カタログのかわりにターゲット・データベース制御ファイルを使用しています
チャネル: ORA_DISK_1が割り当てられました
チャネルORA_DISK_1: SID=278 デバイス・タイプ=DISK
チャネルORA_DISK_1: データファイルの検証を開始しています
チャネルORA_DISK_1: 検証のためのデータファイルを指定しています
入力データファイル ファイル番号=00001 名前=/u01/app/oracle/oradata/ORCL/datafile/o1_mf_system_l7kvnjcv_.dbf
入力データファイル ファイル番号=00003 名前=/u01/app/oracle/oradata/ORCL/datafile/o1_mf_sysaux_l7kvo9j2_.dbf
入力データファイル ファイル番号=00004 名前=/u01/app/oracle/oradata/ORCL/datafile/o1_mf_undotbs1_l7kvormc_.dbf
入力データファイル ファイル番号=00005 名前=/u01/app/oracle/usertbs.dbf
入力データファイル ファイル番号=00007 名前=/u01/app/oracle/oradata/ORCL/datafile/o1_mf_users_l7kvospt_.dbf
チャネルORA_DISK_1: 検証が完了しました。経過時間: 00:00:01
List of Datafiles
=================
File Status Marked Corrupt Empty Blocks Blocks Examined High SCN
---- ------ -------------- ------------ --------------- ----------
1    OK     0              18075        117770          2334998   
  ファイル名: /u01/app/oracle/oradata/ORCL/datafile/o1_mf_system_l7kvnjcv_.dbf
  Block Type Blocks Failing Blocks Processed
  ---------- -------------- ----------------
  Data       0              81424           
  Index      0              13171           
  Other      0              5090            

    :

File Status Marked Corrupt Empty Blocks Blocks Examined High SCN
---- ------ -------------- ------------ --------------- ----------
5    FAILED 0              1141         1280            2334337   ★ StatusがFAILEDとなっている
  ファイル名: /u01/app/oracle/usertbs.dbf
  Block Type Blocks Failing Blocks Processed
  ---------- -------------- ----------------
  Data       1              5               ★ Blocks Failingが 1となっている
  Index      0              1               
  Other      0              133             

    ：：

検証により1つ以上の破損したブロックが見つかりました
詳細はトレース・ファイル/u01/app/oracle/diag/rdbms/orcl/orcl/trace/orcl_ora_2046.trcを参照してください 
チャネルORA_DISK_1: データファイルの検証を開始しています
チャネルORA_DISK_1: 検証のためのデータファイルを指定しています
現行の制御ファイルを検証に組み込んでいます
バックアップ・セットに現行のSPFILEを組み込んでいます
チャネルORA_DISK_1: 検証が完了しました。経過時間: 00:00:01
List of Control File and SPFILE
===============================
File Type    Status Blocks Failing Blocks Examined
------------ ------ -------------- ---------------
SPFILE       OK     0              2               
Control File OK     0              646             
validateを23-08-20で終了しました
```

検出された破損ブロックを確認
```text
RMAN> select FILE#, BLOCK#, BLOCKS, CORRUPTION_TYPE from v$database_block_corruption;

     FILE#     BLOCK#     BLOCKS CORRUPTIO
---------- ---------- ---------- ---------
         5        134          1 CHECKSUM 
```

破損ブロックを修復
```text
RMAN> recover corruption list;

recoverを23-08-20で開始しています
チャネルORA_DISK_1の使用

チャネルORA_DISK_1: ブロックをリストアしています
チャネルORA_DISK_1: バックアップ・セットからリストアするブロックを指定しています
データファイル00005のブロックをリストアしています
チャネルORA_DISK_1: バックアップ・ピース/u01/app/oracle/fast_recovery_area/ORCL/backupset/2023_08_20/o1_mf_nnndf_TAG20230820T223306_lg45jlnc_.bkpから読取り中です
チャネルORA_DISK_1: ピース・ハンドル=/u01/app/oracle/fast_recovery_area/ORCL/backupset/2023_08_20/o1_mf_nnndf_TAG20230820T223306_lg45jlnc_.bkp タグ=TAG20230820T223306
チャネルORA_DISK_1: バックアップ・ピース1からブロックをリストアしました
チャネルORA_DISK_1: ブロックのリストアが完了しました。経過時間: 00:00:01

メディア・リカバリを開始しています
メディア・リカバリが完了しました。経過時間: 00:00:03

recoverを23-08-20で終了しました
```

破損ブロックがないことを確認
```text
RMAN> select FILE#, BLOCK#, BLOCKS, CORRUPTION_TYPE from v$database_block_corruption;

リカバリ・カタログのかわりにターゲット・データベース制御ファイルを使用しています

行が選択されていません
```

バイナリでも復旧したことが確認できる。
```
hexdump -Cv /u01/app/oracle/usertbs.dbf | grep -E '^0010de'

0010de00  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de10  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de20  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de30  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de40  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de50  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de60  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de70  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de80  00 00 00 00 00 00 00 00  2c 01 04 02 c1 0b 04 4a  |........,......J|
0010de90  61 63 6b 10 6a 61 63 6b  40 65 78 61 6d 70 6c 65  |ack.jack@example| ★
0010dea0  2e 63 6f 6d 07 77 bb 0a  1e 01 01 01 2c 01 04 02  |.com.w......,...|
0010deb0  c1 0a 03 49 76 79 0f 69  76 79 40 65 78 61 6d 70  |...Ivy.ivy@examp|
0010dec0  6c 65 2e 63 6f 6d 07 77  bf 09 0a 01 01 01 2c 01  |le.com.w......,.|
0010ded0  04 02 c1 09 06 48 61 6e  6e 61 68 12 68 61 6e 6e  |.....Hannah.hann|
0010dee0  61 68 40 65 78 61 6d 70  6c 65 2e 63 6f 6d 07 77  |ah@example.com.w|
0010def0  b7 08 19 01 01 01 2c 01  04 02 c1 08 05 47 72 61  |......,......Gra|
```


## 別解: データリカバリアドバイザーによる復旧

修復をよしなにしてくれる。

- 検出済みのファイル消失、ブロック破損の表示
- 破損修復スクリプトの生成
- 修復の実行

データファイルの破損チェックを実行(ここまで手動と同じ) ⇒ 障害が検出される
```text
RMAN> validate database;

    :

File Status Marked Corrupt Empty Blocks Blocks Examined High SCN
---- ------ -------------- ------------ --------------- ----------
5    FAILED 0              1141         1280            2334337   ★ StatusがFAILEDとなっている
  ファイル名: /u01/app/oracle/usertbs.dbf
  Block Type Blocks Failing Blocks Processed
  ---------- -------------- ----------------
  Data       1              5               ★ Blocks Failingが 1となっている
  Index      0              1               
  Other      0              133             

    ：
検証により1つ以上の破損したブロックが見つかりました
    ：
```

検出されている障害を表示
```text
RMAN> list failure;

データベース・ロール: PRIMARY

List of Database Failures
=========================

障害ID 優先度ステータス    検出時間 サマリー
------ -------- --------- -------- -------
81     HIGH     OPEN      23-08-20 データファイル5: '/u01/app/oracle/usertbs.dbf'には破損したブロックが1つ以上含まれています
```

障害分析
```
RMAN> advise failure;

データベース・ロール: PRIMARY

List of Database Failures
=========================

障害ID 優先度ステータス    検出時間 サマリー
------ -------- --------- -------- -------
81     HIGH     OPEN      23-08-20 データファイル5: '/u01/app/oracle/usertbs.dbf'には破損したブロックが1つ以上含まれています

自動修復オプションを分析中です。これには少し時間がかかる場合があります
チャネルORA_DISK_1の使用
自動修復オプションの分析が完了しました

必須の手動アクション
========================
no manual actions available

Optional Manual Actions
=======================
no manual actions available

自動修復オプション
========================
オプション 修復 説明
------ ------------------
1      ブロック134 (ファイル5)のブロック・メディア・リカバリを実行します  
  計画: 修復には、データが損失しない完全なメディア・リカバリが含まれます
  Repair script: /u01/app/oracle/diag/rdbms/orcl/orcl/hm/reco_683051497.hm
```

推奨された復旧手順の確認
```
RMAN> repair failure preview;

計画: 修復には、データが損失しない完全なメディア・リカバリが含まれます
Repair script: /u01/app/oracle/diag/rdbms/orcl/orcl/hm/reco_683051497.hm

修復スクリプトの内容:
   # block media recovery
   recover datafile 5 block 134;
```

首位称された復旧手順の実行
```
RMAN> repair failure;

計画: 修復には、データが損失しない完全なメディア・リカバリが含まれます
Repair script: /u01/app/oracle/diag/rdbms/orcl/orcl/hm/reco_683051497.hm

修復スクリプトの内容:
   # block media recovery
   recover datafile 5 block 134;

この修復を実行しますか(YESまたはNOを入力してください)。 yes ★ yesを回答
修復スクリプトを実行しています

recoverを23-08-20で開始しています
チャネルORA_DISK_1の使用

チャネルORA_DISK_1: ブロックをリストアしています
チャネルORA_DISK_1: バックアップ・セットからリストアするブロックを指定しています
データファイル00005のブロックをリストアしています
チャネルORA_DISK_1: バックアップ・ピース/u01/app/oracle/fast_recovery_area/ORCL/backupset/2023_08_20/o1_mf_nnndf_TAG20230820T223306_lg45jlnc_.bkpから読取り中です
チャネルORA_DISK_1: ピース・ハンドル=/u01/app/oracle/fast_recovery_area/ORCL/backupset/2023_08_20/o1_mf_nnndf_TAG20230820T223306_lg45jlnc_.bkp タグ=TAG20230820T223306
チャネルORA_DISK_1: バックアップ・ピース1からブロックをリストアしました
チャネルORA_DISK_1: ブロックのリストアが完了しました。経過時間: 00:00:01

メディア・リカバリを開始しています
メディア・リカバリが完了しました。経過時間: 00:00:01

recoverを23-08-20で終了しました
障害の修復が完了しました
```

障害が修復されたか確認
```
RMAN> list failure;

データベース・ロール: PRIMARY

指定に一致する障害が見つかりません
```

バイナリでも復旧したことが確認できる。
```
hexdump -Cv /u01/app/oracle/usertbs.dbf | grep -E '^0010de'

0010de00  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de10  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de20  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de30  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de40  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de50  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de60  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de70  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
0010de80  00 00 00 00 00 00 00 00  2c 01 04 02 c1 0b 04 4a  |........,......J|
0010de90  61 63 6b 10 6a 61 63 6b  40 65 78 61 6d 70 6c 65  |ack.jack@example| ★
0010dea0  2e 63 6f 6d 07 77 bb 0a  1e 01 01 01 2c 01 04 02  |.com.w......,...|
0010deb0  c1 0a 03 49 76 79 0f 69  76 79 40 65 78 61 6d 70  |...Ivy.ivy@examp|
0010dec0  6c 65 2e 63 6f 6d 07 77  bf 09 0a 01 01 01 2c 01  |le.com.w......,.|
0010ded0  04 02 c1 09 06 48 61 6e  6e 61 68 12 68 61 6e 6e  |.....Hannah.hann|
0010dee0  61 68 40 65 78 61 6d 70  6c 65 2e 63 6f 6d 07 77  |ah@example.com.w|
0010def0  b7 08 19 01 01 01 2c 01  04 02 c1 08 05 47 72 61  |......,......Gra|
```