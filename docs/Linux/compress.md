---
title: "圧縮系"
date: 2022-01-01
draft: false
weight: 20
tags: ["Linux"]
---

## 概要

- Linux系ではtatでまとめてから圧縮が定番
- gzip: 早くて低圧縮 テキスト圧縮は強いみたい
- bzip2: gzipより遅くて高圧縮率
- xz: 遅くて高圧縮率 
- Windowsでよく使用するzipはサイズに注意
    - 4GBを越えるファイルや圧縮後に2GBを越えるファイルは圧縮できない
    - ファイルが破損してしまうが、見た目は圧縮できてしまう(怖い) → 古い形式のみ？

## よく使うコマンド

オプションのつけ方は諸説ある模様。ハイフンありなし、並び方など。  
なお、ハイフンありの場合は f の直後にファイル指定が必要。

```sh
# -c: 圧縮 (-z: gzip)
tar -czvf sample-dir.tgz sample-dir # sample-dirを圧縮

# -x: 展開 (-z: gzip)
tar -xzvf sample-dir.tgz            # sample-dir.tgz を展開(ソースは残る)


# -t: 内容確認 (-z: gzip)
tar -tzvf sample-dir.tgz sample-dir # sample-dir.tgz の内容を確認(-v でパーミッション表示)
less sample-dir.tgz                 # これでも行ける

# 特定ファイルのみ展開 (-z: gzip)
tar -xzvf sample-dir.tgz data01.txt # sample-dir.tgz 内の data01.txt のみ展開

# -O(オー): 解凍せずにファイル内容を確認(パイプでlessとかするといい)
tar -zxOf test.tgz ./data01.txt

# 圧縮形式を確認
file sample-dir.tgz

    # ---> sample-dir.tgz: gzip compressed data, last modified: Mon Jan  3 11:17:58 2022, from Unix, original size 10240

ls | xargs -I $ tar -I pigz -cvf $.tgz $
```

## tar
```sh
# 圧縮/アーカイブ (sampleファイル(またはディレクトリ)を xz形式に)
tar cfJ sample.tar.xz sample
tar cfz sample.tar.gz sample

# 展開
tar xfJ sample.tar.xz


    -c 新しいアーカイブを作成 (srcは残る)
    -x アーカイブファイルからファイルを展開 (srcは残る)

    -f アーカイブファイル名を指定
    -v 処理の詳細を表示

    -z gzipを通じて 圧縮/展開
    -j bzip2を通じて 圧縮/展開
    -J xzを通して圧縮/展開
```


## gzip

```sh
gzip sample         # sampleファイルを圧縮 
                    # sample.gz が作成され、sample は削除される

gzip -d sample.gz   # sample.gz を展開
                    # sample が作成され、sample.gz は削除される
gzip -c file > file.gz  # ファイルを残しつつ、file.gzをさくせい
    -c 元ファイルを残して標準出力に出力
    -r ディレクトリ内の全ファイルを それぞれ再帰的に圧縮
```

## xz
```sh
-d # 展開 --decompress
-k # 圧縮/展開後に元のファイルを維持 --keep
xz -l configure.xz      # 圧縮ファイルの情報を表示 --list
xzcat configure.xz    # 展開して標準出力へ
unxz        # 解凍
```

## bzip2 .bz2

```sh
# sampleファイルを圧縮
bzip2 sample
    # sample.bz2 が作成され、sample は削除される

bzip2 -d sample.bz2 # 解凍

bunzip2 sample.bz2  # 解凍
```


## zip
```sh
# 圧縮 ディレクトリ内のファイルをすべて
zip -r FILENAME.zip FILE_DIR    

# 圧縮 FILENAMEをパスワード付きで圧縮(対話入力)  --password=xxxx とすることでコマンド時に実行可能
zip -e FILENAME.zip FILENAME    


# unzip すべて展開
unzip FILENAME.zip

# パスワード付き 展開
unzip -P xxxx FILENAME.zip

# zipinfo 内容確認 パーミッションも表示される -1 でファイル名のみ表示
zipinfo FILENAME.zip

# 特定のファイルのみ解凍 -j でサブディレクトリを作成しない
unzip FILENAME.zip FILE_DIR/sample.txt 

# 解凍せずに内容確認 -p
unzip -p FILENAME.zip FILE_DIR/sample.txt

# 個人的によく使う
ls | xargs -I$ zip -r $.zip $
```


## zipファイルの容量制限について

- 古い形式のzipと、zip64という新しい形式のものがある。
- 古い形式: ファイルサイズ上限 圧縮前4G, 圧縮後2G 
- サイズオーバーしても圧縮時にはエラーにならない (解凍時にエラー)
- zip64であればサイズ上限の問題がない(上限 16EiB)
- info-zip の zip3 を使用していれば、zip64が使用される？(判定基準 あやしい)

```text
$ zip -v
Copyright (c) 1990-2008 Info-ZIP - Type 'zip "-L"' for software license.
This is Zip 3.0 (July 5th 2008), by Info-ZIP.
```

[zipファイルには容量制限がある！超える場合はどうすればいいのか？ | Aprico](https://aprico-media.com/posts/5977)
[[Info-Zip]BATファイルからの使用や容量制限](https://www.tksoft.work/archives/4132)


## マルチコア対応圧縮コマンド

参考: [マルチスレッド環境でのtar - みつきんのメモ](https://mickey-happygolucky.hatenablog.com/entry/2018/04/21/011811)

```
圧縮形式	圧縮伸張コマンド
GZIP	pigz
BZIP2	pbzip2
XZ（LZMA2)	pxz/pixz
```
- RHEL8には標準で入っていた
- Ubuntu20.04 には入っていないので `apt install pigz`
```sh
# tarするときは、-Iオプションで指定する
tar -I pigz -cf SampleDir.tgz ./SampleDir

# もしくは、パイプする ESXiもこちらであれば実行可能
tar cv SampleDir | pigz > SampleDir.tgz

# pigz -p 4 で、プロセス数を4で指定

# 解凍 
tar -xvf SampleDir.tar.gz --use-compress-prog=pigz
tar -xvf SampleDir.tgz -I pigz
```
tar c coffee | pigz > coffee_2023-01-07.tgz