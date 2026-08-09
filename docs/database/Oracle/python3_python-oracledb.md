# python-oracledb

PythonからOracleDBに接続するライブラリ。  
OracleClient不要

## インストール

```sh
pip install oracledb
```

## 使い方

```py
import oracledb

connection = oracledb.connect(user="hr", password="hr", dsn="10.30.0.63:1521/orcl")
cur = connection.cursor()
cur.execute("""SELECT * FROM employees""")

# 結果の取得と表示
for row in cur:
    print(row)

# カーソルと接続を閉じる
cur.close()
connection.close()
```