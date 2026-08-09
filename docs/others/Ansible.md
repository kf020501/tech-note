---
title: "Ansible"
tags: ["Linux"]
date: 2022-01-03
weight: 20
draft: false
---

# Ansible

[Ansible ドキュメント — Ansible Documentation](https://docs.ansible.com/ansible/2.9_ja/index.html)

## 概要

Ansible とは？

- エージェントレスの構成管理ツール(sshによるリモートログインを使用)
- 管理対象に必要なものはsshとPython(一般的なLinuxは標準装備)
- 冪等性(べきとうせい)がある= ある操作を1回行っても複数回行っても結果が同じである。
- 今回は以下のように呼ぶ(呼び方は諸説あり)
    - Ansileをインストールするホスト: コントローラ
    - Ansibleの操作対象(設定される側): サーバ

## 用語

- inventoryファイル
    - 作業対象となるホストを記載(IPやホスト名)
    - グループ化も可能
    - デフォルトでは /etc/ansible/hosts
- ansibleコマンド
    - モジュールを単発で実行
- playbook / ansible-playbookコマンド
    - モジュールを連続で実行するために使用
    - yaml形式でplaybookを作成
    - ansible-playbookコマンドで実行
- モジュール
    - ファイルをコピーするモジュールや、ユーザーを作成するモジュールなど色々


## インストール(RHEL 8)

[Ansible のインストール — Ansible Documentation](https://docs.ansible.com/ansible/2.9_ja/installation_guide/intro_installation.html#rhelcentos-fedora-ansible)

```sh
# RHEL 8 用の Ansible Engine リポジトリーを有効にして、インストール
subscription-manager repos --enable ansible-2.9-for-rhel-8-x86_64-rpms
yum install ansible
ansible --version   # バージョン確認

    # 実行例
    # [root@redhat8 ~]# ansible --version
    # ansible 2.9.27
    #   config file = /etc/ansible/ansible.cfg
    #   configured module search path = ['/root/.ansible/plugins/modules', '/usr/share/ansible/plugins/modules']
    #   ansible python module location = /usr/lib/python3.6/site-packages/ansible
    #   executable location = /usr/bin/ansible
    #   python version = 3.6.8 (default, Sep  9 2021, 07:49:02) [GCC 8.5.0 20210514 (Red Hat 8.5.0-3)]
    # [root@redhat8 ~]# 
```
もしくはpipでも大丈夫
```sh
pip3 install ansible    # インストール
pip3 install -U ansible # 更新

pip3 install ansible==2.2.1.0 # バージョン指定
```


## 事前準備(名前解決)

/etc/hosts に以下を記載
```text
10.30.0.43   controller
10.30.0.41   server1
10.30.0.42   server2
```

## inventoryファイル

- デフォルトでは `/etc/ansible/hosts`
- 作業対象となるホストを記載
    - IPやホスト名で記載
    - "[]"でグループ指定 
- コマンド実行時 -i オプションで、デフォルト以外のhostsファイルも読み込める
- `#` でコメントアウト
- `server1 ansible_ssh_user=UserName` などとすることで、使用するユーザーを指定可能

今回は `/etc/ansible/hosts` に以下を追記する。
```text
[group1]
server1
server2

[group2]
10.30.0.41
10.30.0.42

# 詳細な書き方例
# HostName ansible_host=127.0.0.1 ansible_port=22 ansible_user=UserName ansible_ssh_private_key_file=private.key
```

## ansibleコマンド(モジュール単発実行)


### 構文
```sh
ansible <HOST> -m <MODULE> [-a <パラメータ>]
```
-  `<HOST>`: hostsに記載されているサーバを指定
- -m: モジュールを指定
- -k: パスワード認証で実行(コマンド実行後、サーバのPWを聞かれる)
- -u: sshユーザを指定
- -i: inventoryファイルを指定(オプション 指定しない場合は/etc/ansible/hostsを見に行くはず)

### 参考: ssh鍵作成例

これで、-kなしでも実行できるようになる
```sh
ssh-keygen              # 鍵作成 オプションなしでRSA 2048?
ls -la ~/.ssh/          # 確認
ssh-copy-id controller  # server1にコピー
ssh-copy-id server1     # server1にコピー
ssh-copy-id server2     # server2にコピー

# ssh server1 などで、PWなしでログインできることを確認する
```
### 例: pingモジュールで疎通確認

- ansibleが実行可能な状態か確認
- OSのpingコマンドを実行しているわけではない点に注意

```text
[root@redhat8 ~]# ansible server1 -m ping
server1 | SUCCESS => {
    "ansible_facts": {
        "discovered_interpreter_python": "/usr/bin/python"
    },
    "changed": false,
    "ping": "pong"
}
[root@redhat8 ~]# 
```

### 例: httpdをstart

```sh
ansible server1 -m service -a "state=started name=httpd"
```

### 例: サーバに`ip a`を実行させ、出力を確認
```sh
ansible server1 -a "ip a" 
``` 

## playbook

- playbookをyaml形式で作成し、モジュールを連続で実行する。
- 実行するには`ansible-playbook`コマンド

### playbook 構文

playbook-sample.yml
```yaml
- hosts: group1   # 対象のホストを指定 all ですべてのホストを指定
  # remote_user: UserName # sshユーザー名を指定
  tasks:
  - name: yumモジュールを使用して、epel-releaseをインストール
    yum: name=epel-release
  - name: yumモジュールを使用して、slコマンドをインストール
    yum: name=sl
```
### playbook 構文チェック
`--syntax-check` で構文チェック
```sh
ansible-playbook --syntax-check playbook-sample.yml

  # 実行結果
  # playbook: playbook-sample.yml
```
--syntax-check 入力補完が効かなくて残念

### ansible-playbookコマンド

コントローラで実行する
```sh
ansible-playbook playbook-sample.yml
```
補足: inventoryファイルを使用せず、直接サーバを指定することも可能。
  - 複数 `ansible-playbook -i sever1,server2 playbook.yml`
  - 単数 `ansible-playbook -i sever1, playbook.yml` 最後に`,`をつけないと、inventoryファイルを探しに行く。

実行例
```text
[root@redhat8 ~]# ansible-playbook --syntax-check playbook-sample.yml

playbook: playbook-sample.yml
[root@redhat8 ~]#
[root@redhat8 ~]# ansible-playbook playbook-sample.yml 

PLAY [group1] **********************************************************************************************************


TASK [Gathering Facts] *************************************************************************************************
ok: [server2]
ok: [server1]

TASK [yumモジュールを使用して、epel-releaseをインストール] *******************************************************************************
changed: [server1]
changed: [server2]

TASK [yumモジュールを使用して、slコマンドをインストール] *************************************************************************************
changed: [server1]
changed: [server2]

PLAY RECAP *************************************************************************************************************
server1                    : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
server2                    : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[root@redhat8 ~]# 
```

- ansibleの冪等性について
    - 実行例では最後が`changed=2` となっている。
    - もう一度実行すると、既にインストール済みなのでインストールは実行されず `changed=0` となる(冪等性)


## モジュール


ansible-doc -l コマンド で使用可能なモジュール一覧を確認することもできる。  
また、ansible-doc <モジュール名> で使い方確認も可能

### サーバの情報を取得(setup)

サーバの情報を取得し、whenの条件分岐などに使用できる。  
実はPlaybook 実行時に初めに実行される(リザルトに記載あり)
かなりいろいろな情報が取得できる(出力はjsonかな?)
```sh
ansible server1 -m setup
```
実行結果抜粋
```text
"ansible_distribution": "CentOS",
"ansible_distribution_version": "7.9",
```
```yaml
- hosts: group1
  tasks:
  - name: distribution = CentOSなら、ファイルを送信
    copy:
      src=/root/sample.tgz
      dest=/root/
    when:
      ansible_distribution == "CentOS"
```


### urlのファイルをDL(get_url)
```yaml
- hosts: group1     # 対象のホストを指定
  vars:             # 変数指定
    url: https://docs.ansible.com/ansible/2.9_ja/index.html
  tasks:
  - name: ansibleドキュメントのトップページをダウンロード
    get_url:        # url と 保存先指定
      url={{ url }}
      dest=/root/  
```

### コントローラから圧縮ファイルを送信+解凍(unarchive)
```yaml
- hosts: group1     # 対象のホストを指定
  tasks:
  - name: sample.tgzをコントローラからサーバに転送し展開(サーバには解凍後のファイルのみ)
    unarchive:      # 送信するファイル(コントローラ側) と 保存先(サーバ側) を指定
      src=/root/sample.tgz
      dest=/root/
      # remote_src=true  とすると、src= はコントローラでなくサーバのファイルを参照する(tgzは残る)
```
コントローラ側 sample.tgz
```
[root@redhat8 ~]# tar -tzvf /root/sample.tgz 
drwxr-xr-x root/root         0 2022-01-03 20:16 sample/
-rw-r--r-- root/root       282 2022-01-03 20:16 sample/playbook-get_url.yml
-rw-r--r-- root/root       338 2022-01-03 20:16 sample/playbook-sample.yml
-rw-r--r-- root/root       353 2022-01-03 20:16 sample/playbook-unarchive.yml
[root@redhat8 ~]# 
```
実行後 サーバ側 ---> 展開されている、sample.tgz は存在しない
```
[root@centos7 ~]# ls -lR
.:
合計 48
-rw-------. 1 root root  1507 12月 17  2020 anaconda-ks.cfg
-rw-r--r--. 1 root root 42634  1月  3 19:56 index.html
drwxr-xr-x. 2 root root    91  1月  3 20:16 sample

./sample:
合計 12
-rw-r--r--. 1 root root 282  1月  3 20:16 playbook-get_url.yml
-rw-r--r--. 1 root root 338  1月  3 20:16 playbook-sample.yml
-rw-r--r--. 1 root root 353  1月  3 20:16 playbook-unarchive.yml
[root@centos7 ~]#
```

### パッケージインストール(yum)
- name= でインストールするパッケージを指定
- state= で "状態" を指定
    - state=present : インストール状態
    - state=absent : アンインストール状態
    - 他、installed, latest, removed

httpdをインストール
```yaml
- hosts: group1     # 対象のホストを指定
  tasks:
  - name: httpdインストール
    yum:
        name=httpd
        state=present
```
全パッケージをアップデート
```yaml
- hosts: group1     # 対象のホストを指定
  tasks:
  - name: 全パッケージをアップデート
    yum:
        name=*
        state=latest
```

### サービスの起動/停止(service)

```yaml
- hosts: group1     # 対象のホストを指定
  tasks:
  - name: httpdインストール
    yum:
        name=httpd
        state=installed
  - name: httpdのstart, enable
    service:
        name=httpd
        state=started
        enabled=yes
```
- state= started, stopped, restarted, reloaded

### 任意のコマンドを実行(shell)

冪等性が保障されていないので、可能な限り既存モジュールを使用したほうがいい    
(複数回実行すると、単にコマンドが再度実行される。
```yaml
- hosts: group1     # 対象のホストを指定
  tasks:
  - name: /tem/に移動後、"pwd > result.txt" を実行
    shell: pwd > result.txt
    args:
      chdir: /tmp/
```

### file - file, dir, link 作成

- path= 対象のパスを指定
- state= directory/touch/absent
- owner= 所有者を指定 (オプション)
- group= 所有グループを指定 (オプション)
- mode= パーミッションを指定 (オプション)

```yaml
- hosts: group1     # 対象のホストを指定
  tasks:
  - name: /root/sample-dir の作成
    file:
      path=/root/sample-dir
      state=directory
      # owner=user
      # group=user
      # mode=0777
```

### file, dirを送信(copy)
```yaml
- hosts: group1
  tasks:
  - name: コントローラの/root/sample.txt を、サーバの/root/にコピー
    copy:
      src=/root/sample.txt
      dest=/root/
```
コントローラの sample.txtを編集して再度実行したら、編集後のデータが再送された。

### テンプレートを元にファイル送信(template)

指定したテキストの`{{ xxx }}`の部分を変数として置き換えてコピー。

```yaml
- hosts: group1
  vars: # 変数を作成
    var=hello!
  tasks:
  - name: コントローラの/root/sample.txt(変数付き) を、サーバの/root/にコピー
    template:
      src=/root/sample.txt
      dest=/root/
```

コントローラ側 sample.txt
```
設定した変数は "{{ var }}"です！
```
サーバ側 sample.txt
```
設定した変数は "hello" です！
```

### ユーザの作成(user)

```yaml
- hosts: group1
  vars: # 変数を作成(ユーザー名, PW)
    user: admin
    password: admin
  tasks:
  - name: ユーザを作成(admin/admin)
    user:
      name={{ user }}
      password={{ password | password_hash('sha512') }}
      state=present
```
サーバ側で確認
```
[root@centos7 ~]# cat /etc/passwd | grep admin
admin:x:1001:1001::/home/admin:/bin/bash
[root@centos7 ~]#
[root@centos7 ~]# cat /etc/shadow | grep admin
admin:$6$GnP8mmYAoiUnbFYh$.ZfB2FaajgvWTIFF7ZpFDYF8Inq4ylsvCRmkTjPpNWT4Xp1CpuJAT.boW/3IL93LMVXu.hqOom3LVql.Q6M5/.:18995:0:99999:7:::
[root@centos7 ~]#
```

[Ansible userで毎回changedとなることを防ぐ - Qiita](https://qiita.com/Ki2neudon/items/16dcb7cffa48eadbb879)

### シェルスクリプトをサーバで実行(script)

```yaml
- hosts: group1
  tasks:
  - name: sample.sh の実行
    script: 
      /root/sample.sh
```
コントローラ側 /root/sample.sh
```sh
#!/bin/bash
ip a > sample.txt
```

### 繰り返し処理(with_items)

```yaml
- hosts: group1     # 対象のホストを指定
  tasks:
  - name: /root/配下に with_items で指定したdirを作成
    file:
      path=/root/{{ item }}
      state=directory
    with_items:
      - sample-dir01
      - sample-dir02
      - sample-dir03
```
実行例 itemsがそれぞれ確認できる
```
[root@redhat8 ~]# ansible-playbook playbook-with_items.yml

PLAY [group1] **********************************************************************************************************
TASK [Gathering Facts] *************************************************************************************************
ok: [server1]
ok: [server2]

TASK [/root/配下に with_items で指定したdirを作成] ********************************************************************************
changed: [server2] => (item=sample-dir01)
changed: [server1] => (item=sample-dir01)
changed: [server1] => (item=sample-dir02)
changed: [server2] => (item=sample-dir02)
changed: [server2] => (item=sample-dir03)
changed: [server1] => (item=sample-dir03)

PLAY RECAP *************************************************************************************************************
server1                    : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
server2                    : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

[root@redhat8 ~]#
```
### when - 条件分岐

```yaml
- hosts: group1     # 対象のホストを指定
  tasks:
  - name: /root/sample.txt を削除
    file:
      path=/root/sample.txt
      state=absent
    when:
      start == "y"
```
実行時に `--extra-vars`オプションで変数を設定できる。   
今回のplaybookでは、start=y を指定した場合にfileモジュールが実行される
```sh
ansible-playbook playbook-when.yml --extra-vars "start=y"
```
start=y でない場合、該当箇所が skipping となる(失敗するわけではない)
```
[root@redhat8 ~]# ansible-playbook playbook-when.yml --extra-vars "start=n"

PLAY [group1] **********************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [server2]
ok: [server1]

TASK [/root/sample.txt を削除] ********************************************************************************************
skipping: [server1]
skipping: [server2]

PLAY RECAP *************************************************************************************************************
server1                    : ok=1    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0
server2                    : ok=1    changed=0    unreachable=0    failed=0    skipped=1    rescued=0    ignored=0

[root@redhat8 ~]#
```



### liineinfile - 1行の書き換え

```yaml
- hosts: group1
  tasks:
  - name: SElinuxを無効にする
    lineinfile:
      dest=/etc/selinux/config
      regexp="^SELINUX=.*"
      line="SELINUX=disabled"
```

### リブート時の書き方
`local_action`モジュールが何なのかよくわかっていない
```yaml
- hosts: group1
  tasks:
  - name: 再起動
    shell:
      sleep 2 && shutdown -r now "Ansible update triggered"
    async: # taskを待つ時間
      1 
    poll:  # task終了をチェックする時間
      0
    ignore_errors: # 結果がfailedでも処理を継続するか?
      true 
  - name: 再起動終了まで待つ
    local_action:
      wait_for
      host={{ inventory_hostname }}
      port=22
      state=started
      delay=30
      timeout=300

# inventory_hostname は指定したホスト
```
実行例
```
[root@redhat8 ~]# ansible-playbook playbook-reboot.yml

PLAY [group1] **********************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************
ok: [server2]
ok: [server1]

TASK [再起動] *************************************************************************************************************
changed: [server1]
changed: [server2]

TASK [再起動終了まで待つ] *******************************************************************************************************
ok: [server2 -> localhost]
ok: [server1 -> localhost]

PLAY RECAP *************************************************************************************************************
server1                    : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0
server2                    : ok=3    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0

[root@redhat8 ~]#
```
### become - 管理者権限に移行

su または sudo してタスクを実行できる。

```yaml
- hosts: default
  become: yes
```

remote_user: webuser