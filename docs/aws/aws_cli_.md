AWS CLI Setup
================================================================================

PCなどに導入すると、ブラウザからでなくCLIでAWSを操作できるようになる。  


初期設定
--------------------------------------------------------------------------------

### アクセスキーの発行(AWS側)

事前準備として、CLIでアクセスしたいユーザーでアクセスキーを発行する必要がある。

IAM > ユーザー > セキュリティ認証情報 画面に移動

1. 「アクセスキーを作成」をクリック
2. 「コマンドラインインターフェイス (CLI)」 を選択し「次へ」をクリック
3. 説明を入力

アクセスキー/シークレットアクセスキーが発行されるので、控えておく。

### インストール(クライアントOS側)

今回はAlmaLinux8.xに導入するサンプル手順を記載

インストール
```
dnf install unzip
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

インストール済みで更新する場合は以下
```
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install --bin-dir /usr/local/bin --install-dir /usr/local/aws-cli --update
```

[AWS CLIの最新バージョンのインストールまたは更新 - AWS Command Line Interface](https://docs.aws.amazon.com/ja_jp/cli/latest/userguide/getting-started-install.html)

動作確認
```sh
aws --version

# 実行結果 例
# aws-cli/2.15.53 Python/3.11.8 Linux/4.18.0-348.2.1.el8_5.x86_64 exe/x86_64.almalinux.8
```

### クライアント初期設定

```sh
# 現在の設定を確認
aws configure list

# 設定値を入力
aws configure

    # 実行例:
    # [manager@awscli ~]$ aws configure
    # AWS Access Key ID [None]: ★ 事前に作成したアクセスキーを入力
    # AWS Secret Access Key [None]: ★ 事前に作成したシークレットアクセスキ―を入力
    # Default region name [None]: ★ ap-northeast-1 を入力(東京リージョン)
    # Default output format [None]: そのままEnter

# 設定情報は ~/.aws/credentials, ~/.aws/configなどに保存されている
```


使い方メモ
--------------------------------------------------------------------------------

### 出力結果フォーマット

- `aws configure`のDefault output formatでデフォルト値を指定可能
- コマンドに`--output table` などと指定も可能

以下はEC2を一覧表示する例

jsonの例
```text
[manager@awscli ~]$ aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Type:InstanceType,PublicIP:PublicIpAddress}" --output json
[
    [
        {
            "ID": "i-xxxxxxxxxxxxxxxxx",
            "State": "stopped",
            "Type": "t2.nano",
            "PublicIP": null
        }
    ]
]
```

tableの例
```text
[manager@awscli ~]$ aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Type:InstanceType,PublicIP:PublicIpAddress}" --output table
-----------------------------------------------------------
|                    DescribeInstances                    |
+----------------------+-----------+----------+-----------+
|          ID          | PublicIP  |  State   |   Type    |
+----------------------+-----------+----------+-----------+
|  i-xxxxxxxxxxxxxxxxx |  None     |  stopped |  t2.nano  |
+----------------------+-----------+----------+-----------+
```
textの例
```text
[manager@awscli ~]$ aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Type:InstanceType,PublicIP:PublicIpAddress}" --output text
i-xxxxxxxxxxxxxxxxx     None    stopped t2.nano
```

### ページ送り回避

結果が長い場合、ページ送りされる。  
挙動は、環境変数`$AWS_PAGER`で指定されている模様。

単発でページ送りさせない場合
```sh
AWS_PAGER="" aws ec2 describe-instances --instance-ids i-xxxxxxxxxxxxxxxxx
```

恒久的に無効にする場合
```sh
export AWS_PAGER=""
aws ec2 describe-instances --instance-ids i-xxxxxxxxxxxxxxxxx
```

### プロファイルについて

【configファイルの記述方法】  

defaultプロファイルは  
```
[default]
region = ap-northeast-1
cli_pager=
```  
非defaultプロファイルはセクション名に「profile」を付けて記述する必要がある  
```
[profile test]
region = ap-northeast-1
cli_pager=
```  

【credentialsファイルの記述方法】  
credentialsファイルでは、非defaultプロファイルも単にプロファイル名を記述すればよい  
```
[default]
aws_access_key_id = AAAA
aws_secret_access_key = BBBB

[test]
aws_access_key_id = CCCC
aws_secret_access_key = DDDD
```  

【プロファイル切り替え方法】  
環境変数でAWS_PROFILEを設定すれば、該当プロファイルの設定が有効になる  
```
export AWS_PROFILE="test"
```

ユーザー情報の確認
--------------------------------------------------------------------------------

```sh
aws sts get-caller-identity
```

結果例
```json
{
    "UserId": "xxxxxxxxxxxxxxxxxxxxx",
    "Account": "123456789012",
    "Arn": "arn:aws:iam::123456789012:user/YourName"
}
```

おまけ: ユーザー名の取得
```sh
# 現在のIAMユーザーのARNを取得
IAM_ARN=$(aws sts get-caller-identity --query Arn --output text)
# ARNからユーザー名を抽出（例: arn:aws:iam::123456789012:user/YourUserName から YourUserName を取得）
IAM_USER=$(echo $IAM_ARN | awk -F'/' '{print $NF}')
```


EC2
--------------------------------------------------------------------------------

### 全てのインスタンスを確認

一覧の確認
```sh
aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,State:State.Name,Type:InstanceType,PublicIP:PublicIpAddress}" --output table
```
実行例
```
-----------------------------------------------------------
|                    DescribeInstances                    |
+----------------------+-----------+----------+-----------+
|          ID          | PublicIP  |  State   |   Type    |
+----------------------+-----------+----------+-----------+
|  i-xxxxxxxxxxxxxxxxx |  None     |  stopped |  t2.nano  |
+----------------------+-----------+----------+-----------+
```

### 特定のインスタンスを確認

```sh
# すべて？の方法を表示
aws ec2 describe-instances --instance-ids i-xxxxxxxxxxxxxxxxx

# 指定した情報のみを表示
aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,Type:InstanceType,State:State.Name,PublicIP:PublicIpAddress,PrivateIP:PrivateIpAddress,LaunchTime:LaunchTime}" --instance-ids i-xxxxxxxxxxxxxxxxx
```
設定に関する詳細な情報が出てくる


S3
--------------------------------------------------------------------------------

バケット名はグローバルで一意のため注意

```sh
your_bucket_name="cli-test-$(date +%s)"
your_region="ap-northeast-1"
your_file_name="sample.txt"

touch ${your_file}

# バケットの作成
aws s3api create-bucket --bucket ${your_bucket_name} --region ${your_region} --create-bucket-configuration LocationConstraint=${your_region}

# バケット・ファイルの確認
aws s3 ls
aws s3 ls s3://${your_bucket_name}

# ファイルをアップロード
aws s3 cp ./${your_file_name} s3://${your_bucket_name}/
aws s3 ls s3://${your_bucket_name}

    # 実行結果
    # [manager@awscli ~]$ aws s3 cp ./${your_file_name} s3://${your_bucket_name}/
    # upload: ./sample.txt to s3://cli-test-1716149065/sample.txt
    # [manager@awscli ~]$ aws s3 ls s3://${your_bucket_name}
    # 2024-05-19 20:18:28          0 sample.txt
    # [manager@awscli ~]$

# ファイルのダウンロード
rm ./${your_file_name}
aws s3 cp s3://${your_bucket_name}/${your_file_name} ./

    # 実行結果
    # [manager@awscli ~]$ aws s3 cp s3://${your_bucket_name}/${your_file_name} ./
    # download: s3://cli-test-1716149065/sample.txt to ./sample.txt
    # [manager@awscli ~]$

# ファイルの削除
aws s3 rm s3://${your_bucket_name}/${your_file_name}
aws s3 ls s3://${your_bucket_name}

    # 実行結果
    # [manager@awscli ~]$ aws s3 rm s3://${your_bucket_name}/${your_file_name}
    # delete: s3://cli-test-1716149065/sample.txt
    # [manager@awscli ~]$ aws s3 ls s3://${your_bucket_name}
    # [manager@awscli ~]$

# バケットの削除
aws s3api delete-bucket --bucket ${your_bucket_name} --region ${your_region}
aws s3 ls
```


Session Manager プラグイン
--------------------------------------------------------------------------------

手順に従いインストールする:  
[AWS CLI 用の Session Manager プラグインをインストールする - AWS Systems Manager](https://docs.aws.amazon.com/ja_jp/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html)


```sh
aws ssm start-session --target <instance-id>
```
