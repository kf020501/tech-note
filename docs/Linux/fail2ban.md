# Fial2Ban

fail2banはログファイル(/var/log/auth.log や /var/log/secure)をスキャンして不審なアクセスを検出し、iptablesの制御をするソフトウェア。      
細かい設定も可能だが、とりあえずインストールして起動しておくだけでもsshdに関しては効果がある。

## インストール

```sh
# インストール
apt-get install -y fail2ban

# バージョン確認
fail2ban-server --version

    # Fail2Ban v0.11.2

# 起動/有効化
systemctl start fail2ban
systemctl enable fail2ban
systemctl status fail2ban
```

設定の初期値は`/etc/fail2ban/jail.conf` にある(直接編集NG)    
ログファイルに同一IPでの異常値が5回あると(例えばssh認証に5回失敗する)、10分間アクセス制限がかかる。
```text
bantime  = 10m
maxretry = 5
```

また、`/etc/fail2ban/jail.d/defaults-debian.conf` には以下のように記載があり、sshdがデフォルトで有効化されている。
```text
[sshd]
enabled = true
```

## 動作確認

10.30.0.42 からsshし、PWを5回間違えたときの動作を確認。

`iptables -L`で確認できる。

```text
root@UbuntuServer22:~# iptables -L
Chain INPUT (policy ACCEPT)
target     prot opt source               destination
f2b-sshd   tcp  --  anywhere             anywhere             multiport dports ssh

Chain FORWARD (policy ACCEPT)
target     prot opt source               destination

Chain OUTPUT (policy ACCEPT)
target     prot opt source               destination

Chain f2b-sshd (1 references)
target     prot opt source               destination
REJECT     all  --  10.30.0.42            anywhere             reject-with icmp-port-unreachable ★ここでrejectされている
RETURN     all  --  anywhere             anywhere
```

また、/var/log/fail2ban.logもある。
```
2023-09-16 02:28:34,067 fail2ban.filter         [55285]: INFO    [sshd] Found 10.30.0.42 - 2023-09-16 02:28:33
2023-09-16 02:28:37,655 fail2ban.filter         [55285]: INFO    [sshd] Found 10.30.0.42 - 2023-09-16 02:28:37
2023-09-16 02:28:53,776 fail2ban.filter         [55285]: INFO    [sshd] Found 10.30.0.42 - 2023-09-16 02:28:53
2023-09-16 02:28:57,989 fail2ban.filter         [55285]: INFO    [sshd] Found 10.30.0.42 - 2023-09-16 02:28:57
2023-09-16 02:36:48,667 fail2ban.filter         [55285]: INFO    [sshd] Found 10.30.0.42 - 2023-09-16 02:36:48
2023-09-16 02:36:48,867 fail2ban.actions        [55285]: NOTICE  [sshd] Ban 10.30.0.42       ★ 5回でban
2023-09-16 02:46:48,211 fail2ban.actions        [55285]: NOTICE  [sshd] Unban 10.30.0.42     ★ 10分経過したらunban
```

## 設定変更について

/etc/fail2ban/jail.conf には以下の記載がある。
基本的には jail.localか、jail.d/配下の.confに設定を記載してね、とのこと。

> YOU SHOULD NOT MODIFY THIS FILE.
> 
> It will probably be overwritten or improved in a distribution update.
> 
> Provide customizations in a jail.local file or a jail.d/customisation.local.
> For example to change the default bantime for all jails and to enable the
> ssh-iptables jail the following (uncommented) would appear in the .local file.
> See man 5 jail.conf for details.

翻訳

> このファイルを変更してはいけません。
> 
> おそらくディストリビューションのアップデートで上書きまたは改善されるでしょう。
> 
> カスタマイズはjail.localファイルまたはjail.d/customisation.localで提供してください。
> 例えば、すべてのジェイルのデフォルトのbantimeを変更し、
> ssh-iptablesジェイルを有効にする場合、次のように（コメントを外して）.localファイルに記載されます。
> 詳細についてはman 5 jail.confを参照してください。

```sh
# 設定の上書きファイルを作成()
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
```

### 再犯

再犯(recidive)が行われた場合の設定が可能。      
jail.conf には以下のように設定があるが、有効化はされていない。
```
[recidive]

logpath  = /var/log/fail2ban.log
banaction = %(banaction_allports)s
bantime  = 1w
findtime = 1d
```
jail.conf に直接設定を書き込んではいけないので、recidive.confを作成し、そこに記載する。     
`vi /etc/fail2ban/jail.d/recidive.conf`
```
[recidive]
enabled = true
```

サービス再起動/確認
```
systemctl restart fail2ban
systemctl status fail2ban
```

再犯(recidive)処理されると、`/var/log/fail2ban.log`に以下のように記載される。
```
2023-09-16 03:25:10,196 fail2ban.factions       [55285]: NOTICE  [recidive] Ban 10.30.0.42
```

`iptables -L` では以下のようになる。
```
Chain f2b-recidive (1 references)
target     prot opt source               destination
REJECT     all  --  10.30.0.42            anywhere             reject-with icmp-port-unreachable
RETURN     all  --  anywhere             anywhere
```


補足:   
fail2ban.conf や .localで、ログレベルがDEBUGになっていてはいけない。ログ監視の無限ループになるため。