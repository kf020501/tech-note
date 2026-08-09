
# PowerShellノート

cmdのコマンド含む。     
スクリプトの場合、文字コードは「UTF-8 with BOM」にしないと日本語が文字化けする。

## 共通系

### 実行ポリシー

PowerShellスクリプトを実行する際、標準では実行できない。    
ポリシーを変更する必要がある。

| ポリシー名   | 署名あり | ローカル | 非ローカル |
| ------------ | -------- | -------- | ---------- |
| Restricted   | x        | x        | x          |
| AllSigned    | o        | x        | x          |
| RemoteSigned | o        | o        | x          |
| Unrestricted | o        | o        | #          |
| Bypass       | o        | o        | o          |

```powershell
Get-ExecutionPolicy                                     # 現在のポリシーを確認
Set-ExecutionPolicy RemoteSigned                        # ポリシーを RemoteSigned に

PowerShell -ExecutionPolicy RemoteSigned .\sample.ps1   # 実行ポリシーをその場だけ変更
```

### 繰り返し/分岐

```powershell
# Where-Object (?) オブジェクト抽出
Get-Alias | ?{$_ -like "echo"}

# ForEach-Object (%) itemsをすべて処理
@(1,2,3,4,5) | %{Write-Host $_}

# Get-Service (gsv) サービス一覧を表示
gsv | ?{$_.name -like "Win*"}

| Format-List   # リスト化
| Get-Member    # メンバー(MethodやProperty)を表示
| Select-Object -Property * # プロパティ一覧表示
```

### エイリアス

```powershell
# Get-Alias (gal) エイリアスの一覧を取得
gal -Definition Write-Output    # Write-Output のエイリアスを表示
gal -Name echo                  # echo がなんのエイリアスか表示

# 設定ファイルの場所を確認
echo $profile

# 設定ファイルがなければ作成
New-item –type file –force $profile

# 設定ファイルに書き込む
set-alias <設定する略称> <正式なコマンド>
    # echo "set-alias～" >> $profile でもよい？
```




## ファイル/ディレクトリ操作


### robocopy

```powershell
# ヘルプの表示
robocopy /?
 
$src_dir = "C:\work\SourceDir"
$src_dir = "C:\work\DestDir"

# テスト実行
robocopy $src_dir $src_dir /S /E /MIR /TEE /NP /L 
# 実行
robocopy $src_dir $src_dir /S /E /MIR /TEE /NP

robocopy "\\server\share¥SourceDir" "\\server\share¥TargetDir" /S /E /MIR /LOG:"<LogFile>" /TEE /NP

```

| オプション    | 説明                                                     |
| ------------- | -------------------------------------------------------- |
| /S            | サブディレクトリをコピー(空のディレクトリはコピーしない) |
| /E            | 空のディレクトリを含むサブディレクトリをコピー           |
| /PURGE        | コピー元に存在しないコピー先のファイル・フォルダを削除。 |
| /MIR          | ディレクトリをミラー化。/E /PURGE (*1)                   |
| /L            | テスト実行。処理内容の表示のみを行い変更を加えない。     |
| /NP           | コピーの完了率を表示しない                               |
| /LOG:ファイル | ログファイルに出力(上書き)                               |
| /TEE          | ログファイル出力時、コンソールウィンドウにも出力         |
| /V            | スキップされたファイルも結果に表示                       |

*1 /E /PURGE とほぼ同等だが、コピー先にフォルダが存在する場合、/MIRはセキュリティ設定をコピーする。

### フォルダ 作成

```powershell
# ディレクトリ作成 以下の例だと、C:\work がなくとも自動生成される
New-Item -Type Directory 'C:\work\dir01'

# 確認
Get-Item 'C:\work\dir01'
```

### ディレクトリを圧縮

```powershell
Get-ChildItem -Directory | ForEach-Object { Compress-Archive -Path $_.FullName -DestinationPath "$($_.Name).zip" }
```

### 疑似 tail -f

```powershell
Get-Content .\test.log -Wait -Tail 10
```


## ハッシュ値計算

```sh
Get-FileHash -Algorithm md5 <FilePath>      # md5
Get-FileHash -Algorithm sha256 <FilePath>   # sha256
```

## 端末のパスを短く

[PowerShellのプロンプト文字列をカスタマイズする － ＠IT](https://atmarkit.itmedia.co.jp/fwin2k/win2ktips/983psprompt/psprompt.html)


## cipher - HDD削除

HDD捨てる前とかに

事前にNTFSにフォーマット → コマンド実行

```powershell
cipher /w:d:            #dドライブを削除するよ 

できるだけ多くのデータを削除するために、CIPHER /W の実行中
はほかのアプリケーションをすべて終了してください。
0x00 に書き込み中
......................  # ←進行状況
0xFF に書き込み中
......................
乱数 に書き込み中
......................
C:\>
```

## 日付取得

```
$date = Get-Date -Format "yyyy/MM/dd HH:mm:ss.fff"
echo $date
```

## カレントフォルダ内のフォルダ毎に圧縮

```ps1
# カレントディレクトリ内のすべてのフォルダを取得
$folders = Get-ChildItem -Directory

# 各フォルダをzipファイルに圧縮
foreach ($folder in $folders) {
    $zipPath = "$($folder.FullName).zip"
    Compress-Archive -Path $folder.FullName -DestinationPath $zipPath
}
```