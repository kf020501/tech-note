---
title: "Windows Server 2019 Install"
tags: ["memo"]
date: 2022-01-10
weight: 100
draft: false
---

## PowerShellでRDP有効化

```
Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Value "0"
```


## ネットワーク系

### hostsの場所
覚えられない...  
`C:\Windows\System32\drivers\etc`

### Windowsのルーティングテーブル操作

cmdでもpsでもどっちでも同じ(多分)

```
# 現在のルーティングテーブルを確認
> route print

# ルートを追加
> route <option> add <network> mask <mask> <gateway>
    # 例) route -p add 172.16.0.0 mask 255.255.0.0 192.168.10.129
    # 192.168.xxx.xxxのネクストホップが192.168.11.254になる
    # -pをつけると恒久設定になる。

# ルートを削除
> route delete <network> [mask <mask>]
```
## パフォーマンスログ設定

[Windowsのパフォーマンスログ(モニタ)取得の設定方法](https://www.haruru29.net/blog/post-4135/)

コンピュータの管理 > パフォーマンス > データコレクトセット > ユーザー定義
新規作成 → データコレクトセット
- 手動で作成する
- データログを作成する
    - パフォーマンスカウンター
- 追加
    - Processor > (Total)Processor Time
    - Memory > Available MBytes
    - Memory > Committed Bytes

## 時刻設定

### 同期先NTP設定

サーバーマネージャー > ツール > サービス > Windows Time が有効になっていることを確認(規定値で有効)

```powershell
# 確認
w32tm /query /source    # 接続先確認
w32tm /query /status    # 接続状態確認

# NTP同期先を 10.30.0.3 に設定 /update で即時反映
w32tm /config /manualpeerlist:10.30.0.3,0x8 /syncfromflags:manual /update
```

実行例
```
PS C:\Users\Administrator> w32tm /config /manualpeerlist:10.30.0.3,0x8 /syncfromflags:manual /update
コマンドは正しく完了しました。
PS C:\Users\Administrator>
PS C:\Users\Administrator>
PS C:\Users\Administrator> w32tm /query /source
10.30.0.3,8
PS C:\Users\Administrator>
PS C:\Users\Administrator> w32tm /query /status
閏インジケーター: 0 (警告なし)
階層: 3 (二次参照 - (S)NTP で同期)
精度: -23 (ティックごとに 119.209ns)
ルート遅延: 0.0216253s
ルート分散: 7.7938950s
参照 ID: 0x0A000003 (ソース IP:  10.30.0.3)
最終正常同期時刻: 2022/01/10 1:45:54
ソース: 10.30.0.3,8
ポーリング間隔: 10 (1024s)

PS C:\Users\Administrator>
```


### 時計の秒数表示

    HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced
    新規作成
    名前：ShowSecondsInSystemClock
    種類：DWORD（32ビット値）
    値  ：1

その後、タスクマネージャーからエクスプローラを再起動

```
REG ADD HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced /v ShowSecondsInSystemClock /t REG_DWORD /d 1
stop-process -name explorer
```


## Windows評価版 期間延長

```
# 残り期間確認
slmgr /dli

# 残りのリセット回数確認
slmgr /dlv

# 期間延長
slmgr /rearm 
```

## prob

### Win2019 や Win10 EnterpriseでSMB接続できない問題

GuestでもSMB接続できるようにする設定。セキュリティ的には望ましくない。

```
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters
名前：AllowInsecureGuestAuth
データ：1（有効） ← こっちにする
　　　※0（無効）
```

### RDP 暗号化認証エラー (暗号化オラクル)

クライアントとサーバーで、WindowsUpdateの歩調を合わせておかないと発生するエラー。
根本解決としては、クライアント/サーバー共にUpdateを最新にしておけばいいのだが、そうできないときのためのメモ。

なお、修正パッチも存在するが、今回は設定で回避する。

パターン１：サーバー側の設定変更
    [2018 年 5 月の更新プログラム適用によるリモート デスクトップ接続への影響 | Microsoft Docs](https://docs.microsoft.com/ja-jp/archive/blogs/askcorejp/2018-05-rollup-credssp-rdp)

[システムのプロパティ] －[リモート] タブにおいて、「ネットワークレベル認証でリモートデスクトップを実行しているコンピューターからのみ接続を許可する」のチェックを外します。  
↓同等のコマンド  
Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp' -Name "UserAuthentication" -Value 0

パターン２：クライアント側の設定変更

>4-1. リモート デスクトップ接続元 (クライアント) での回避策 1
>
>    リモートデスクトップ接続元にて以下のポリシーを変更することでリモートデスクトップ接続先に 3 月以降の更新プログラムが未適用の場合でも接続可能となります。
>
>    [コンピューターの構成]
>    -> [管理用テンプレート]
>    -> [システム]
>    -> [資格情報の委任]
>
>    ポリシー名 : Encryption Oracle Remediation (暗号化オラクルの修復)
>    設定 : Vulnerable (脆弱)
>
>4-2. リモート デスクトップ接続元 (クライアント) での回避策 2
>
>    リモートデスクトップ接続元にて以下レジストリを手動もしくは REG ADD コマンドで追加いただくことでも回避策 1 と同様の効果が得られます。
>
>    レジストリ パス : HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters
>    値 : AllowEncryptionOracle
>    データの種類 : DWORD
>    値 : 2
>
>    REG ADD コマンドで追加いただく場合には以下のコマンド ラインとなります。
```REG ADD HKLM\Software\Microsoft\Windows\CurrentVersion\Policies\System\CredSSP\Parameters /v AllowEncryptionOracle /t REG_DWORD /d 2```
