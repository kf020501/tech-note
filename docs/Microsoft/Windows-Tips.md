# Windows Tips

## hostsの場所

永遠に覚えられない
```
C:\Windows\System32\drivers\etc
```

## その他

## 最近使ったアイテム

[NEC LAVIE公式サイト > サービス＆サポート > Q&A > Q&A番号 021235](https://faq.nec-lavie.jp/qasearch/1007/app/servlet/relatedqa?QID=021235)

## ステップ記録ツール
psr


## prob: Win2019 や Win10 EnterpriseでSMB接続できない問題
```
HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters
名前：AllowInsecureGuestAuth
データ：1（有効） ← こっちにする
　　　※0（無効）
```

