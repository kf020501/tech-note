DynamoDB
================================================================================


基本操作
--------------------------------------------------------------------------------

### テーブルの作成

```sh
export AWS_DEFAULT_REGION=ap-northeast-1

aws dynamodb create-table \
    --table-name Users \
    --attribute-definitions AttributeName=EMAIL_ADDRESS,AttributeType=S \
    --key-schema AttributeName=EMAIL_ADDRESS,KeyType=HASH \
    --billing-mode PAY_PER_REQUEST
    # --provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5
    --tags Key=Owner,Value=$IAM_USER
```

| 引数                                                     | 説明                                                                                                                       |
| -------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------- |
| --table-name Users                                       | 作成するテーブルの名前を指定します。ここでは「Users」というテーブルを作成。                                                |
| --attribute-definitions AttributeName=ID,AttributeType=N | テーブルで使用する属性を定義します。ここでは「ID」属性を数値型 (N) として定義しています。                                  |
| --key-schema AttributeName=ID,KeyType=HASH               | テーブルの主キー（パーティションキー）を定義します。ここでは「ID」属性をパーティションキーとして設定。                     |
| --billing-mode PAY_PER_REQUEST                           | 課金モードをオンデマンド方式に設定します。これにより、読み書きキャパシティの明示的な設定は不要になります。                 |
| --tags Key=Owner,Value=$IAM_USER                         | テーブルにタグを付与します。ここでは「Owner」というキーで、環境変数 $IAM_USER（現在のIAMユーザー名）を値として設定します。 |


### テーブルの確認

一覧の表示
```sh
aws dynamodb list-tables
```
結果例
```json
{
    "TableNames": [
        "Users"
    ]
}
```

テーブルを指定して詳細を表示
```sh
aws dynamodb describe-table --table-name <テーブル名> 
```


### テーブルの削除する場合

```sh
aws dynamodb delete-table \
    --table-name Users
```

### データの挿入

```sh
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "1"}, "NAME": {"S": "Alice"}, "EMAIL": {"S": "alice@example.com"}, "BIRTHDAY": {"S": "1990-01-01"}}'
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "2"}, "NAME": {"S": "Bob"}, "EMAIL": {"S": "bob@example.com"}, "BIRTHDAY": {"S": "1985-02-15"}}'
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "3"}, "NAME": {"S": "Charlie"}, "EMAIL": {"S": "charlie@example.com"}, "BIRTHDAY": {"S": "1980-03-20"}}'
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "4"}, "NAME": {"S": "David"}, "EMAIL": {"S": "david@example.com"}, "BIRTHDAY": {"S": "1992-04-10"}}'
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "5"}, "NAME": {"S": "Eva"}, "EMAIL": {"S": "eva@example.com"}, "BIRTHDAY": {"S": "1993-05-05"}}'
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "6"}, "NAME": {"S": "Frank"}, "EMAIL": {"S": "frank@example.com"}, "BIRTHDAY": {"S": "1988-06-15"}}'
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "7"}, "NAME": {"S": "Grace"}, "EMAIL": {"S": "grace@example.com"}, "BIRTHDAY": {"S": "1995-07-20"}}'
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "8"}, "NAME": {"S": "Hannah"}, "EMAIL": {"S": "hannah@example.com"}, "BIRTHDAY": {"S": "1983-08-25"}}'
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "9"}, "NAME": {"S": "Ivy"}, "EMAIL": {"S": "ivy@example.com"}, "BIRTHDAY": {"S": "1991-09-10"}}'
aws dynamodb put-item --table-name Users --item '{"ID": {"N": "10"}, "NAME": {"S": "Jack"}, "EMAIL": {"S": "jack@example.com"}, "BIRTHDAY": {"S": "1987-10-30"}}'
```

一括挿入する方法:

- CSVをJSONに変換してbatch-write-itemを利用(25件まで？)
- AWS Glueを使用(パット見た感じ学習コストそこそこ必要)
- DynamoDB Import from S3（新機能）

### データの検索(パーティションキー)

完全一致

```sh
aws dynamodb get-item \
    --table-name Users \
    --key '{"EMAIL_ADDRESS": {"S": "bill.donaldson.fleming@sample.com"}}'
```

結果
```json
{
    "Item": {
        "BIRTHDAY": {
            "S": "1990-01-01"
        },
        "ID": {
            "N": "1"
        },
        "EMAIL": {
            "S": "alice@example.com"
        },
        "NAME": {
            "S": "Alice"
        }
    }
}
```

### データの検索(クエリ操作)

主キーの範囲や、ソートキーを利用した検索を行う場合は、query コマンドを使用する。

```sh
aws dynamodb scan \
    --table-name Users \
    --filter-expression "EMAIL = :email" \
    --expression-attribute-values '{":email": {"S": "bob@example.com"}}'
```

結果
```json
{
    "Items": [
        {
            "BIRTHDAY": {
                "S": "1985-02-15"
            },
            "ID": {
                "N": "2"
            },
            "EMAIL": {
                "S": "bob@example.com"
            },
            "NAME": {
                "S": "Bob"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 10,
    "ConsumedCapacity": null
}
```

機能
--------------------------------------------------------------------------------

ChatGPTに聞いたもの含む

### パーティションキー（PK）とソートキー

- **パーティションキー（PK）:**  
  - テーブル内で一意の値である必要があります。  
  - アイテムはこのキーによって異なるパーティション（物理的な分散領域）に格納されます。

- **ソートキー:**  
  - パーティションキーと組み合わせることで、複合主キーを形成します。  
  - 同一のパーティションキーを持つ複数のアイテムを区別するための、順序付け可能な属性です。  
  - **使い時:**  
    - 複数のアイテムを1つのパーティションキーの下にグループ化したい場合（例: ユーザーごとに複数の注文情報を保存する場合）  
    - 範囲検索や順序付けされたクエリを実施する場合（例: ある期間内の注文を取得したいなど）


### セカンダリインデックス

主キー（パーティションキー、ソートキー）以外の属性で検索する場合、直接はクエリできないため、セカンダリインデックスを使用する。

| インデックス名                             | 特徴・用途                                                                                                                                                               | 制約・注意点                                                                                                  |
| ------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------- |
| **ローカルセカンダリインデックス (LSI)**   | - テーブルのパーティションキーはメインテーブルと同じ。<br> - 異なるソートキーを定義可能。<br> - 主に、同一パーティション内で異なる並び順やフィルタを実現するために使用。 | - テーブル作成時にのみ定義可能。<br> - アイテム数が同じパーティションに制限される。                           |
| **グローバルセカンダリインデックス (GSI)** | - テーブルとは異なるパーティションキー、ソートキーを設定可能。<br> - メインテーブルとは別にインデックスが管理されるため、任意の属性で効率的に検索できる。                | - GSIは後から追加可能。<br> - 書き込み時にGSIも更新されるため、書き込みパフォーマンスに影響する可能性がある。 |

- **LSIの使い方の例:**  
  例えば、ユーザーごとの投稿を管理するテーブルで、パーティションキーが「UserID」、メインのソートキーが「投稿日時」である場合、LSIを利用して「投稿の種類」など別の基準での並び替えや検索が可能です。

- **GSIの使い方の例:**  
  ユーザーテーブルで「EMAIL」や「NAME」での検索を行いたい場合、これらをパーティションキーやソートキーとして持つGSIを定義しておくことで、メインテーブルとは異なる属性で効率的なクエリができます。


参考
--------------------------------------------------------------------------------

- [Amazon DynamoDB - How it works【AWS Black Belt】 - YouTube](https://www.youtube.com/watch?v=ndtg5Gx0rKE)
- [[GT-2] イラストで学ぶAmazon DynamoDB ～テーブル設計からパフォーマンスチューニングまで～ | AWS Dev Day 2023 Tokyo #AWSDevDay - YouTube](https://www.youtube.com/watch?v=JeVsqphKKEI)
