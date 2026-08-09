# Oracle19c CDB

- LTSだと23cから、非CDBは使用できなくなる。
- OracleMasterGoldの勉強用に色々試す。  

## CDB概要

- 1個のインスタンスに対して1個のCDB
- 1個のCDBに対して複数のPDB
- SGAやバックグラウンドプロセスはCDBが保持(各PDBで共有)
- PDBの構成要素はデータファイルのみ
    - SPファイル、制御ファイル、オンラインREDOログはCDBのみが持つ
 

## CDB作成

DBCAで作成する際「コンテナデータベースとして作成」を選択する。  

## コンテナ一覧確認

DBCAでのDB作成時に、PDBを1個作成済み(pdb1)

```sql
show pdbs

    -- 実行例:
    --     CON_ID CON_NAME                       OPEN MODE  RESTRICTED
    -- ---------- ------------------------------ ---------- ----------
    --          2 PDB$SEED                       READ ONLY  NO
    --          3 PDB1                           MOUNTED

```

## PDBの作成

内部的にはシードPDBを元に作成される。

```sql
CREATE PLUGGABLE DATABASE pdb2
    ADMIN USER pdb2adm IDENTIFIED BY P@ssw0rd
    FILE_NAME_CONVERT=('/pdbseed','/pdb2');
```


## コンテナへの接続

### sqlplusでの接続

```sh
# 簡易接続ネーミングの場合
sqlplus sys/sys@localhost:1521/pdb1 as sysdba
```
```sql
-- 確認
show con_name;

    -- 実行例:
    -- CON_NAME
    -- ------------------------------
    -- PDB1
```

### すでに接続済みの場合の切り替え

```sql
-- 既に接続している場合の接続先変更
alter session set container = pdb1;
-- 確認
show con_name;
```

## コンテナの起動/停止

### 起動(OPEN)/停止(CLOSE)

```sql
-- 起動
ALTER PLUGGABLE DATABASE [ <PDB名> | ALL ] OPEN [READ WRITE | READ ONLY];
-- もしくは、PDBにアクセスしてstartup

-- 停止(MOUNTEDとなる)
ALTER PLUGGABLE DATABASE [ <PDB名> | ALL ] CLOSE [READ WRITE | READ ONLY];
-- もしくは、PDBにアクセスしてshutdown

-- 確認
show pdbs

    -- 実行例:
    --     CON_ID CON_NAME                       OPEN MODE  RESTRICTED
    -- ---------- ------------------------------ ---------- ----------
    --          2 PDB$SEED                       READ ONLY  NO
    --          3 PDB1                           MOUNTED
```

### PDB起動モードの保持

```sql
-- 設定の保持
ALTER PLUGGABLE DATABASE [ PDB名 | ALL ] SAVE STATE;

-- 確認(SAVEしていないと何も表示されない)
set linesize 200;
SELECT CON_NAME, STATE FROM CDB_PDB_SAVED_STATES;
```

### OPEN MODEの説明

| OPEN MODE  | 説明                                        | コマンド                                    |
| ---------- | ------------------------------------------- | ------------------------------------------- |
| MOUNTED    | クローズ状態 CDB起動時は基本的にこの状態    |                                             |
| READ ONLY  | オープン状態                                |                                             |
| READ WRITE |                                             |                                             |
| MIGRATE    | アップグレードモード OracleDBの更新時に使用 | `ALTER ALUGGABLE DATABASE ALL OPEN UPGRADE` |


## CDBのアップグレード

アップグレード後の環境において、

- CDBをアップグレードモードで起動 `STARTUP UPGRADE`
- 全PDBをアップグレードモードでオープン `ALTER ALUGGABLE DATABASE ALL OPEN UPGRADE`