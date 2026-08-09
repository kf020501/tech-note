NFSサーバー構築
========================================

環境：CentOS7

まえがき
----------------------------------------

過去メモから転記→再構築/検証
ESXiから接続できる共有フォルダを作りたかったので構築してみる。


構築する環境
----------------------------------------

**①NFSサーバー** 
- OS：CentOS 7
  - ベース環境：インフラストラクチャサーバー
- IP：192.168.10.110
- /mnt/nfss ←ここを共有ディレクトリに設定

**②NFSクライアント**
- OS：CentOS 7
  - ベース環境：インフラストラクチャサーバー
- /mnt/nfsc ←共有ディレクトリをマウントする

**③NFSクライアント**
- OS：Windows 10 Pro
- Fドライブに共有ディレクトをマウントする


①NFSサーバー設定
----------------------------------------

管理者権限で操作を行った


```bash
# NFSサービスのインストール
yum -y install nfs-utils

# 参考: debian11の場合は以下
# apt -y install nfs-kernel-server

# エクスポートポイント(保存フォルダ？)の作成
mkdir /mnt/nfss/

# テストファイル作成
vi /mnt/nfss/test.txt

# エクスポートポイント(NFS用の共有)設定
# とりあえずテスト環境なので、誰でも触れるようにしてみる
vi /etc/exports
  -----以下を追記する-----
  /mnt/nfss/ *(rw,async,no_root_squash)
  ------------------------

# サービスを起動/有効化
systemctl start rpcbind
systemctl enable rpcbind
systemctl start nfs-server
systemctl enable nfs-server

# firewalld設定
firewall-cmd --permanent --zone=public --add-service=nfs
firewall-cmd --reload
```


②NFSクライアント設定
----------------------------------------

```bash
yum -y install nfs-utils
mkdir /mnt/nfsc
mount -t nfs 192.168.10.110:/mnt/nfss /mnt/nfsc

# /etc/fstabを編集する事で、起動時に自動マウントも可能
vi /etc/fstab
  -----以下を追記する-----
  192.168.10.110:/mnt/nfss /mnt/nfsc nfs defaults 0 0
  ------------------------
  <デバイスファイル名> <マウントポイント> <ファイルシステム種類> <オプション> <dumpフラグ> <fsckがチェックする順序>

```
- /etc/fstabについて
  - <デバイスファイル名> <マウントポイント> <ファイルシステム種類> <オプション> <dumpフラグ> <fsckがチェックする順序>
  - default = async,auto,dev,exec,nouser,rw,suid つまり
    - 非同期入出力
    - mount -a でマウント
    - バイナリ実行可
    - 読み書き可
    - SUID,SGID有効


③NFSクライアント設定 (win)
----------------------------------------

WIndows Server(2016) と Windows 10 Pro ではできることを確認。

ServerとProは問題なく行けると思う。Homeでできるかは不明。

### 3-1 NFSクライアント機能の追加
- WinServer：役割と機能の追加 から
- WinPro：Windowsの機能の有効化または無効化 から

### 3-2 マウント
```bash
mount -o nolock [NFSサーバのホスト名やIPアドレス]:/[共有名] [未使用のドライブラベル]:\
    # 例) mount -o nolock 192.168.10.110:/mnt/nfss F:\
    # PowerShellだと駄目だよ！ コマンドプロンプトで！
```

[Windows7からNFSをマウントする方法 - kissrobberの日記](https://kissrobber.hatenadiary.org/entry/20110402/1301730648)

mountする時は、nolockのオプションを指定してないとなぜかマウントしたコマンドプロンプト以外からの書き込みが上手く動きません。

エラー 0x80070021: プロセスはファイルにアクセスできません。別のプロセスがファイルの一部をロックしています。


参考
----------------------------------------

- [nfs環境の覚書 - Qiita](https://qiita.com/ch7821/items/345ea842ca73c9063ed3)
- [【 mount 】コマンド――ファイルシステムをマウントする：Linux基本コマンドTips（183） - ＠IT](https://www.atmarkit.co.jp/ait/articles/1802/15/news035.html)