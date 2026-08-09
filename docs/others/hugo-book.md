---
title: "Hugo - WEBサイト作成"
date: 2021-11-22
draft: false
weight: 100
tags: ["Linux", "Ubuntu", "Install"]
---

# Hugo 構築

## 概要

今までWordPressに備忘録を作成したんだけど、静的サイトジェネレータ"Hugo"に切り替えるので、
作業手順を記録しておくよ。

切り替える理由は以下。
- 普段はVScodeでMarkdownに試したことをメモしている。
- はじめはWordpressに転記していたが、途中で面倒になり結局使わなくなった。
- Wordpressが乗っているCentOS8がもうすぐサポート切れ(なのでいいタイミング)
- 別に静的に拘りはないけど、以下を満たすものが見つからなかった(※)
  - Markdownの記事がVScodeで直接書ける
  - ブログ形式でなく、ドキュメントっぽく?したい。(時系列順でなく、Wikiっぽく?)
  - 全文検索がある


google様が作成した「Docsy」をいうテーマは使いこなせなかったので、
Bookというシンプルテーマを使う。

- [The world’s fastest framework for building websites | Hugo](https://gohugo.io/)
- [Book | Hugo Themes](https://themes.gohugo.io/themes/hugo-book/)
- [Welcome to Docsy | Docsy](https://www.docsy.dev/docs/)

※ 実は全くなかったわけではないが(Gollum, Wiki.js)、デザインがあまり好みでなかった。あとセキュリティとか。

動的でないのにどうやって全文検索しとるん？  

## Hugo インストール

Ubuntu Server20.04を使用。

`apt install hugo` でも可能だが、横着せずに[Docsy公式ドキュメント](https://www.docsy.dev/docs/getting-started/)に沿ってインストールする。  



[ここ](https://github.com/gohugoio/hugo/releases)  から、インストールするExtendedなバージョンを見つける。

.debパッケージもあったが、今回は手順に則り `hugo_extended_0.89.4_Linux-64bit.tar.gz` を使用。   
URLを確認して、wgetするところからスタート。
```sh
# URLを確認したファイルをダウンロード
wget https://github.com/gohugoio/hugo/releases/download/v0.89.4/hugo_extended_0.89.4_Linux-64bit.tar.gz

# ディレクトリ作成し、そこにDLしたファイルを展開
mkdir docsy
tar xfz hugo_extended_0.89.4_Linux-64bit.tar.gz -C ./docsy/

#展開したディレクトリに移動してinstall
cd docsy/
sudo install hugo /usr/bin/

# 動作確認兼 バージョン確認
hugo version

    # 実行例:
    # user@hugo:~$ hugo version
    # hugo v0.89.4-AB01BA6E+extended linux/amd64 BuildDate=2021-11-17T08:24:09Z VendorInfo=gohugoio
    # user@hugo:~$
```

## テーマインストール(Book)

[Book | Hugo Themes](https://themes.gohugo.io/themes/hugo-book/)

```sh
hugo new site mydocs; cd mydocs
git init
git submodule add https://github.com/alex-shpak/hugo-book themes/hugo-book
cp -R themes/hugo-book/exampleSite/content .
```


## 設定・記事作成

config.toml
```
baseURL = ''

languageCode = 'ja'
defaultContentLanguage = "ja"

title = '技術ノート'
theme = "hugo-book"
enableGitInfo = true

[params]
    # 更新日等を表示する際に必要だけど、今回はコメントアウト
    # BookRepo = 'https://github.com'
    # BookCommitPath = 'commit'
    # BookDateFormat = 'Jan 2, 2006'
    BookSection = '*'
```

## 検索が効かない問題

調べたところ、どうやら設定ファイルの `config.toml` に `defaultContentLanguage = "ja"` を書き込んだタイミングで検索が効かなくなっている模様。      
以下のファイルに言語の変換処理？が書かれていたので、これを編集したところ改善した。
- ./themes/hugo-book/i18n/ja.yaml
- ./themes/hugo-book/i18n/jp.yaml
``` sh
# 編集前にバックアップをとる
cd ./themes/hugo-book/i18n/
cp ja.yaml .ja.yaml.bk
cp jp.yaml .jp.yaml.bk

vi ja.yaml
vi jp.yaml
```
この個所を
```
- id: bookSearchConfig
  translation: |
    {
      encode: false,
      tokenize: function(str) {
        return str.replace(/[\x00-\x7F]/g, '').split('');
      }
    }
```
以下に編集(enなどにならった)
```
- id: bookSearchConfig
  translation: '{ cache: true }'
```

## メインコンテンツの横幅が狭い問題

`min-width` や `max-width` で全体検索したら以下が引っ掛かった。   
./themes/hugo-book/assets/_defaults.scss
```cs
// $body-min-width: 20rem !default;       // コメントアウト
$body-min-width: 25rem !default;
// $container-max-width: 80rem !default;  // コメントアウト
$container-max-width: 100rem !default;
```
直接編集でなく上書きする設定があるのかもしれないけど、わからなかった。    
web屋さんじゃないからゆるしておくれ。   

どうでもいいけど、Markdownのコードブロック、cssはどう書けばいいの？   
`css` だと反応してくれない。`cs`は反応するけど、C# になってる気がする。。。


## 記事作成

./content 配下が記事となるので、頑張って作成する