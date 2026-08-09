# Terraform Setup

## 事前準備

### Terraformインストール(作業端末)

以下の公式サイトに手順の記載がある(リポジトリ追加含む)が、  
[Install | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/install?product_intent=terraform)

Teraformは1つの実行ファイルのみで動作するため、今回は実行ファイルを配置してパスを通す。

```sh
terraform --version
    # 実行例
    # Terraform v1.10.0
    # on linux_amd64
```

### Access Keyの作成(AWS)

Terraformを実行するAWSユーザーのアクセスキーを発行する必要がある。

IAM > ユーザー > セキュリティ認証情報 画面に移動

1. 「アクセスキーを作成」をクリック
2. 「コマンドラインインターフェイス (CLI)」 を選択し「次へ」をクリック
3. 説明を入力

アクセスキー/シークレットアクセスキーが発行されるので、控えておく。

### ssh用キーペアの作成(AWS)



## 設定ファイルの書き方概要

定義ファイルの内容は、大きく分けて2つに分かれている。

- provider: 接続先の定義
- resource: 実際に設定するリソースの定義

```tf
provider "aws" {
  region = "ap-northeast-1"
  access_key = "your_access_key_id"
  secret_key = "your_secret_access_key"
}

resource "<provider>_<resource_type>" "name" {
  key1 = "value1"
  key2 = "value2"
}
```

リソースごとの書き方は以下で確認   

- provider: [Docs overview | hashicorp/aws | Terraform | Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- resource - インスタンス: [aws_instance | Resources | hashicorp/aws | Terraform | Terraform Registry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)


## クイックスタート

### 作業ディレクトリの作成

```
mkdir terraform_test
cd terraform_test
```

### 設定ファイルの作成

main_infra_setup.tf
```tf
# プロバイダの設定
provider "aws" {
  region = "ap-northeast-1"
  # access_key = "your_access_key_id"       # ファイルに記載せず、環境変数"AWS_ACCESS_KEY_ID"に指定
  # secret_key = "your_secret_access_key"   # ファイルに記載せず、環境変数"AWS_SECRET_ACCESS_KEY"に指定
}

# VPCの作成
resource "aws_vpc" "terraform_test_vpc" {
  cidr_block = "10.255.0.0/16"

  tags = {
    Name = "terraform_test_vpc"
  }
}

# サブネットの作成
resource "aws_subnet" "terraform_test_subnet" {
  vpc_id     = aws_vpc.terraform_test_vpc.id
  cidr_block = "10.255.1.0/24"

  tags = {
    Name = "terraform_test_subnet"
  }
}

# EC2インスタンスの作成
resource "aws_instance" "terraform_test_ec2" {
  ami           = "ami-0091f05e4b8ee6709" # AmazonLinux2023 AMI
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.terraform_test_subnet.id

  tags = {
    Name = "terraform_test_ec2"
  }
}
```

### access_key等の環境変数設定

事前に発行したアクセスキー/シークレットアクセスキーを指定。
```sh
export AWS_ACCESS_KEY_ID="your_access_key_id"
export AWS_SECRET_ACCESS_KEY="your_secret_access_key"
```

### 作業ディレクトリの初期化

```sh
terraform init
```

実行例
```text
[user@hostname terraform_test]$ terraform init
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/aws...
- Installing hashicorp/aws v5.63.0...
- Installed hashicorp/aws v5.63.0 (signed by HashiCorp)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

### ドライラン

```sh
terraform plan
```
変更されるリソースが表示されるので、想定通りか確認。

- 作成されるリソースには行頭に`+`  
- 削除されるリソースには行頭に`-`


実行例
```text
[user@hostname terraform_test]$ terraform plan

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.terraform_test_ec2 will be created
  + resource "aws_instance" "terraform_test_ec2" {
      + ami                                  = "ami-0091f05e4b8ee6709"
      + arn                                  = (known after apply)
      + associate_public_ip_address          = (known after apply)
      + availability_zone                    = (known after apply)
      + cpu_core_count                       = (known after apply)
      + cpu_threads_per_core                 = (known after apply)
      + disable_api_stop                     = (known after apply)
      + disable_api_termination              = (known after apply)
      + ebs_optimized                        = (known after apply)
      + get_password_data                    = false
      + host_id                              = (known after apply)
      + host_resource_group_arn              = (known after apply)
      + iam_instance_profile                 = (known after apply)
      + id                                   = (known after apply)
      + instance_initiated_shutdown_behavior = (known after apply)
      + instance_lifecycle                   = (known after apply)
      + instance_state                       = (known after apply)
      + instance_type                        = "t2.micro"
      + ipv6_address_count                   = (known after apply)
      + ipv6_addresses                       = (known after apply)
      + key_name                             = (known after apply)
      + monitoring                           = (known after apply)
      + outpost_arn                          = (known after apply)
      + password_data                        = (known after apply)
      + placement_group                      = (known after apply)
      + placement_partition_number           = (known after apply)
      + primary_network_interface_id         = (known after apply)
      + private_dns                          = (known after apply)
      + private_ip                           = (known after apply)
      + public_dns                           = (known after apply)
      + public_ip                            = (known after apply)
      + secondary_private_ips                = (known after apply)
      + security_groups                      = (known after apply)
      + source_dest_check                    = true
      + spot_instance_request_id             = (known after apply)
      + subnet_id                            = (known after apply)
      + tags                                 = {
          + "Name" = "terraform_test_ec2"
        }
      + tags_all                             = {
          + "Name" = "terraform_test_ec2"
        }
      + tenancy                              = (known after apply)
      + user_data                            = (known after apply)
      + user_data_base64                     = (known after apply)
      + user_data_replace_on_change          = false
      + vpc_security_group_ids               = (known after apply)

      + capacity_reservation_specification (known after apply)

      + cpu_options (known after apply)

      + ebs_block_device (known after apply)

      + enclave_options (known after apply)

      + ephemeral_block_device (known after apply)

      + instance_market_options (known after apply)

      + maintenance_options (known after apply)

      + metadata_options (known after apply)

      + network_interface (known after apply)

      + private_dns_name_options (known after apply)

      + root_block_device (known after apply)
    }

  # aws_subnet.terraform_test_subnet will be created
  + resource "aws_subnet" "terraform_test_subnet" {
      + arn                                            = (known after apply)
      + assign_ipv6_address_on_creation                = false
      + availability_zone                              = (known after apply)
      + availability_zone_id                           = (known after apply)
      + cidr_block                                     = "10.255.1.0/24"
      + enable_dns64                                   = false
      + enable_resource_name_dns_a_record_on_launch    = false
      + enable_resource_name_dns_aaaa_record_on_launch = false
      + id                                             = (known after apply)
      + ipv6_cidr_block_association_id                 = (known after apply)
      + ipv6_native                                    = false
      + map_public_ip_on_launch                        = false
      + owner_id                                       = (known after apply)
      + private_dns_hostname_type_on_launch            = (known after apply)
      + tags                                           = {
          + "Name" = "terraform_test_subnet"
        }
      + tags_all                                       = {
          + "Name" = "terraform_test_subnet"
        }
      + vpc_id                                         = (known after apply)
    }

  # aws_vpc.terraform_test_vpc will be created
  + resource "aws_vpc" "terraform_test_vpc" {
      + arn                                  = (known after apply)
      + cidr_block                           = "10.255.0.0/16"
      + default_network_acl_id               = (known after apply)
      + default_route_table_id               = (known after apply)
      + default_security_group_id            = (known after apply)
      + dhcp_options_id                      = (known after apply)
      + enable_dns_hostnames                 = (known after apply)
      + enable_dns_support                   = true
      + enable_network_address_usage_metrics = (known after apply)
      + id                                   = (known after apply)
      + instance_tenancy                     = "default"
      + ipv6_association_id                  = (known after apply)
      + ipv6_cidr_block                      = (known after apply)
      + ipv6_cidr_block_network_border_group = (known after apply)
      + main_route_table_id                  = (known after apply)
      + owner_id                             = (known after apply)
      + tags                                 = {
          + "Name" = "terraform_test_vpc"
        }
      + tags_all                             = {
          + "Name" = "terraform_test_vpc"
        }
    }

Plan: 3 to add, 0 to change, 0 to destroy.

───────────────────────────────────────────────────────────

Note: You didn't use the -out option to save this plan, so Terraform can't guarantee to take exactly these actions if you run "terraform apply" now.
```

### リソース作製(適用)

```sh
terraform apply
```
変更されるリソースが表示されるので、想定通りか確認。

- 作成されるリソースには行頭に`+`  
- 削除されるリソースには行頭に`-`

"Do you want to perform these actions?"と聞かれるので、問題なければyesを解答。

実行例
```text
[user@hostname terraform_test]$ terraform apply

Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # aws_instance.terraform_test_ec2 will be created
  + resource "aws_instance" "terraform_test_ec2" {
        :
    }

  # aws_subnet.terraform_test_subnet will be created
  + resource "aws_subnet" "terraform_test_subnet" {
        :
    }

  # aws_vpc.terraform_test_vpc will be created
  + resource "aws_vpc" "terraform_test_vpc" {
        :
    }

Plan: 3 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

aws_vpc.terraform_test_vpc: Creating...
aws_vpc.terraform_test_vpc: Creation complete after 2s [id=vpc-xxxxxxxxxxxxxxxx]
aws_subnet.terraform_test_subnet: Creating...
aws_subnet.terraform_test_subnet: Creation complete after 0s [id=subnet-xxxxxxxxxxxxxxxx]
aws_instance.terraform_test_ec2: Creating...
aws_instance.terraform_test_ec2: Still creating... [10s elapsed]
aws_instance.terraform_test_ec2: Still creating... [20s elapsed]
aws_instance.terraform_test_ec2: Still creating... [30s elapsed]
aws_instance.terraform_test_ec2: Creation complete after 32s [id=i-xxxxxxxxxxxxxxxx]

Apply complete! Resources: 3 added, 0 changed, 0 destroyed.
```

### 作成されたことを確認

マネージメントコンソールで確認するのもいいが、
以下コマンドでも確認可能

```sh
# terraformで作成したリソースの一覧を確認
terraform state list

# リソースの詳細情報を確認
terraform state show <listで確認したリソース情報>
```

### リソース削除

```sh
terraform destroy
```

削除されるリソースが表示されるので、想定通りか確認。  
"Do you really want to destroy all resources?"と聞かれるので、問題なければyesを解答。

## 変数

- コマンド実行時に引数として指定
- 変数用設定ファイルを作製

### コマンド実行時に引数として指定

以下のケースでは、`terraform apply`時に値を渡す必要がある。

```
variable "subnet_cider" {
    description = "sample"
    # default
    # type
}

resouce "aws_subnet" "test-subnet" {
    vpc_id = aws_vpc.test-vpc.id
    cider_block = var.subnet_cider
}
```
```sh
# 対話形式で解凍するパターン
terrafrom apply

# コマンド実行時に引数で与えるパターン
terraform apply -var "subnet_cider=10.30.0.0/24"
```

### 変数用設定ファイルを作製するパターン

iac.tfvers
```
subnet_cider = "10.30.0.0/24"
```

```sh
# 対話形式で解凍するパターン
terrafrom apply -var-file iac.tfvers
```


環境分離
--------------------------------------------------------------------------------

以下のように、共通部分をmodulesとして作成するといいみたい。  
env内のmain.tfに環境固有の変数などを指定し、

```
terraform-project/
├── modules/
│   └── vpc/
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf       # （必要に応じて出力値を定義）
├── env/
│   ├── test/
│   │   ├── main.tf          # テスト環境用のルートモジュール設定
│   │   └── terraform.tfvars # （必要なら環境固有の変数定義）
│   └── prod/
│       ├── main.tf          # 本番環境用のルートモジュール設定
│       └── terraform.tfvars # （必要なら環境固有の変数定義）
└── README.md                # プロジェクト概要や利用方法のドキュメント
```

env/test/main.tf
```tf
provider "aws" {
  alias   = "test"
  region  = "ap-northeast-1"
  profile = "test-account-profile"  # テストアカウント用の認証情報
}

module "vpc" {
  source = "../../modules/vpc"

  providers = {
    aws = aws.test
  }

  vpc_cidr       = "10.30.0.0/16"
  name           = "test-vpc"
  environment    = "test"
  subnet_cidrs   = ["10.30.1.0/24", "10.30.2.0/24"]
  availability_zones = ["ap-northeast-1a", "ap-northeast-1c"]
}
```

トラブルシュート
--------------------------------------------------------------------------------

### 想定外のリソース再作成が発生

terraform applyしたところ、EC2インスタンスが再作成されそうになった。特に設定を変更した覚えはない。  
表示を見たところ、"# forces replacement"という記載があり、これが変更された事が原因に見える。

```text
$ terraform apply
  :
  # module.compute.aws_instance.step_sv must be replaced ★1
-/+ resource "aws_instance" "step_sv" {
      ~ arn                                  = "arn:aws:ec2:ap-northeast-1:xxxxxxxxxx:instance/xxxxxxxxxx" -> (known after apply)
      ~ associate_public_ip_address          = false -> true # forces replacement
```

下記の形で、associate_public_ip_addressを無視する設定にしたところ、EC2として変更したと検知されなくなった。
```diff
resource "aws_instance" "step_sv" {
  ami                    = var.ami_id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[0]
  associate_public_ip_address = true
  vpc_security_group_ids = var.security_group_ids
  key_name               = aws_key_pair.aws_default_key.key_name
+ lifecycle {
+   ignore_changes = [
+     # 停止などでIPアドレスが変更になっても無視する
+     associate_public_ip_address
+   ]
+ }
}
```

[Terraformで作成したEC2を停止したら差分が！instance_stateをignore_changesしたるでぇ！←無駄無駄ァ！](https://zenn.dev/ninomiya_hy/articles/f3437f331f0a0b)


参考
--------------------------------------------------------------------------------

### workspaceによる環境分離は非推奨

[Terraformの環境切り替えとフォルダ構成について](https://zenn.dev/t_shunsuke/articles/164f2c4ff06584#workspace-%E3%81%AB%E3%82%88%E3%82%8B%E6%96%B9%E6%B3%95-(%E5%9F%BA%E6%9C%AC%E7%9A%84%E3%81%AB%E3%81%AF%E9%9D%9E%E6%8E%A8%E5%A5%A8))

[ワークスペースの管理 | Terraform | HashiCorp Developer](https://developer.hashicorp.com/terraform/cli/workspaces#when-not-to-use-multiple-workspaces)