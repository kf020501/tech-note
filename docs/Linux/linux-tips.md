---
title: "LinuxTips"
tags: ["Linux"]
date: 2022-05-18
weight: 100
draft: false
---

## 日付文字列作成

```sh
datestr=`date +%Y-%m-%d`
echo $datestr

timestr=`date +%Y-%m-%d_%H-%M-%S`
echo $timestr
```

## メモリとは？ (記載中)

total とか chache とか buff とか、ふわっとしかわからないので調べた。


### 関係性

```test

|<--------------------------------- total -------------------------------------->|

<-------- used -------->|<-------- buff/cache -------->|<---------- free ---------->|

                        |<-- 解放不可 -->|<--開放可能-->|
                                        |<-------- Avail Mem ---------------------->|
```

### 

- total
    - サーバに搭載されているメモリ総量
- used
    - OSやアプリケーションに割り当て済みの消費量

- buffer
    - メモリに存在するデータのうち、ディスクにフラッシュされているもの
    - 定期的にbdflushデーモンによってディスクにフラッシュされる
- cached
    - プログラムが使用していたメモリで実行中 or 新しい起動プログラムが必要に応じ再利用できるもの
- free
    - 未使用領域
- Avail Mem 
    - ★ すぐに割り当て可能な領域
### 参考


- [Linuxのtop コマンドの見方 ~メモリやload averageの単位,定義,目安~ | SEの道標](https://milestone-of-se.nesuke.com/sv-basic/linux-basic/top-command/)
- [4.メモリ使用率(第5章 パフォーマンス管理～上級:基本管理コースII)](https://users.miraclelinux.com/technet/document/linux/training/2_5_4.html)
- [inuxフリーメモリの理解 - 日本エクセム株式会社 Oracleその他技術情報](https://www.ex-em.co.jp/blog/oraclegijutsujoho9/)



## Script
```bash
script -a ~/scr_`date +%Y-%m-%d`.log # -a:追記 -f:都度書き込む

#なんならログイン時に自動実行させてもいい？
vi ~/.bash_profile
script -a ~/scr_`date +%Y-%m-%d`.log
#秒まで指定→ script ~/scr_`date +%Y-%m-%d_%H%M%S`.log

#なおPS
Start-Transcript <ファイル名> → Stop-Transcript
```


## プログレスバー実装
```bash
echo -ne '#####                     (33%)\r'
sleep 1
echo -ne '#############             (66%)\r'
sleep 1
echo -ne '#######################   (100%)\r'
echo -ne '\n'
```


## ファイル名一括変換
[【rename】Linuxでファイル名を一括変更するコマンド | UX MILK](https://uxmilk.jp/8366)
```
$ rename 置換する文字列 置換後の文字列 ファイル名 ファイル名２ ...
$ rename 2014 2015 2014-*.txt
```

[Bashのコンソールで単語移動するショートカット - Qiita](https://qiita.com/odacoh/items/b94be0deecaaa27b0263)
[bashで設定ファイルを読み込む | UNIX | 株式会社CONFRAGE](https://www.confrage.com/unix/sh/conf_file/conf_file.html)

[execコマンド（コマンドを実行して終了する）](http://itdoc.hitachi.co.jp/manuals/3020/30203S3530/JPAS0288.HTM)
[【 tee 】コマンド――標準出力とファイルの両方に出力する：Linux基本コマンドTips（65） - ＠IT](https://www.atmarkit.co.jp/ait/articles/1611/16/news022.html)

## vi しようとしたら "Found a swap file ... " と出る

```
Found a swap file by the name ".xxxxx.swp"
```

- viを強制終了したりすると、同一ディレクトリに`.xxxxx.swp`が作成されるので、それの警告。
- `.xxxxx.swp`を削除すれば警告は出なくなる。
- 状況に応じて`.xxxxx.swp` を削除、バックアップ、復元 などするといい


## pingコマンド
```sh
ping -c 5 10.30.0.xxx    # -c 回数指定 5回のみ送信
ping -I eth0 10.30.0.xxx # -I インターフェイス指定
ping -i 10 10.30.0.xxx    # -i 間隔指定 10秒間隔
ping -s 10 10.30.0.xxx    # -s サイズ指定

```

## コマンドを後からnohupにする

1. Ctrl+Z でコマンドを中断
2. `jobs` でジョブリストを表示し、停止したコマンドのジョブ番号を確認
3. `bg %1` でバックグラウンド実行に変更 (%1部分はjobs結果で確認)
4. `disown %1`でログアウトしても実行されるように変更 (%1部分はjobs結果で確認)

## sort

フィールドを指定して並び替え
```sh
sort -k 並び替えフィールド -t 区切り文字 ファイル名
```

- -n 数値として並び替え
- -r 降順で並び替え
- -f 大文字小文字を区別しない

## column

-s 区切り文字指定
```
column -t -s :
```

## 設定ファイルからコメントと空行削除
```
cat hgoehoge.ini | grep -vE '^\s*(#|$)'
```

## パッケージのダウンロードのみを行う

```sh
dnf install --downloadonly --destdir ./ <package_name>
```