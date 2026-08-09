jqコマンド(json整形)
================================================================================

jsonを扱えるツール。  
RHEL8.xには標準で入っている模様。

使用するサンプル
------------------------------------------------------------

```json
{
  "people":[
      {"ID":1,"NAME":"Alice","BIRTHDAY":"1990-01-01","GENDER":"female"},
      {"ID":2,"NAME":"Bob","BIRTHDAY":"1985-02-15","GENDER":"male"},
      {"ID":3,"NAME":"Charlie","BIRTHDAY":"1980-03-20","GENDER":"male"},
      {"ID":4,"NAME":"David","BIRTHDAY":"1992-04-10","GENDER":"male"},
      {"ID":5,"NAME":"Eva","BIRTHDAY":"1993-05-05","GENDER":"female"}
  ]
}
```


出力形式の変更
------------------------------------------------------------

### 整形形式

改行やインデントをいい感じにしてくれる
```sh
echo $json_data | jq .
```

結果
```json
{
  "people": [
    {
      "ID": 1,
      "NAME": "Alice",
      "BIRTHDAY": "1990-01-01",
      "GENDER": "female"
    },
    {
      "ID": 2,
        :
    }
  ]
}
```

### コンパクト形式(-c)

改行しない形式

```sh
echo $json_data | jq -c .
```
結果
```
{"people":[{"ID":1,"NAME":"Alice","EMAIL":"alice@example.com","BIRTHDAY":"1990-01-01","GENDER":"female"},{"ID":2,"NAME":"Bob","EMAIL":"bob@example.com","BIRTHDAY":"1985-02-15","GENDER":"male"},{"ID":3,"NAME":"Charlie","EMAIL":"charlie@example.com","BIRTHDAY":"1980-03-20","GENDER":"male"},{"ID":4,"NAME":"David","EMAIL":"david@example.com","BIRTHDAY":"1992-04-10","GENDER":"male"},{"ID":5,"NAME":"Eva","EMAIL":"eva@example.com","BIRTHDAY":"1993-05-05","GENDER":"female"}]}
```


データ加工
------------------------------------------------------------

### 指定した要素を表示

peopleの中身を表示
```sh
echo $json_data | jq '.people'
```
結果 (peopleの中身だけ表示されている点に注目)
```json
[
    {
      "ID": 1,
      "NAME": "Alice",
      "BIRTHDAY": "1990-01-01",
      "GENDER": "female"
    },
    {
      "ID": 2,
      "NAME": "Bob",
        :
    }
]
```

people"配列"の中身を表示
```sh
echo $json_data | jq '.people[]'
```
結果 (配列の中身だけ表示されている点に注目)
```json
{
    "ID": 1,
    "NAME": "Alice",
    "BIRTHDAY": "1990-01-01",
    "GENDER": "female"
},
{
    "ID": 2,
    "NAME": "Bob",
    :
}
```

people"配列"内の要素のNameだけ表示
```sh
echo $json_data | jq '.people[].NAME'
```
結果 (Nameだけ表示された)
```json
"Alice"
"Bob"
"Charlie"
"David"
"Eva"
```

### 選択したキーのみ表示(KeyValue)

波カッコ
```sh
echo $json_data | jq '.people[] | {ID, NAME}'
```

結果
```
{
  "ID": 1,
  "NAME": "Alice"
}
{
  "ID": 2,
  "NAME": "Bob"
}
    :
```

### 選択したキーのみ表示(配列)

大カッコ

```sh
echo $json_data | jq '.people[] | [.ID, .NAME]'
```

```
[
  1,
  "Alice"
]
[
  2,
  "Bob"
]
    :
```

### 選択したキーのみ表示(csv, tsv)

- `-r` で生の値(ダブルクオートなどがなくなる)
- `@csv` と `@tsv`はJSONオブジェクトそのものではなく、配列形式に変換したデータに対して使う必要がある。

```sh
echo $json_data | jq -r '.people[] | [.ID, .NAME] | @csv'
```
結果
```
1,"Alice"
2,"Bob"
3,"Charlie"
4,"David"
5,"Eva"
```

```sh
echo $json_data | jq -r '.people[] | [.ID, .NAME] | @tsv'
```
結果
```
1       Alice
2       Bob
3       Charlie
4       David
5       Eva
```

### 複数のキーを列にして表示

```sh
echo $json_data | jq -r '.people[] | "\(.ID) \(.NAME)"'
```
結果
```
1 Alice
2 Bob
3 Charlie
4 David
5 Eva
```

### フィルタリング(select)

GENDER が femaleの要素を週出
```sh
echo $json_data | jq '.people[] | select(.GENDER == "female")'
```
```
{
  "ID": 1,
  "NAME": "Alice",
  "BIRTHDAY": "1990-01-01",
  "GENDER": "female"
}
{
  "ID": 5,
  "NAME": "Eva",
  "BIRTHDAY": "1993-05-05",
  "GENDER": "female"
}
```

オプション
------------------------------------------------------------

### `-r`: 生の値(ダブルクオートなどがなくなる)

-r なしの場合
```sh
echo $json_data | jq '.people[].NAME'
```
結果
```
"Alice"
"Bob"
"Charlie"
"David"
"Eva"
```

-r ありの場合
```sh
echo $json_data | jq -r '.people[].NAME'
```
結果
```text
Alice
Bob
Charlie
David
Eva
```


一緒に使うLinuxコマンド
------------------------------------------------------------

### column

- テーブルっぽく整形してくれる
- -t: 入力が含まれる列数を決めて、テーブルを作成する。デフォルトでは列は空白で区切られる。
- -s <文字>: 区切り文字指定

```sh
# column使わない例
echo $json_data | jq -r '.people[] | [.ID, .NAME, .BIRTHDAY, .GENDER] | @csv'
# column使う例
echo $json_data | jq -r '.people[] | [.ID, .NAME, .BIRTHDAY, .GENDER] | @csv' | column -t -s , 
```

```
[user@hostname ~]$ echo $json_data | jq -r '.people[] | [.ID, .NAME, .BIRTHDAY, .GENDER] | @csv'
1,"Alice","1990-01-01","female"
2,"Bob","1985-02-15","male"
3,"Charlie","1980-03-20","male"
4,"David","1992-04-10","male"
5,"Eva","1993-05-05","female"
[user@hostname ~]$ 
[user@hostname ~]$ echo $json_data | jq -r '.people[] | [.ID, .NAME, .BIRTHDAY, .GENDER] | @csv' | column -t -s , 
1  "Alice"    "1990-01-01"  "female"
2  "Bob"      "1985-02-15"  "male"
3  "Charlie"  "1980-03-20"  "male"
4  "David"    "1992-04-10"  "male"
5  "Eva"      "1993-05-05"  "female"
```

### sort

`sort -k 並び替えフィールド -t 区切り文字 ファイル名`

- 並び替えしてくれる
- 区切り文字のデフォルトはtab?
- -r: 降順で並び替え
- -n: 数値として並び替え
- -f: 大文字小文字を区別しない

```sh
# column使わない例
echo $json_data | jq -r '.people[] | [.ID, .NAME, .BIRTHDAY, .GENDER] | @tsv'
# column使う例
echo $json_data | jq -r '.people[] | [.ID, .NAME, .BIRTHDAY, .GENDER] | @tsv' | sort -k 3
```
誕生日順に並び変わっている
```
[user@hostname ~]$ echo $json_data | jq -r '.people[] | [.ID, .NAME, .BIRTHDAY, .GENDER] | @tsv'
1       Alice   1990-01-01      female
2       Bob     1985-02-15      male
3       Charlie 1980-03-20      male
4       David   1992-04-10      male
5       Eva     1993-05-05      female
[user@hostname ~]$ 
[user@hostname ~]$ echo $json_data | jq -r '.people[] | [.ID, .NAME, .BIRTHDAY, .GENDER] | @tsv' | sort -k 3
3       Charlie 1980-03-20      male
2       Bob     1985-02-15      male
1       Alice   1990-01-01      female
4       David   1992-04-10      male
5       Eva     1993-05-05      female
```