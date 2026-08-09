---
title: "Apatch"
tags: ["memo"]
date: 2022-02-23
weight: 100
draft: false
---

# Apatch勉強メモ

[Apache httpd 入門 |](https://weblabo.oscasierra.net/apache/)

```
[root@centos7 ~]# cat /etc/redhat-release
CentOS Linux release 7.9.2009 (Core)
```

## インストール

```sh
cat /etc/redhat-release
> CentOS Linux release 7.9.2009 (Core)

yum update -y
yum install httpd -y
httpd -version
> Server version: Apache/2.4.6 (CentOS)
> Server built:   Jan 25 2022 14:08:43

systemctl enable httpd.service
systemctl start httpd.service
systemctl stop firewalld.service        # 今回は雑にfirewall止めちゃった
systemctl disable firewalld.service 
```

## セキュリティ

[攻撃を受ける前に見直すApacheの基本的なセキュリティ10のポイント - レムシステム エンジニアブログ](https://www.rem-system.com/apache-security01/)

## VirutalHost 設定

そもそもVirutalHostとは？   
1台のサーバで、複数の異なるドメインのサイトを運用可能とする機能。   

例として、sample1.centos.local と sample2.centos.local の設定を行う。


### 共通設定
```sh
# /etc/httpd/conf/httpd.conf(共通部分) 設定変更/確認
cat /etc/httpd/conf/httpd.conf | grep IncludeOptional
> IncludeOptional conf.d/*.conf

vi /etc/httpd/conf/httpd.conf

以下を追加
--------------------
NameVirtualHost *:80
--------------------
```

### ドメインごとの設定

```sh
# ドメインごとの DocumentRoot と サンプルファイル作成
mkdir /var/www/sample1.centos.local
chown apache.apache /var/www/sample1.centos.local
echo "This is sample1.centos.local" > /var/www/sample1.centos.local/index.html
# 2
mkdir /var/www/sample2.centos.local
chown apache.apache /var/www/sample2.centos.local
echo "This is sample2.centos.local" > /var/www/sample2.centos.local/index.html
# 3
mkdir /var/www/sample3.centos.local
chown apache.apache /var/www/sample3.centos.local
echo "This is sample3.centos.local" > /var/www/sample3.centos.local/index.html

# ドメインごとの設定ファイル作成
vi /etc/httpd/conf.d/sample1.centos.local.conf  # sample1
vi /etc/httpd/conf.d/sample2.centos.local.conf  # sample2
vi /etc/httpd/conf.d/sample3.centos.local.conf  # sample3
```
以下のように記載 `sample1.centos.local`は必要に応じて変更
```
<VirtualHost *:80>
    DocumentRoot /var/www/sample1.centos.local
    ServerName sample1.centos.local

    # 以下必須ではないが、デフォルトだと各ドメインのログが同一個所に出力されるので、分ける
    ErrorLog logs/sample1.centos.local-error_log
    CustomLog logs/sample1.centos.local-access_log common
</VirtualHost>
```
サービス再起動
```sh
systemctl reload httpd
```


### 確認
名前解決できればなんでも大丈夫みたいだが、今回はwindowsから確認するのでhostsに記載した。    
`C:\Windows\System32\drivers\etc\hosts` いっつも忘れる

```
10.30.0.41         sample1.centos.local
10.30.0.41         sample2.centos.local
```
ブラウザから、各ドメインへアクセス  
`This is sample().centos.local` が表示されることを確認


## BASIC認証

- 非暗号化 (なので、ローカルなどで簡易的に使用)
- 配下のファイルすべてに制限がかかる
- .htaccess ファイルを使用するやり方もあるみたい(今回未記載 /etc配下をいじれないときなどに使用？)

```sh
# "user01" というユーザを作成 -c で指定したパスにhtpasswdファイルが作成される
htpasswd -c /etc/httpd/htpasswd user01
※ コマンド実行後、PWを入力する

    # 実行例
    # [root@centos7 ~]# htpasswd -c /etc/httpd/htpasswd user01
    # New password: 
    # Re-type new password: 
    # Adding password for user user01
    # [root@centos7 ~]#
    # [root@centos7 ~]# cat /etc/httpd/htpasswd
    # user01:$apr1$QQWCvAtZ$ZR7bUZqkbdHY0zKE4MpKM.
    # [root@centos7 ~]# 

# ユーザー追加(htpasswd作成後)
htpasswd /etc/httpd/htpasswd user02
※ コマンド実行後、PWを入力する

# htpasswdのアクセス変更
chown apache:apache /etc/httpd/htpasswd
chmod 600 /etc/httpd/htpasswd

# httpd.conf編集
vi /etc/httpd/conf/httpd.conf

以下のように記載
------------------------------
<Directory "/var/www/html">
    # 認証の種類 Basic
    AuthType Basic
    # ダイアログに表示する名前の設定だが、実際には表示されない？
    AuthName "auth"
    # htpasswdファイルのパスを指定
    AuthUserFile /etc/httpd/htpasswd
    # 認証ユーザー valid-userで全ユーザーが対象
    Require valid-user
</Directory>
------------------------------

VirutalHostの場合は、以下のように <VirtualHost>内に記載する
------------------------------
<VirtualHost *:80>
    DocumentRoot /var/www/sample1.centos.local
    ServerName sample1.centos.local
    ErrorLog logs/sample1.centos.local-error_log
    CustomLog logs/sample1.centos.local-access_log common
    <Directory "/var/www/sample1.centos.local">
        AuthType Basic
        AuthName "auth"
        AuthUserFile /etc/httpd/htpasswd
        Require valid-user
    </Directory>
</VirtualHost>
------------------------------

# 再読み込み
systemctl reload httpd.service
```

## Digest認証

```sh
vi sample2.centos.local.conf
--------------------
<VirtualHost *:80>
    DocumentRoot /var/www/sample2.centos.local
    ServerName sample2.centos.local

    # 以下必須ではないが、デフォルトだと各ドメインのログが同一個所に出力されるので、分ける
    ErrorLog logs/sample2.centos.local-error_log
    CustomLog logs/sample2.centos.local-access_log common
    <Directory "/var/www/sample2.centos.local">
        AuthType Digest
        AuthName "Digest Authentication"
        AuthDigestDomain /
        AuthUserFile /etc/httpd/conf/.htdigest
        Require valid-user
    </Directory>

</VirtualHost>
--------------------

# ユーザー登録
# 構文 htdigest -c <設定ファイル> <AuthName> <ユーザー名>
# Note: -c は初回のみ指定、AuthName は 設定ファイルのAuthNameと同じ必要がある
htdigest -c /etc/httpd/conf/.htdigest "Digest Authentication" user02

    # [root@centos7 conf.d]# htdigest -c /etc/httpd/conf/.htdigest "Digest Authentication" user02
    # Adding password for user02 in realm Digest Auth.
    # New password: ※ password
    # Re-type new password: 
    # [root@centos7 conf.d]# 

systemctl restart httpd
```

## (よくわからない)サーバーアカウントでユーザー認証

[apacheでBasic認証をLixnuxアカウントでおこなう | パソコン鳥のブログ](https://pcvogel.sarakura.net/2017/03/07/31694#toc2)

そもそもインストールが上手くいかない。


```sh
# mod_authnz_external をインストール EPELリポジトリを使用
yum --enablerepo=epel install mod_authnz_external

vi /etc/httpd/conf/httpd.conf
以下を追記
--------------------
LoadModule authnz_external_module modules/mod_authnz_external.so
DefineExternalAuth pwauth pipe /usr/bin/pwauth
# 識別名(任意の名前) には pwauth を指定した
--------------------

vi /etc/httpd/conf.d/sample3.centos.local.conf
以下のように作成
--------------------
<VirtualHost *:80>
    DocumentRoot /var/www/sample3.centos.local
    ServerName sample3.centos.local

    # 以下必須ではないが、デフォルトだと各ドメインのログが同一個所に出力されるので、分ける
    ErrorLog logs/sample3.centos.local-error_log
    CustomLog logs/sample3.centos.local-access_log common
    <Directory "/var/www/sample3.centos.local">
        AuthType Basic
        AuthName "Protected Area"
        AuthBasicProvider external ★ 
        AuthExternal pwauth         ★
        require valid-user
    </Directory>
</VirtualHost>
--------------------

# 再起動
systemctl restart httpd
```

```sh
# これではないみたい
yum -y install mod_authnz_pam

[root@centos7 sample3.centos.local]# ls /etc/httpd/modules/ | grep authnz
mod_authnz_pam.so
[root@centos7 sample3.centos.local]# ls /etc/httpd/conf.d/ | grep authnz
authnz_pam.conf
[root@centos7 sample3.centos.local]# 

[root@centos7 sample3.centos.local]# systemctl restart httpd.service
Job for httpd.service failed because the control process exited with error code. See "systemctl status httpd.service" and "journalctl -xe" for details.
```


https://www.yahoo.co.jp/

## Rewrite

[Apacheのmod_rewriteモジュールの使い方を徹底的に解説 | OXY NOTES](https://oxynotes.com/?p=7392#1)

[5分でわかる！一番わかりやすいmod_rewriteの設定 ～WordPress運営者もエンジニアも必読 | トリオス](https://trios.pro/mod_rewrite-overview/)

[apache2.4でmod_rewrite を有効化する | NOARTS](https://noarts.net/archives/1059)

```sh
# モジュールの存在確認
ls /etc/httpd/modules | grep mod_rewrite.so
> mod_rewrite.so

# モジュールの有効化
vi /etc/httpd/conf/httpd.conf

以下の行を追加
--------------------
# Rewriteモジュールを追加
LoadModule rewrite_module modules/mod_rewrite.so
--------------------

以下を追加すると何故かエラー
# [root@centos7 modules]# systemctl restart httpd.service 
# Job for httpd.service failed because the control process exited with error code. See "systemctl status httpd.service" and "journalctl -xe" for details.
--------------------
# (任意) Rewriteのログ設定
RewriteLog /var/log/httpd/rewrite.log
RewriteLogLevel 9
--------------------

# 各場所によって相対パスの起点が異なったりするため注意
vi /etc/httpd/conf.d/sample3.centos.local.conf
以下のように記載
------------------------------
<VirtualHost *:80>
    DocumentRoot /var/www/sample3.centos.local
    ServerName sample3.centos.local
    ErrorLog logs/sample3.centos.local-error_log
    CustomLog logs/sample3.centos.local-access_log common

    # RewriteEngineをオンに
    RewriteEngine on
    # ベースを/hogeにする(任意)
    RewriteBase /re
    RewriteRule . http://www.yahoo.co.jp [R=301,L]
</VirtualHost>
------------------------------

以下のように記載
--------------------
RewriteEngine on  # RewriteEngineをオンに
RewriteBase /re # ベースを/hogeにする(任意)
RewriteRule . http://www.yahoo.co.jp [R=301,L]
--------------------
```

```
<VirtualHost *:80>
    DocumentRoot /var/www/sample3.centos.local
    ServerName sample3.centos.local
    ErrorLog logs/sample3.centos.local-error_log
    CustomLog logs/sample3.centos.local-access_log common

    <IfModule mod_rewrite.so>
        # RewriteEngineをオンに
        RewriteEngine on
        # ベースを/hogeにする(任意)
        RewriteBase /re
        RewriteCond %{REQUEST_URI} ^(.*)$
        RewriteRule ^(.*)$ http://www.yahoo.co.jp [R=301,L]
    </IfModule>
</VirtualHost>
```


http://sample3.centos.local/
http://sample3.centos.local/


https://ja.getdocs.org/how-to-set-up-mod-rewrite-for-apache-on-centos-7/

https://rin-ka.net/apache-init/#toc7
