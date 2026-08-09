# Python3 - openpyxl

## 環境構築

- Windows 10 Pro 21H2
- Python 3.10.10

### 作業用ディレクトリ作成

```
mkdir openpyxl
cd openpyxl
```

### openpyxlインストール

仮想環境時の例
```powershell
python -m venv openpyxl.venv
.\openpyxl.venv\Scripts\Activate.ps1    # 抜けるときは deactivate
pip install openpyxl==3.0.10
```
<details><summary>バージョン確認</summary>

```text
PS > python -V
Python 3.10.10
PS > pip freeze
et-xmlfile==1.1.0
openpyxl==3.0.10
PS > 
```

</details>

## サンプル

作業用ディレクトリ内の`sample.xlsx`を操作してみる


### HelloWorld

```py
import openpyxl

# 操作対象のパスを指定
xlsx_path = "./sample.xlsx"

# ワークブック読み込み
wb = openpyxl.load_workbook(xlsx_path)

# ワークシート指定
ws = wb["Sheet1"]       # 名前指定

        # 参考: 色々な指定
        # ws = wb.worksheets[0]  # 番号指定
        # ws = wb.active         # アクティブなシート指定

# 指定セルへ"HelloWorld"と書き込み
write_str = "HelloWorld"
ws.cell(1, 1).value = write_str

# 指定セルの値を表示
read_str = ws.cell(1, 1).value
print(read_str)

# ファイルを保存 同じパスで上書き.別パスで新規保存
wb.save(xlsx_path) 

# ファイルを閉じる
wb.close()
```


## 参考

- [openpyxlでExcelを操作する【Python入門】 - RAKUS Developers Blog | ラクス エンジニアブログ](https://tech-blog.rakus.co.jp/entry/20210729/openpyxl)