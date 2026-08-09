# パーティション

## 新規作成するケース

```sql
CREATE TABLE transactions (
    transaction_id NUMBER,
    transaction_date DATE,
    amount NUMBER
)
PARTITION BY RANGE (transaction_date)  -- パーティション化の基準列を指定
INTERVAL (NUMTODSINTERVAL(1, 'DAY'))    -- パーティションの間隔を1日に設定
(
    PARTITION p_initial VALUES LESS THAN (DATE '2023-01-01') -- 初期パーティションを設定
);
```
- p_initial は初期パーティションの名前
- 自動生成されたものはoracleが名前を付ける

## 既存のテーブルを変換するケース

```sql
ALTER TABLE transactions
MODIFY PARTITION BY RANGE (transaction_date)  -- transaction_date列に基づいてパーティション化
INTERVAL (NUMTODSINTERVAL(1, 'DAY'))       -- パーティションの間隔を1日に設定
(
    PARTITION p_initial VALUES LESS THAN (DATE '2023-01-01')  -- 初期パーティションの定義
);
```

## 確認方法

```sql
SELECT table_owner, table_name, partition_name, high_value
FROM all_tab_partitions;
```