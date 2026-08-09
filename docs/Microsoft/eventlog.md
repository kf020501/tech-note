# Windowsイベントログ

## 既存のイベントログから抽出

```ps1
# Securityログを抽出
Get-WinEvent -FilterHashtable @{ LogName='Security'}

# Securityのうち、d4625のものを抽出 
Get-WinEvent-FilterHashtable @{ LogName='Security'; id='4625'}

# ディレクトリ配下のログを一括変換
Get-ChildItem | %{ Get-WinEvent -Path $_.FullName | Export-Csv -Path "$($_.FullName).s-jis.csv" -Encoding utf8NoBOM -NoTypeInformation }
```

## アーカイブしたログファイルから抽出

```ps1
# ログがあるフォルダ推定        ファイル名でフィルタ            フルパスに変換      各パスのイベントを取得
Get-ChildItem C:work\WEventLog | ?{$_.Name -like "*Security*"} | %{ $_.FullName } | Get-WinEvent -Path $_}
```

## 使い方いろいろ

```ps1
# イベントログを関数に格納
$EventLog = (Get-ChildItem C:work\WEventLog | ?{$_.Name -like "*Security*"} | %{ $_.FullName } | Get-WinEvent -Path $_})

# ID 4625のみをフィルタ 
$EventLog | ?{ $_.Id -eq "4625"}

# 時間ごとに並び替え
$EventLog | Sort-Object -Property TimeCreated

# csvに変換
$EventLog | Export-Csv -Path temp.csv -Encoding UTF8 -NoTypeInformation
```