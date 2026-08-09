AWR
================================================================================


AWR (Automatic Workload Repository)とは？
--------------------------------------------------------------------------------

- Oracleデータベースでのパフォーマンス監視とチューニングのために使用される組み込みツール。
- パフォーマンス問題の診断に重要なパフォーマンス統計を収集してくれる。
- 初期設定では、1時間ごとのスナップショットを8日間保持


事前設定
--------------------------------------------------------------------------------

### control_management_pack_access / statistics_level

- デフォルトでは変更不要
- 設定変更時のインスタンス再起動: 必要

```sql
-- control_management_pack_access 現在の値を確認
SHOW PARAMETER control_management_pack_access;
-- 有効化(初期値)
ALTER SYSTEM SET control_management_pack_access = 'DIAGNOSTIC+TUNING' SCOPE = spfile;
-- 参考: 無効化するばあい
-- ALTER SYSTEM SET control_management_pack_access = 'NONE' SCOPE = spfile;

-- statistics_level 現在の値を確認
SHOW PARAMETER statistics_level;
-- 有効化(初期値)
ALTER SYSTEM SET statistics_level = TYPICAL SCOPE = spfile;

-- 変更した場合インスタンス再起動
shutdown immediate
startup
```

### スナップショット自動取得設定

- 必要に応じて変更。
- 設定変更時のインスタンス再起動: 不要

| 値            | 説明                                                   | 初期値            |
| ------------- | ------------------------------------------------------ | ----------------- |
| SNAP_INTERVAL | スナップショットを自動的に取得する間隔                 | +00000 01:00:00.0 |
| RETENTION     | スナップショットを保存しておく時間                     | +00008 00:00:00.0 |
| TOPNSQL       | レポートに出力する上位SQLの数（経過時間、CPU時間など） | DEFAULT           |

なお、しばちょう先生のところにおすすめの値の記載もあった。

> ちなみに、弊社データベース・コンサルの畔勝さんからのおすすめとしては、10分間に一度のAWRのSnapshotを取得し、一カ月間は保持する設定・運用がお勧めとのガイドも頂きました。また、この設定は秒間1万回のSQLが実行されるデータベース環境においても問題なく動作しているとのことで安心して設定変更ができそうですね。もちろん、保持するデータ量が多くなるのでSYSAUX表領域のサイジングには十分にご注意くださいね。また、定期的なディクショナリ統計情報の収集も忘れずに！！

引用: [しばちょう先生の試して納得！DBAへの道　第51回 AWRレポートを読むステップ3: オンライン・トランザクションのスループット低下の原因特定](https://blogs.oracle.com/otnjp/post/shibacho-051)

```sql
-- 設定確認
col SNAP_INTERVAL for a20
col RETENTION for a20
SELECT DBID, SNAP_INTERVAL, RETENTION, TOPNSQL FROM DBA_HIST_WR_CONTROL;

-- 取得間隔変更を10分に変更
EXEC dbms_workload_repository.modify_snapshot_settings (interval=>10);
-- 保存期間を30日(43200分)に変更
EXEC dbms_workload_repository.modify_snapshot_settings (retention=>43200);
-- SQL出力数
EXEC dbms_workload_repository.modify_snapshot_settings (topnsql=>'MAXIMUM');
```

### 補足: スナップショット手動取得

```sql
-- 手動取得
EXEC dbms_workload_repository.create_snapshot();

-- 取得されているスナップショットを確認
col begin_interval_time for a20
col end_interval_time for a20
ALTER SESSION SET NLS_TIMESTAMP_FORMAT = 'YYYY-MM-DD HH24:MI:SS';

SELECT snap_id, begin_interval_time, end_interval_time
FROM   dba_hist_snapshot 
ORDER BY snap_id;
```


レポート取得
--------------------------------------------------------------------------------

### AWRレポート

- 指定した期間のパフォーマンス統計のレポート
- 任意の2つのスナップショット間の統計を取得する。

```sql
@?/rdbms/admin/awrrpt.sql
```

### AWR SQLレポート

- 指定した期間の特定のSQL IDのレポート
- 任意の2つのスナップショット間の統計を取得する。

```sql
@?/rdbms/admin/awrsqrpt.sql
```