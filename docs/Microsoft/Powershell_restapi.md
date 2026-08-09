# PowerShellでRestAPIを使う

## 構文

```bash
Invoke-RestMethod -Uri "https://192.168.xxx.xxx:xxx/api/xxxxx"

    [使いそうなオプション]
    -Method ：      Get / Post など指定
    -Headers：      連想配列で記述→ @{xxxx = "xxxx"; xxxx: "xxxx"}
    -Body：         'key1=value1&key2=value2'
                    連想配列で記述→ @{xxxx = "xxxx"; xxxx: "xxxx"}
    -OutFile xxx.txt：  ファイル保存する場合
    -ContentType "application/json" ：json形式で返ってくる
    -Credential：   認証情報を渡せる(詳細後術)
    | ConvertTo-Json : json整形 (オプションではないが)

-Credentialオプション使い方の例

    $USER = "username"        # ユーザー名平文を変数に格納
    $PASS = "password"        # パスワード平文を変数に格納
    $secpasswd = ConvertTo-SecureString $PASS -AsPlainText -Force
                              # パスワード平文を変換
    $cred = New-Object System.Management.Automation.PSCredential($USER, $secpasswd)
                              # ユーザー名/パスワードを使用して認証情報を作成 → cred変数に格納
    Invoke-RestMethod -Uri "https://192.168.xxx.xxx:xxx/api/xxxxx" -Method Get -Credential $cred
                              # 作成した認証情報を -Credential $cred の形で記載
```

なお Invoke-WebRequest という性質が少し違うコマンドもあり こちらもRestAPIに使用できる。  
ちなみに、Invoke-WebRequestはヘッダ情報を取得することができる。

----------------------------------------

## 例文

```bash
# 結果を変数に格納

# サーバーに要求した結果が$response変数にオブジェクトとして格納される 
# $response変数は複数のプロパティを持ち、それらを参照する形でデータを取り出す

$response = Invoke-RestMethod -Uri https://127.0.0.1:9398/api/ -Method Get
echo $response
    xml                            EnterpriseManager
    ---                            -----------------
    version="1.0" encoding="utf-8" EnterpriseManager
```
----------------------------------------

## エラーに関して

SSLバージョンの関係などで、PowerShell標準設定だと当たり前にエラーが発生するので、回避方法を記載。  
※※※ PowerShellから抜けると設定がリセットされる ※※※  
参考：https://zassinojunin.jp/20200205/1598  


#### httpsへの対応
```bash
# 確認
[Net.ServicePointManager]::SecurityProtocol
Ssl3, Tls
    → デフォルトだとssl3とTLSのみ対応。

# TLS1.1、TLS1.2も対応させたい
[Net.ServicePointManager]::SecurityProtocol = @([Net.SecurityProtocolType]::Ssl3,[Net.SecurityProtocolType]::Tls,[Net.SecurityProtocolType]::Tls11,[Net.SecurityProtocolType]::Tls12)

# 再度確認
[Net.ServicePointManager]::SecurityProtocol
Ssl3, Tls, Tls11, Tls12
```


#### 自己証明書関連エラー
```bash
# 詳細不明だが、以下のコマンド実施で解決

add-type @"
    using System.Net;
    using System.Security.Cryptography.X509Certificates;
    public class TrustAllCertsPolicy : ICertificatePolicy {
        public bool CheckValidationResult(
            ServicePoint srvPoint, X509Certificate certificate,
            WebRequest request, int certificateProblem) {
            return true;
        }
    }
"@

[System.Net.ServicePointManager]::CertificatePolicy = New-Object TrustAllCertsPolicy
```
