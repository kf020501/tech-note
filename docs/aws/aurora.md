# Aurora

## DBの作成

1. Aurora and RDS を開く
2. データベースの作成をクリック

今回は下記の設定で作成

| 項目                       | 設定値                                              | 備考       |
| -------------------------- | --------------------------------------------------- | ---------- |
| データベース作成方法を選択 | 標準作成                                            |            |
| エンジンのタイプ           | Aurora (PostgreSQL Compatible)                      |            |
| 利用可能なバージョン       | Aurora PostgreSQL (Compatible with PostgreSQL 16.6) |            |
| テンプレート               | 本番稼働用                                          |            |
| DB クラスター識別子        | aurora-test                                         |            |
| マスターユーザー名         | postgres                                            |            |
| 認証情報管理               | セルフマネージド                                    |            |
| マスターパスワード         | ****\*\*\*\*****                                    |            |
| クラスターストレージ設定   | Aurora I/O 最適化                                   | どう違う？ |
| インスタンスの設定         | Serverless v2                                       | どう違う？ |
| 容量の範囲                 | 8 GB - 64 GB                                        |            |
| 可用性と耐久性             | Aurora レプリカを作成しない                         |            |
| 容量の範囲                 | 8 GB - 64 GB                                        |            |

## 参考資料

- [Amazon Aurora の開始方法 - Amazon Aurora](https://docs.aws.amazon.com/ja_jp/AmazonRDS/latest/AuroraUserGuide/CHAP_GettingStartedAurora.html)
- [Amazon Auroraを作成してみた | DevelopersIO](https://dev.classmethod.jp/articles/lim-rds-aurora/)
