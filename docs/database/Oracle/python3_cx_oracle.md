
# cx_Oracle(Python)


## インストール

- AlmaLinux 8.8
- Python 3.6.8
- Oracle Client 19c

```sh
# インストール
pip3 install cx_Oracle==8.2.1

# 確認
pip3 freeze
    # cx-Oracle==8.2.1
```

## 実行サンプル

```py
import cx_Oracle

# 接続先設定
tns = cx_Oracle.makedsn('10.30.0.67', 1521, service_name = 'orcl')

# DB接続
conn = cx_Oracle.connect('user01','password01',tns)
cur = conn.cursor()

# SQL実行 (末尾のセミコロンは不要)
cur.execute('SELECT empno, ename, job FROM emp')

# 参考: f_strings でSQL文を作成 (末尾のセミコロンは不要)
# column = 'username, hoge'
# table = 'users'
# sql = f'SELECT {column} FROM {table}'
# cur.execute(sql)

# 実行結果取得
res = cur.fetchall()

# DB接続を閉じる
cur.close()
conn.close()

# 実行結果確認
print(res)
```


## 

```
SERVICE =
  (DESCRIPTION =
    (ADDRESS_LIST =
      (ADDRESS = (PROTOCOL = TCP)(HOST = 10.30.0.67)(PORT = 1521))
    )
    (CONNECT_DATA =
      (SERVICE_NAME = orcl)
    )
  )
```

## python-oracledbドライバ

なんかOracleClient不要なのもあるらしい。

- [Pythonおよびpython-oracledbドライバのインストール](https://docs.oracle.com/ja-jp/iaas/autonomous-database-shared/doc/connecting-python-prepare.html)
- [pythonからOracleを操作する「cx_Oracle」が「python-oracledb」になったのでさっそく使ってみた | ヒノマルクのデータ分析ブログ](https://www.hinomaruc.com/cx_oracle-updated-to-python-oracledb/)
  
javaだとThin?



## 参考

- [【 Python 】cx_OracleでOracleにアクセスしよう！ | 趣味や仕事に役立つ初心者DIYプログラミング入門](https://resanaplaza.com/2021/09/06/%E3%80%90-python-%E3%80%91cx_oracle%E3%81%A7oracle%E3%81%AB%E3%82%A2%E3%82%AF%E3%82%BB%E3%82%B9%E3%81%97%E3%82%88%E3%81%86%EF%BC%81/)
- [大手IT企業が提供するサンプルデータセット まとめ](https://zenn.dev/mom/articles/ba2f5a0bff3729)