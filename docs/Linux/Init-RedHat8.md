# Install Redhat 8.x 初期設定

## 概要

- CentOS騒動を受けて(?) Red Hat Developer Programに登録すると、16台までRHELが使えるよ。
- [Red Hat Developer Programに参加して最新技術を学習しよう - 赤帽エンジニアブログ](https://rheb.hatenablog.com/entry/developer-program)   
- CentOS代替品(RedHat系)を模索しているけど、出来るだけシェアが多いものを使いたいので、決定はもう少したってからかな。
    - AlmaLinux, RockyLinux, OracleLinux 雰囲気的にはAlmaLinuxか？
    - AmazonLinuxをオンプレでも使えるって聞いたことがあるけど、さっと調べた感じESXiでやるには手順がめんどくさそうだった。
        - Cloud init あると比較的簡単。Proxmox余裕だった。


## サブスクリプション関連

### アカウント作成・確認

- 開発者用アカウントを作成
    - Red Hat Developerサイトで アカウント作成する必要があるよ。
    - [Cloud Developer Tutorials and Software from Red Hat | Red Hat Developer](https://developers.redhat.com/)
- Red Hat Enterprise Linux ダウンロード
    - [Enterprise Linux Containers Tutorials and Training | Red Hat Developer](https://developers.redhat.com/topics/linux)
- サブスクリプション確認場所
    - [Red Hat Customer Portal - Access to 24x7 support and knowledge](https://access.redhat.com/)
    -  「概要」 で Red Hat Developer Subscriptionがあることが確認できる
    -  「システム」で登録してあるRHELが確認できる


### サブスク登録 - インストール時

- インストール画面の「RED HATに接続」から、Red Hat Developerのアカウントを入力し登録
- (あたりまえだけど)インターネットにつないでいないといけない
- 登録すると、「ソフトウェアの選択」のチェックが変更になる？(推奨されたもののチェックが勝手に入る？)
    - 8.6 でなおった?


### サブスク登録 - インストール後

- インストール時に指定しなくても、後からコマンドで登録も可能。
- コマンドで登録した場合、その後に [Customer Portal](https://access.redhat.com/management/systems) でサブスクの割り当てが別途必要?

```sh
# 登録 パターン1: 対話型
subscription-manager register 

# 登録 パターン2: 一括入力
subscription-manager register --username <username> --password <password> --name <SYSTEM_NAME> 

        # --username: Red Hat Developer アカウントのユーザ名
        # --password: Red Hat Developer アカウントのパスワード
        # --name:     このホストの任意の登録名

# 参考
subscription-manager list       # 確認
subscription-manager refresh    # サブスク再読み込み
subscription-manager unregister # サブスク解除
```

[第5章 インストール後の作業の完了 Red Hat Enterprise Linux 8 | Red Hat Customer Portal](https://access.redhat.com/documentation/ja-jp/red_hat_enterprise_linux/8/html/performing_a_standard_rhel_installation/post-installation-tasks_installing-RHEL#subman-rhel8-setup_post-installation-tasks)


## バージョン確認

`hostnamectl`, `cat /etc/os-release`, `cat /etc/redhat-release`


## ユーザー作成

```sh
### ユーザ名「UserName」を作成・設定するサンプル ### 

useradd -m UserName         # UserName を作成 (-m ホームディレクトリ作成)
passwd UserName             # パスワードを変更 (コマンド実行後入力を求められる)
usermod -G wheel UserName   # sudoを使えるように wheelグループに追加(RedHat系) -G で補助グループに追加 -gで主グループ指定

## 補足
/etc/passwd | grep UserName               # 設定確認
  > UserName:x:1001:1001::/home/UserName:/bin/bash
userdel -r UserName                       # UserName を削除 (-r ホームディレクトリも削除)
usermod -s /bin/bash UserName             # ログインシェルを指定(フルパス)
useradd -m UserName -g wheel -s /bin/bash # ★作成時一括指定
usermod -aG GrpName UserName              # GrpName を UserName の補助グループに追加(-aを付けないと置き換えになる)

groupadd GroupName        # グループを作成
cat /etc/group            # グループを確認
gpasswd -d UserName wheel # wheelから UserNameをはずす
```
管理者権限をつけたい場合(sudoを使用したい場合)、visudoコマンドで/etc/sudoersに追記する必要があるが、  
RHEL8の場合`%wheel ALL=(ALL) ALL`がデフォルトで記載されている。

```
UserName        ALL=(ALL)       ALL
```
このため、ユーザーをwheelグループに追加すれば `/etc/sudoers` の編集はせずとも管理者権限ユーザーとして利用可能。

```
useradd -m -s /bin/bash -G wheel manage
passwd manage
```

## ssh設定

- インストール済み
設定は`/etc/ssh/sshd_config` 

## ネットワーク関連

### ip設定

- NetworkManager ありなので、`nmtui`, `nmcli`が使用可能。
- nmcli connection up ens160 で再起動？

### ルーティングテーブル



## NTPクライアント設定

- RHEL8にNTPはない模様... ---> `chronyc`を使ってねってさ    
- [【RHEL8/CentOS8】NTPは死んだ。時代はChrony。 - Qiita](https://qiita.com/thzking/items/c2bcf7d60963b4dab7b6)
- なお、初めからインストールされていた`chronyc`

```sh
# インストール 今回は初めからインストールされていたため不要
# yum install -y chrony

# 設定ファイル編集
vi /etc/chrony.conf         

    必要に応じて以下を記載

    # 接続先設定(iburstを付けると同期が早くなるんだっけ)
    pool ntp.pool.xxxxx.com iburst 
    server ntp.xxxxx.com iburst 
    server 10.30.0.xxx iburst 

    # サーバとして動作する場合のポート指定 0にするとクライアント専用となる
    port 0

systemctl enable chronyd
systemctl restart chronyd

# 同期状況確認
chronyc sources

    MS Name/IP address         Stratum Poll Reach LastRx Last sample
    ===============================================================================
    ^* 10.30.0.xxx                    2   7   377    93  -1887ns[-4203ns] +/-   46ms

    * となっていれば同期されている。
    Reach: 過去何回NTPパケットを受け取れたか？ 8bit 8進数 全部成功で377
    LastRX: 最後の受信は何秒前か

# 補足 今すぐ同期
chronyc makestep

# 補足 ntpdateコマンドの場合は以下
ntpdate 10.30.0.xxx
```
tips
- ntpdの起動時と相手が応答しないとき、2秒間隔で8パケット確認を行い、初回の同期を高速化できる?


## ファイアウォール関連

- firewalld.service インストール済み

```sh
systemctl status firewalld.service --no-pager

# 設定確認
firewall-cmd --list-all

# 追加 例
firewall-cmd --add-port=4440/tcp --permanent
firewall-cmd --add-port=9091/{tcp,udp}
firewall-cmd --zone=public --add-service=http --permanent
firewall-cmd --zone=internal --add-port=22/tcp --permanent

# 削除 例
firewall-cmd --remove-service=http --zone=public --permanent
firewall-cmd --remove-port=9091/tcp --permanent

# 再読み込み
firewall-cmd --reload
```

## パッケージ管理

- yumも使えるが、dnfが推奨の模様。
- yum はpython2.x、dnf はpython3.xで書かれているから、とどこかで見た気がする。

```sh
# インストール済み および 利用可能なパッケージ 一覧表示
dnf list --all

# インストール済みパッケージ 表示
dnf list --installed

# 利用可能なパッケージを検索
dnf search mysql

# あるコマンドを使用するためのパッケージを検索
dnf provides rpmbuild

# 利用可能なパッケージを検索
dnf --showduplicates search xxx

# バージョンを指定してインストール
dnf install xxxxx-11.7.3-2.el8.x86_64

systemctl list-units
```


### あとからソフトウェアグループ(パッケージグループ?)をインストールする

```sh
dnf group list                           # 使用できるグループを確認
dnf group install "サーバー (GUI 使用)"  # インストール
```
"サーバー (GUI 使用)"をインストールしたとして、デフォルトでどのターゲットで起動するかを変更するには以下
```sh
# デフォルトターゲットの表示
systemctl get-default

# 現在のターゲットの表示
systemctl list-units --type target

# デフォルトターゲットの変更
systemctl set-default graphical.target 

# 上手くいかない(引き続きCLIとなる)ケースで、以下をしたら解消した。
dnf install gdm
```

### !! update失敗 1

しばらく放置していたサーバをupdateしようとしたら、以下の表示でupdateできない。  
サブスクリプションを解除>再登録しても改善しない。

```
[root@redhat8 ~]# dnf update -y
Updating Subscription Management repositories.

This system is registered to Red Hat Subscription Management, but is not receiving updates. You can use subscription-manager to assign subscriptions.

エラー: "/etc/yum.repos.d", "/etc/yum/repos.d", "/etc/distro.repos.d" には有効化されたリポジトリーがありません。
[root@redhat8 ~]#
```

`subscription-manager refresh` コマンドを実行後に再度updateしたら成功した


### !! update失敗 2

Red Hat Developer Programの期限切れの模様。

1. 以下を確認すると、サブスクリプションがなくなっている     
   https://access.redhat.com/management/subscriptions
2. ここにログインするだけで大丈夫だった(利用規約の確認?更新?はあったが)     
    [Hybrid Cloud Developer Tutorials and Software from Red Hat | Red Hat Developer](https://developers.redhat.com/)
3. 再度以下を確認すると、サブスクリプションが追加されている。   
    https://access.redhat.com/management/subscriptions
4. ここから各マシンにサブスクリプションの再割り当てが必要だった     
     https://access.redhat.com/management/systems

その後、`subscription-manager refresh`を実行したら`dnf update`が成功した


### !! update失敗(AlmaLinux)

インストール時以下のようなエラー

```text
 GPG Keys are configured as: file:///etc/pki/rpm-gpg/RPM-GPG-KEY-AlmaLinux
The downloaded packages were saved in cache until the next successful transaction.
You can remove cached packages by executing 'dnf clean packages'.
Error: GPG check FAILED
```

以下のコマンドでGPGキーを更新すればOKだった
```sh
rpm --import https://repo.almalinux.org/almalinux/RPM-GPG-KEY-AlmaLinux
```

## 言語設定

```sh
locale                  # 現在の設定を確認
localectl list-locales  # 現在使用できるロケールを確認
    # [user@redhat8 ~]$ localectl list-locales
    # C.utf8
    # ja_JP.eucjp
    # ja_JP.utf8
localectl set-locale C.utf8     # ロケール変更
localectl set-locale ja_JP.utf8 # ロケール変更

# 補足
cat /etc/locale.conf      # 設定ファイル確認
source /etc/locale.conf   # 即時反映


# 日本語ロケールのインストール
dnf install -y glibc-langpack-ja
```

## SELinux

インストールするソフトウェアによっては無効化が必要な場合が多い。    
`/etc/selinux/config` の `SELINUX=enforcing` を書き換える必要がある。   
書き換え後、再起動が必要。

- SELINUX=enforcing   有効(アプリケーションによっては動作を阻害する)
- SELINUX=permissive  無効だが、記録は行う(だったかな？)
- SELINUX=disabled    無効

```sh
# SELinux を無効にする例
cat /etc/selinux/config | grep -e '^SELINUX=' # 現在の設定を確認
sed -i -e "s/^SELINUX=.*$/SELINUX=permissive/g" /etc/selinux/config # 設定変更
cat /etc/selinux/config | grep -e '^SELINUX=' # 変更後のを確認
reboot                                        # 再起動
```

一時的に(再起動まで)設定変更する場合
```sh
# 現在の状態を確認
getenforce

# 一時的に無効化 -> Permissive
setenforce 0

# 一時的に有効化 -> Enforcing
setenforce 1
```

ログを確認する方法
```sh
grep "denied" /var/log/audit/audit.log
grep "SELinux is preventing" /var/log/messages
```


## ユーザー名の色を変更

ssh実行時の誤操作を防止するため、以下の部分の色を変更したい。
```
[user@redhat8 ~]$
```
環境変数 `PS1` によって設定されているっぽい。(RHELでは /etc/bashrc に記載あり)
```
[user@redhat8 ~]$ echo $PS1
[\u@\h \W]\$
[user@redhat8 ~]$ 
```
```sh
# 現在こうなっているが...
PS1="[\u@\h \W]\$ "   

# 色を付けたい範囲に制御文字を入れる
# 開始場所 '\[\e[x;xxm\]' 終了場所 '\[\e[m\]'
PS1="\[\e[1;34m\][\u@\h \W]\[\e[m\]\$ "
     ^^^^^^^^^^^^          ^^^^^^^^
``` 
これを~/.bashrc あたりに書き込むといい。

PS1="[\[\e[1;35m\]\u\[\e[m\]@\h \W]\$ "
PS1="[\[\e[1;35m\]\u@\h\[\e[m\] \W]\$ "

[シェルで使える色一覧を確認するスクリプト - Qiita](https://qiita.com/exy81/items/d58a0c6cdea46ffb36b9)


## デフォルトターゲット

```sh
# 現在のターゲットを確認
systemctl get-default

# ターゲットをgraphical.targetに変更
systemctl set-default graphical.target
```


## 起動確認系
```sh
# 起動時間確認
who -b
# カーネルダンプ確認
grep "Starting kdump" /var/log/messages
# systemd起動確認
grep "Startup finished" /var/log/message
```
