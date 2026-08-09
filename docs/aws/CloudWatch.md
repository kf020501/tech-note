CloudWatch
================================================================================

必要に応じて事前に指定
```sh
export AWS_PROFILE=dev
export AWS_REGION=ap-northeast-1
```

CloudWatch Logs
--------------------------------------------------------------------------------

### ロググループ一覧

```sh
# 一覧取得
aws logs describe-log-groups
```

### ログストリーム一覧

```sh
# 確認したいlogGroupNameを指定
log_group_name="/aws/lambda/my-function"
# 取得
aws logs describe-log-streams \
  --log-group-name $log_group_name
```

### InsightsをCLIで実行

#### 最小構成
```sh
# 確認したいlogGroupNameを指定
log_group_name="/aws/lambda/my-function"

# カラマデの指定(UNIXエポック秒) 直近24時間例
start_time=$(date -d "1 day ago" +%s)
end_time=$(date +%s)

# クエリを作成
query='
fields @timestamp, @message
| sort @timestamp asc
| limit 100
'

# クエリの実行
query_id=$(aws logs start-query \
  --start-time      $start_time \
  --end-time        $end_time \
  --log-group-name  $log_group_name \
  --query-string    "$query" \
  --query 'queryId' --output text)

# クエリの取得(json)
aws logs get-query-results --query-id $query_id

# クエリの取得(jqでtsv形式に変換しファイルへ)
jq_filter='.results[]| (map({(.field): .value}) | add)| [.["@timestamp"], .["@message"]]| @tsv'
aws logs get-query-results --query-id $query_id | jq -r "$jq_filter" > ${log_group_name//\//_}_$(date -d "@$start_time" "+%Y%m%d-%H%M%S")_$(date -d "@$end_time" "+%Y%m%d-%H%M%S")_$query_id.tsv

# クエリの取得(jqでcsv形式に変換しファイルへ)
jq_filter='.results[]| (map({(.field): .value}) | add)| [.["@timestamp"], .["@message"]]| @csv'
aws logs get-query-results --query-id $query_id | jq -r "$jq_filter" > ${log_group_name//\//_}_$(date -d "@$start_time" "+%Y%m%d-%H%M%S")_$(date -d "@$end_time" "+%Y%m%d-%H%M%S")_$query_id.csv
```
#### 時間指定サンプル
```sh
# 特定の日付（例：2025-01-01 00:00〜）
start_time=$(date -d "2025-01-01 00:00" +%s)
end_time=$(date -d "2025-01-01 23:59:59" +%s)

# 直近10分
start_time=$(date -d "10 minutes ago" +%s)
end_time=$(date +%s)

# 直近1時間
start_time=$(date -d "1 hour ago" +%s)
end_time=$(date +%s)

# 直近1日
start_time=$(date -d "1 day ago" +%s)
end_time=$(date +%s)

# 今日の 00:00:00 から現在まで
start_time=$(date -d "yesterday 00:00" +%s)
end_time=$(date -d "yesterday 23:59:59" +%s)

# 昨日の 00:00:00 〜 23:59:59
start_time=$(date -d "yesterday 00:00" +%s)
end_time=$(date -d "yesterday 23:59:59" +%s)
```


#### クエリサンプル

```sh
# ERRORを含むログ
query="
fields @timestamp, @message
| filter @message like /ERROR/
| sort @timestamp asc
| limit 1000
"
```
