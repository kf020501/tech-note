# サンプルECサイト設計書

下記の考え方・使い分けが理解できるようにChatGPTに作成してもらったサンプル設計書

- RDBとDynamoDBの使い分け
- DynamoDBのキー、INDEXの使い分け

## 1. システム概要

**目的:**  
ユーザーが商品を閲覧、カートに入れ、購入できるECサイトを構築する。  
- 商品情報、在庫、決済、ユーザーアカウントなどの整合性が重要なデータはRDBMS（例：MySQL / PostgreSQL）で管理。  
- 注文履歴、カート、セッション、アクセスログなど大量かつ高スループットなデータはDynamoDBで管理し、スケーラブルな運用を実現する。

**対象ユーザー:**  
一般消費者、管理者、出品者

---

## 2. システムアーキテクチャ

### 2.1 フロントエンド
- Webサイト（ReactなどのSPA）およびモバイルアプリ  
- REST API / GraphQLを通じたバックエンドとの連携

### 2.2 バックエンド
- **APIサーバ:**  
  - ユーザー認証、商品検索、決済処理、注文受付などのコアロジックを提供
  - マイクロサービスやサーバーレス（Lambda）を活用する場合もあり

- **RDBサーバ (MySQL / PostgreSQL):**  
  - 商品カタログ、在庫、ユーザーアカウント、決済トランザクションを管理  
  - 複雑なJOINやACIDトランザクションを利用

- **DynamoDB:**  
  - 注文履歴、ショッピングカート、セッション、アクセスログなど高い書き込み/読み込みスループットが必要なデータを管理  
  - アクセスパターンに合わせたインデックス設計（LSI/GSI）により柔軟なクエリを実現

### 2.3 インフラ
- AWS環境全体（EC2 / Lambda、RDS、DynamoDB、S3、API Gateway、CloudFrontなど）  
- IAM、VPC、暗号化、監査ログなどセキュリティ対策も実施

---

## 3. データベース設計

### 3.1 RDB (MySQL / PostgreSQL)

#### 主なテーブルと用途

| テーブル名    | 主な属性                                                                    | 用途                                                       |
| ------------- | --------------------------------------------------------------------------- | ---------------------------------------------------------- |
| **Products**  | ProductID (PK), ProductName, Description, Price, Stock, Category, ...       | 商品カタログ。詳細表示、複雑な検索、在庫管理。             |
| **Users**     | UserID (PK), Name, Email, PasswordHash, Address, Phone, CreatedDate, ...    | ユーザーアカウント管理。認証、プロフィール、決済情報など。 |
| **Inventory** | ProductID (PK), WarehouseID (PK), StockLevel, ...                           | 複数倉庫での在庫管理。外部キー制約を利用。                 |
| **Payments**  | PaymentID (PK), OrderID (FK), Amount, PaymentMethod, Status, Timestamp, ... | 決済情報。トランザクション処理により整合性を確保。         |

#### 利用シーン
- 商品詳細表示、在庫チェック、決済トランザクション、ユーザー情報の更新など、複雑なクエリと厳密な整合性が必要な処理。

---

### 3.2 DynamoDB

#### Ordersテーブル（注文履歴管理）

| 属性名         | データ型 | 用途                                                                          |
| -------------- | -------- | ----------------------------------------------------------------------------- |
| **CustomerID** | String   | パーティションキー。各ユーザーの注文履歴をグループ化。                        |
| **OrderDate**  | String   | ソートキー。注文日時（ISO8601形式推奨）。同一ユーザーの注文を時系列で並べる。 |
| OrderID        | String   | 注文固有のID。補助的な識別子。                                                |
| OrderStatus    | String   | 注文状態（例："Processing", "Shipped", "Delivered"）。                        |
| TotalAmount    | Number   | 注文合計金額。                                                                |
| ...            | ...      | 配送先情報、支払い方法、注文内商品のリストなど。                              |

##### インデックス例

| インデックス種別   | 構成                                                      | 用途                                                                    |
| ------------------ | --------------------------------------------------------- | ----------------------------------------------------------------------- |
| **メインテーブル** | パーティションキー: CustomerID<br>ソートキー: OrderDate   | 顧客ごとの注文履歴を時系列（最新順など）に取得。                        |
| **LSI**            | パーティションキー: CustomerID<br>ソートキー: TotalAmount | 同一顧客内で注文金額の大小順で並べ替え、金額範囲のクエリに利用。        |
| **GSI**            | パーティションキー: OrderStatus<br>ソートキー: OrderDate  | 全顧客の中から特定の注文状態（例："Shipped"）の注文を注文日時順で抽出。 |

#### **ShoppingCartテーブル**

ショッピングカートは、ユーザーが購入前に選択した商品の一覧を高速に操作できるようにします。

| 属性名        | データ型 | 用途                                           |
| ------------- | -------- | ---------------------------------------------- |
| **UserID**    | String   | パーティションキー。各ユーザーのカートを識別。 |
| **ProductID** | String   | ソートキー。カート内の商品を識別。             |
| Quantity      | Number   | 商品の数量。                                   |
| AddedAt       | String   | 商品をカートに追加した日時。                   |

※ このテーブルにより、ユーザーは自分のカート内商品を高速に追加・更新・削除可能。

---

## 4. データ挿入処理の考え方

ECサイトにおけるデータ挿入は、処理内容に応じてRDBとDynamoDBの両方に対して行われることが考えられます。

### 4.1 購入時（チェックアウト）の場合

1. **RDBへのINSERT/UPDATE:**
   - **ユーザー情報／在庫／決済:**  
     - 決済処理や在庫引当、ユーザー情報の更新は、ACIDトランザクションが必要なため、RDBで処理。
     - 例: 在庫数の減少、決済レコードの作成。

2. **DynamoDBへのINSERT:**
   - **注文履歴（Ordersテーブル）:**  
     - 購入完了後、注文内容の履歴をDynamoDBにINSERT。  
     - 高速な書き込みとスケーラブルな履歴管理が可能。
   - **ショッピングカート（ShoppingCartテーブル）のクリア:**  
     - 購入完了時に、ユーザーのカート内容を削除またはアーカイブする処理を実施。

### 4.2 その他のデータ挿入

- **ユーザー登録:**  
  - ユーザー情報はRDBにINSERT（整合性が必要な情報）。
- **商品レビューやアクセスログ:**  
  - 分析や履歴用途の場合、DynamoDBや別の分析向けサービス（例：Redshift）にINSERT。

### 4.3 挿入処理の連携例

1. ユーザーが「購入」ボタンをクリック  
2. バックエンドAPIがトランザクションを開始し、RDBで以下を実行:
   - 在庫チェックと在庫数更新  
   - 決済処理レコードの作成  
3. 同時に、バックエンドは非同期またはトランザクション連動処理で、DynamoDBのOrdersテーブルに購入情報をINSERT  
4. 購入完了後、ショッピングカート（ShoppingCartテーブル）をクリアする

※ このように、リアルタイム性やスケーラビリティが要求される処理はDynamoDB、整合性や複雑なクエリが求められる処理はRDBに分担するハイブリッドアプローチを採用します。

---

## 5. 想定するデータ取得（サンプル：AWS CLI）

### 5.1 顧客ごとの注文履歴取得（Ordersテーブル: メインクエリ）
```bash
aws dynamodb query \
    --table-name Orders \
    --key-condition-expression "CustomerID = :custId" \
    --expression-attribute-values '{":custId": {"S": "USER123"}}' \
    --scan-index-forward false
```

### 5.2 同一顧客の注文を金額順に取得（Ordersテーブル: LSI利用例、インデックス名 "CustomerID-TotalAmount-index"）
```bash
aws dynamodb query \
    --table-name Orders \
    --index-name CustomerID-TotalAmount-index \
    --key-condition-expression "CustomerID = :custId" \
    --expression-attribute-values '{":custId": {"S": "USER123"}}' \
    --scan-index-forward false
```

### 5.3 注文状態で全体検索（Ordersテーブル: GSI利用例、インデックス名 "OrderStatus-OrderDate-index"）
```bash
aws dynamodb query \
    --table-name Orders \
    --index-name OrderStatus-OrderDate-index \
    --key-condition-expression "OrderStatus = :status" \
    --expression-attribute-values '{":status": {"S": "Shipped"}}' \
    --scan-index-forward true
```

### 5.4 ユーザーのショッピングカート内容取得（ShoppingCartテーブル）
```bash
aws dynamodb query \
    --table-name ShoppingCart \
    --key-condition-expression "UserID = :uid" \
    --expression-attribute-values '{":uid": {"S": "USER123"}}'
```

---

## 6. システム運用・注意点

- **整合性:**  
  - RDB側はACIDトランザクションによりデータ整合性を保証  
  - DynamoDBは必要に応じた整合性（強整合性 vs 最終的整合性）を設定

- **パフォーマンス:**  
  - 高トラフィック時は、DynamoDBのキャパシティ設定やRDBのリードレプリカ・キャッシュ（例：Redis）を活用

- **セキュリティ:**  
  - IAMポリシー、VPC、暗号化、監査ログを活用し、各データベースのアクセス制御を強化

- **データ連携:**  
  - イベント駆動（例：SQS、Lambda）やバッチ処理で、RDBとDynamoDB間のデータ連携を実現

---

## 7. まとめ

- **ハイブリッドアーキテクチャ:**  
  RDBは商品、在庫、ユーザー、決済など整合性と複雑なクエリが必要な領域に、DynamoDBは注文履歴やショッピングカートなど高速スループットが求められる領域に最適  
- **データ挿入のタイミング:**  
  購入処理時に、RDBとDynamoDBの両方に必要なデータを書き込み、ユーザー体験とシステム整合性の両立を図る  
- **拡張性:**  
  DynamoDBテーブルを複数（Orders、ShoppingCartなど）持つことで、各アクセスパターンに合わせた最適なデータ管理が可能
