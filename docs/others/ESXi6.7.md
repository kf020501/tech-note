---
title: "ESXi 6.7 (無料枠)"
date: 2022-01-02
draft: false
tags: ["VMware"]
---

# ESXi 6.7 (無料枠)

無料枠をわちゃわちゃ使うためのメモ

## ESXiのコマンド

```sh
# 状態確認

vim-cmd vmsvc/getallvm              # VMの一覧取得
vim-cmd vmsvc/power.on 944          # ID: 944 のVMを起動
vim-cmd vmsvc/power.getstate 944    # ID: 944 電源状態の確認
vim-cmd vmsvc/get.summary vmid      # ステータスや設定情報の確認

# VMの起動・シャットダウン・再起動

vim-cmd vmsvc/power.on vmid         # 起動
vim-cmd vmsvc/power.reboot vmid     # 再起動
vim-cmd vmsvc/power.shutdown vmid   # シャットダウン

# VMの情報

vim-cmd vmsvc/get.summary vmid
vim-cmd vmsvc/get.config vmid
vim-cmd vmsvc/get.guest vmid
vim-cmd vmsvc/get.runtime vmid

# ファイル圧縮(tarとかgzip可能)
 tar cfz TargetDir.tgz TargetDir
# pigz(マルチコア処理)も使える

```
[VMware ESXiをSSHでがんばるぞい(コマンドライン操作色々) - Qiita](https://qiita.com/binzume/items/096ce77f73b6e853c342)
[コマンド実行結果を入れた変数を出力するとき、改行をそのままにする | ハックノート](https://hacknote.jp/archives/16316/)
[ESXi 6.5に公開鍵/秘密鍵を使用してSSHで自動ログインする - Qiita](https://qiita.com/negi_c/items/f9332b4a6308378bc36f)

esxiに公開鍵を配置 /etc/ssh/keys-root/authorized_keys
```scp ./key ssh@192.168.10.130:/etc/ssh/keys-root/authorized_keys```



## シンプロビジョニングで使用していないディスク領域を縮小

データストア移動したら限界まで拡張した。許せない。  
なお、NFSでは出来ない模様(Not a supported filesystem type)

```sh
# 縮小させる
vmkfstools -K <縮小したいvmdk>

  # 例) 

# たくさんある場合はfindするといいよ
find ./ -name *.vmdk -exec vmkfstools -K {} \;

    # 停止しているVMを対象に実行して、その後動くのは確認した。
    # 本番環境でやっていいかは不明。
```

vmkfstools -K ./<仮想マシン名>.vmdk

[【実践】VMwareの仮想ディスクを縮小する | りんか ネット](https://rin-ka.net/thin-provisioning-disk-difference/)


## HDDマッピングファイル作成

datastoreのvmdkを使用するのではなく、HDDを(ほぼ)直接マウントする

```bash
# HDDの識別子を確認
ls /vmfs/devices/disks/

# マッピングファイルの保存ディレクトリの作成
cd /vmfs/volumes/datastore1
mkdir rdm

# マッピングファイルの作成
vmkfstools -z <物理デバイスのパス> <作成するマッピングのパス>
  # 例：vmkfstools -z /vmfs/devices/disks/t10.ATA_____WDC_WD30EZRZ2D00GXCB0_________________________WD2DWCL7K4RPLA3U /vmfs/volumes/datastore1/rdm/WD2DWCL7K4RPLA3U.vmdk
```

## ESXi側の設定

ネストの通信を通すには、親のvSwitchのセキュリティをいかに変更する必要がある。
(しないと、vSwitch間でmacアドレスが解決できない？？)

※ もどしたけど行けたわ...不要かも

## ESXi - TrueNAS間のSAN速度確認

TrueNAS側

```bash
iperf3 -s -p 8080 # 通信テストを待ち受ける
```

ESXi側

```bash
# FWを一時的に無効化 
esxcli network firewall set --enabled false

# テスト
/usr/lib/vmware/vsan/bin/iperf3 -4 -c 10.31.0.1 -p 8080

#     実行例
#     [root@esxi01:~] /usr/lib/vmware/vsan/bin/iperf3 -c 10.31.0.1 -p 8080
#     Connecting to host 10.31.0.1, port 8080
#     [  4] local 10.31.0.20 port 33120 connected to 10.31.0.1 port 8080
#     iperf3: getsockopt - Function not implemented
#     [ ID] Interval           Transfer     Bandwidth       Retr  Cwnd
#     [  4]   0.00-1.00   sec   684 MBytes  5.74 Gbits/sec  8634728   0.00 Bytes
#     iperf3: getsockopt - Function not implemented
#     [  4]   1.00-2.00   sec   718 MBytes  6.02 Gbits/sec    0   0.00 Bytes
#     iperf3: getsockopt - Function not implemented
#     [  4]   2.00-3.00   sec   706 MBytes  5.93 Gbits/sec    0   0.00 Bytes
#     iperf3: getsockopt - Function not implemented

# FWを元に戻す
esxcli network firewall set --enabled true
```



## 自動バックアップスクリプト(考え中)


ESXi6.7のauthorized_keysはここにある。    
`/etc/ssh/keys-<username>/authorized_keys`
リモート側から ssh-copy-id では書き込めなかったので、手動で公開鍵を追記した。

```sh
#!/bin/sh

# ---------- Config ----------------------
vm_name='v122_Red Hat Enterprise Linux 8 (10.30.0.40)'
esxi_host='root@192.168.10.120'
esxi_key='~/.default_rsa'
src_datastore
tgt_dir
# ----------------------------------------


# 登録されているVM一覧を取得
vm_list=`ssh -i ${esxi_key} ${esxi_host} "vim-cmd vmsvc/getallvm"`

# 当該VMのIDを取得
vm_id=`echo "${vm_list}" | grep "${vm_name}" | cut -d ' ' -f 1`
echo ${vm_id}

ssh -i ${esxi_key} ${esxi_host} "vim-cmd vmsvc/power.getstate ${vm_id}"
ssh -i ${esxi_key} ${esxi_host} "vim-cmd vmsvc/power.shutdown ${vm_id}"
ssh -i ${esxi_key} ${esxi_host} "vim-cmd vmsvc/power.getstate ${vm_id}"
ssh -i ${esxi_key} ${esxi_host} "vim-cmd vmsvc/power.on ${vm_id}"

result=`ssh -i ${esxi_key} ${esxi_host} "vim-cmd vmsvc/power.getstate ${vm_id}"`

# VMがパワーオフになっている or 5分経過したら抜ける
while [`ssh -i ${esxi_key} ${esxi_host} "vim-cmd vmsvc/power.on ${vm_id}"` | grep 'Powered on'`]
do
    power_state=`ssh -i ${esxi_key} ${esxi_host} "vim-cmd vmsvc/power.on ${vm_id}"`
    if [ "${power_state} | grep 'Powered on'"]; then
      break
    fi

    if [ ${time} >= 300 ]; then
      echo "5分経過しましたがVMがオフにならなかったため、処理を終了します."
      exit 1
    fi

    sleep 

    time+=5

done

while
do

    if [ ${time} >= 300 ]; then
      echo "5分経過しましたがVMがオフにならなかったため、処理を終了します."
    fi

    sleep 
    time+=5

done


while [ "`ssh -i ${esxi_key} ${esxi_host} vim-cmd vmsvc/power.getstate ${vm_id}` | grep 'Powered on'" ]
do
  echo aaa
done


if [ -z "${TargetDir}/${LatestDir}" ]; then
  rsync -aP ${SourceDir}/ ${TargetDir}/${Date} --log-file=${TargetDir}/_${Date}_rsync.log
else
  rsync -aP ${SourceDir}/ ${TargetDir}/${Date} --log-file=${TargetDir}/_${Date}_rsync.log --link-dest=${TargetDir}/${LatestDir} 
fi
```

## パッチ適用
[[VMware ESXiにパッチを適用する | New technologies in our life](https://yoshi0808.github.io/new-technology/2020/06/14/esxi67-patch/)]

### ここからDL

sshでの作業が必要。

[Product Patches - VMware Customer Connect](https://customerconnect.vmware.com/patch)

zipのままESXiに送る。(sftpすると上手くいかない。。ブラウザからdatastoreに上げた)

パッチ宛てる前にメンテナンスモードにする。

```sh
# 現在のプロファイル確認
esxcli software profile get   

> ESXi-6.7.0-20190802001-standard
>    Name: ESXi-6.7.0-20190802001-standard

# パッチのプロファイル確認
 esxcli software sources profile list -d /vmfs/volumes/system/ESXi670-202201001.zip 

> Name                             Vendor        Acceptance Level  Creation Time        Modification Time
> -------------------------------  ------------  ----------------  -------------------  -------------------
> ESXi-6.7.0-20220104001-no-tools  VMware, Inc.  PartnerSupported  2022-01-12T08:53:55  2022-01-12T08:53:55
> ESXi-6.7.0-20220104001-standard  VMware, Inc.  PartnerSupported  2022-01-12T08:53:55  2022-01-12T08:53:55

# アップデート
# esxcli software profile update -d <パッチのパス> -p <パッチのプロファイル名>
esxcli software profile update -d /vmfs/volumes/system/ESXi670-202201001.zip  -p ESXi-6.7.0-20220104001-standard

# 再起動
reboot
```

## pigzで圧縮
ESXiでは `tar -I pigz -cvf $.tgz $` のようにtar -I でpigzを指定できない。   
単一dirならパイプすればいいが、xargsする場合は以下のようにする。
```
ls | xargs -I $ sh -c "tar cv $ | pigz > $.tgz"
```

## マウント状態の確認

[ESXi コマンド ラインから切断された NFS データストアの 再マウント (1005057)](https://kb.vmware.com/s/article/1005057?lang=ja)

```
esxcli storage nfs list
```

