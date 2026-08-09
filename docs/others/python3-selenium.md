# Python3 - Selenium

## 環境構築

作業用ディレクトリを作成して環境構築していく。
```
mkdir selenium
cd selenium
```

### seleniumインストール 

仮想環境時の例
```powershell
python -m venv selenium.venv
.\selenium.venv\Scripts\Activate.ps1    # 抜けるときは deactivate
pip install selenium==4.1.0
```
<details><summary>バージョン確認</summary>

```text
PS > python -V
Python 3.10.7
PS > pip freeze
async-generator==1.10
attrs==22.1.0
certifi==2022.9.14
cffi==1.15.1
cryptography==38.0.1
h11==0.13.0
idna==3.4
outcome==1.2.0
pycparser==2.21
pyOpenSSL==22.0.0
selenium==4.1.0
sniffio==1.3.0
sortedcontainers==2.4.0
trio==0.21.0
trio-websocket==0.9.2
urllib3==1.26.12
urllib3-secure-extra==0.1.0
wsproto==1.2.0
PS > 
```

</details>

### webDriver

Chromeのバージョンに合わせたドライバをダウンロードし、作業用ディレクトリ直下に配置。    
`.\chromedriver.exe`

[ChromeDriver - WebDriver for Chrome](https://sites.google.com/chromium.org/driver/)



## サンプル

手元のTrueNASにログインするサンプル

### 要素確認

動きとしては、  
ユーザー名入力 > パスワード入力 > ログインボタンクリック    
としたい。

なので、まずはブラウザで各要素について確認する。(どこに入力すればいいのか?)    
ブラウザで画面を開いた状態でF12などをクリックしてデベロッパーツールを開き、
要素名を調べる。

```html
<input _ngcontent-yru-c485="" autofocus="" matinput="" name="username" required="" value="" autocorrect="off" autocapitalize="none" autocomplete="off" class="mat-input-element mat-form-field-autofill-control ng-tns-c130-0 cdk-text-field-autofill-monitored ng-pristine ng-invalid ng-touched" id="mat-input-0" placeholder="Username" aria-invalid="true" aria-required="true" aria-describedby="mat-error-0">
...
<input _ngcontent-yru-c485="" type="password" name="password" required="" matinput="" value="" class="mat-input-element mat-form-field-autofill-control ng-tns-c130-1 cdk-text-field-autofill-monitored ng-pristine ng-invalid ng-touched" id="mat-input-1" placeholder="Password" aria-invalid="true" aria-required="true" aria-describedby="mat-error-1">
...
<span class="mat-button-wrapper">Log in</span>
```
以下のことが確認できた。

- ユーザー名は `name="username"` に入力
- パスワードは `name="password"` に入力
- ログインは `class="mat-button-wrapper"` をクリック


### サンプルコード

.\webScraping.py
```py
from selenium import webdriver
import time

# 保存したwebDriverを指定
driver = webdriver.Chrome('.\chromedriver')

# 最大待ち時間の指定
driver.implicitly_wait(10)

# URL取得
driver.get('http://freenas.local/ui/sessions/signin')

# ユーザー名 パスワード 入力
username = driver.find_element_by_name("username")
username.send_keys("root")
password = driver.find_element_by_name("password")
password.send_keys("P@ssw0rd")

# ボタンをクリック
login_button = driver.find_element_by_class_name('mat-button-wrapper')
login_button.click()

# 処理が終わったらブラウザがすぐ閉じてしまうので、確認時間を設ける
time.sleep(10)
```
要素の指定の仕方は以下を参考にした。

[4. 要素を見つける — Selenium Python Bindings 2 ドキュメント](https://kurozumi.github.io/selenium-python/locating-elements.html)


## 参考

- [【Python | Selenium4】”WEBブラウザを操作して、スクレイピングするぞ！（次の１歩のその２） | ひらちんの部屋](https://hirachin.com/post-7756/)
- [Selenium - ページの読み込みが完了するまで待つ(python)](https://codechacha.com/ja/selenium-explicit-implicit-wait/)

```py



""""
hoge
""""


```