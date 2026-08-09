# Python3 ノート


## pipの使い方

以下"pip3"で記載しているが、環境によっては"pip"でもOK(特にWindows?)
```sh
pip3 freeze                     # 現在のインストール状態を確認

python -m pip install openpyxl  # openpyxl をインストール パターン1
pip3 install openpyxl           # openpyxl をインストール パターン2

pip3 install openpyxl==         # インストール可能な openpyxl のバージョンが表示される
pip3 install openpyxl==3.0.10   # openpyxl 3.0.10 をインストール
pip3 install openpyxl==3.0.10 --proxy http://<プロキシサーバ>:<プロキシユーザー名>:<プロキシパスワード>@FWDN:ポート番号   # プロキシ利用時

pip3 uninstall openpyxl         # openpyxl をアンインストール
```
一括アンインストール
```sh
pip3 freeze > installed.txt     # インストールされたパッケージのリストをテキストに吐き出し
pip3 uninstall -r installed.txt # リスト内のパッケージをアンインストール
```
pip自体の更新
```sh
pip3 install --upgrade pip
```


## venv 環境分離

環境を分離できる (pipした場合など、追加パッケージが個別フォルダに格納される)    
仕組み的には、一時的に環境変数の書き換えを行っているみたい。

Linux
```sh
# 仮想環境作成
python3 -m venv .venv

        # カレントディレクトリに、.venvというディレクトリが作成される
        # 仮想環境のactivate中は、追加パッケージなどはここへ保存され既存環境を汚さない

# 仮想環境のactivate (Linux) ---> activate中はコンソールの頭に"(test.venv)"がつく
source .venv/bin/activate

        # ここで開発やpipなど、お好きな処理を実行

# 仮想環境のdeactivate ---> コンソールの頭の"(.venv)"が消える
deactivate 
```

Windows
```ps1
# 仮想環境作成
python -m venv .\.venv

        # カレントディレクトリに、.venvというディレクトリが作成される
        # 仮想環境のactivate中は、追加パッケージなどはここへ保存され既存環境を汚さない

# 仮想環境のactivate (Windows) ---> activate中はコンソールの頭に"(test.venv)"がつく
.\.venv\Scripts\activate.ps1

        # ここで開発やpipなど、お好きな処理を実行

# 仮想環境のdeactivate ---> コンソールの頭の"(.venv)"が消える
deactivate 

```

## サンプル: grep処理

```py
#!/usr/bin/env python3

import sys
import os
import re
import codecs

# ----------------------------------------
# 引数 など事前処理
# ----------------------------------------

# 引数なしで実行するとパスを聞かれるので入力 or 第1引数にファイルのパスを指定して実行
if len(sys.argv) >= 2:
    path = sys.argv[1]
else:
    path = input('読み込むファイルのフルパスを入力してください: ')
    path = path.replace('"','') # Windonwsでパスのコピーをすると ” が入ってしまうので除去。

log_file_name = os.path.basename(path) # ファイルパス(拡張子付き)を取得 -> sample.txt
log_dir_path = os.path.dirname(path) # ディレクトリパスを取得 -> /foo/bar

# ----------------------------------------
# ファイルを読み込み、1行ずつ読み取り処理していく
# ----------------------------------------

# 最終的にファイルに吐き出す内容を格納する変数
output = []

# 正規表現の検索文字
reg_str = r'199[0-9]\/7\/[0-9]+'

# ファイルを開いて、変数 lines に格納 ※codecsで変換できない文字を無視
print('ファイルを読み込んでいます...')
with codecs.open(path, 'r', 'utf-8','ignore') as f:
    lines = f.readlines()

# 1行ずつ処理
for line in lines:

    # 正規表現に一致する場合、その行をoutputに格納
    if re.search(reg_str, line):

        # outputにデータ格納
        output += [line] # outputにデータ格納

# デバッグ用 outputリストを画面に出力
# for str in output:
#     print(str)

# ----------------------------------------
# outputリスト をファイルに出力
# ----------------------------------------

with open(log_dir_path + '/' + 'result_' + log_file_name + '.txt', 'w', encoding="utf-8") as f:
    f.writelines(output)

input("Press Enter...")
```

## threading 並列処理


### 2つの関数を1個ずつ並行に起動
```py
#!/usr/bin/env python3

import threading
import time

# 1秒ごとにコメント 3回繰り返し
def test_function_A(n):

    for i in range(3):

        print('test_function_A ' + str(n) + '個目は動作中です')
        time.sleep(1)

# 1秒ごとにコメント 5回繰り返し
def test_function_B(n):

    for i in range(5):

        print('test_function_B ' + str(n) + '個目は動作中です')
        time.sleep(1)


# Threadを指定
t1 = threading.Thread(target=test_function_A, args=(1,))
t2 = threading.Thread(target=test_function_B, args=(1,))

t1.start()      # t1(test_function_A) を開始
t2.start()      # t1(test_function_B) を開始

t1.join()       # t1が完了するまで待つ
t2.join()       # t2が完了するまで待つ
```
実行例
```text
test_function_A 1個目は動作中です
test_function_B 1個目は動作中です
test_function_A 1個目は動作中です
test_function_B 1個目は動作中です
test_function_A 1個目は動作中です
test_function_B 1個目は動作中です
test_function_B 1個目は動作中です
test_function_B 1個目は動作中です
```


### 1つの関数を複数 並列に起動

```py
#!/usr/bin/env python3

import threading
import time


# 1秒ごとにコメント 3回繰り返し
def test_function_A(n):

    for i in range(3):

        print('test_function_A ' + str(n) + '個目は動作中です')
        time.sleep(1)


# 配列型の変数を指定 
# ここに実行したthreadを格納していき、最後にjoin処理
threads = []

# test_function_A を5回起動
for i in range(5):

    t = threading.Thread(target=test_function_A, args=(i,)) # threadを指定
    threads.append(t)                                       # threads変数に格納(後でまとめてjoin)
    t.start()                                               # threadを開始

# 格納された各threadが完了するまで待つ
for thread in threads:
    thread.join()
```
joinのしかたは `threading.enumerate()` で生存中のthreadを拾ったりするやり方もあるみたいだけど、わかりやすいのはこれかな。

実行例
```
test_function_A 0個目は動作中です
test_function_A 1個目は動作中です
test_function_A 2個目は動作中です
test_function_A 3個目は動作中です
test_function_A 4個目は動作中です
test_function_A 1個目は動作中です
test_function_A 0個目は動作中です
test_function_A 3個目は動作中です
test_function_A 4個目は動作中です
test_function_A 2個目は動作中です
test_function_A 3個目は動作中です
test_function_A 1個目は動作中です
test_function_A 4個目は動作中です
test_function_A 2個目は動作中です
test_function_A 0個目は動作中です
```

## バージョン指定

```
update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1
update-alternatives --install /usr/bin/python3 python /usr/bin/python3.11 1
```

Linuxでの`update-alternatives`コマンドは、異なるコマンドのためのシンボリックリンクを管理するために使用され、複数のバージョンが利用可能なツールのデフォルトバージョンを選択することができます。提供されたコマンドの構文は以下の通りです：

- `update-alternatives`：Linuxの代替システムを管理するために使用されるコマンドです。
- `--install`：システムに代替を追加するために使用されるオプションです。
- `/usr/bin/python`：シンボリックリンクが作成されるべきパスです。これはユーザーが通常実行するコマンドの一般的な名前を表します。
- `python`：この特定の代替が属している代替群の名前です。この場合は、Pythonインタープリターのための群です。
- `/usr/bin/python3.11`：この代替が指し示す実際の実行可能ファイルへのパスです。この場合はPython 3.11インタープリターです。
- `1`：代替の優先度です。同じ一般的な名前のための複数の代替が利用可能な場合、最高優先度を持つものがデフォルトで使用されます。ここでは、優先度を1に設定しています。

このコマンドでは、Pythonのための新しい代替を作成し、それをPython 3.11に指すようにし、その優先度を1に設定するよう`update-alternatives`に伝えています。ユーザーが`python`を実行すると、システムは`python`コマンドのために利用可能な最高優先度の代替を使用します。