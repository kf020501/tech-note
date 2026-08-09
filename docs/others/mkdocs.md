
# mkdocs-material 環境構築

WordPressに始まり、Wiki系とかHugoとかドキュメント管理を色々試して、   
2022/09現在、最終的にこちらに行きついた。

[Material for MkDocs](https://squidfunk.github.io/mkdocs-material/)

## Python仮想環境の作成

```sh
# ベースディレクトリ作成
mkdir mkdocs; cd mkdocs

# venv作成
dnf install python3
python3 -m venv mkdocs.venv
. mkdocs.venv/bin/activate

# 以下だと何故かエラーが出る 8.2.12がおかしい？
# pip install mkdocs-material==8.2.12
pip install mkdocs-material==8.2.11

# サイト作成
mkdocs new .

```
```text
mkdocs
├─ docs/            ----> ここにコンテンツを作成していく
│  └─ index.md
├─ mkdocs.venv      ----> pythonのvenv
└─ mkdocs.yml       ----> 設定ファイル
```

## 使い方
```sh
# venvに入るため毎回実行
. mkdocs.venv/bin/activate
# 抜ける場合
deactivate 

# 書きながらプレビュー
mkdocs serve

# ビルド
mkdocs build
```

## シンタックスハイライト

使い方が翼わからなかったが、以下の記事を参考にしたら設定できた

[MkDocsによるドキュメント作成](https://zenn.dev/mebiusbox/articles/81d977a72cee01#%F0%9F%93%8C-%E3%82%B3%E3%83%BC%E3%83%89%E3%83%8F%E3%82%A4%E3%83%A9%E3%82%A4%E3%83%88)

```yaml
site_name: 技術ノート
theme:
  name: material
  language: ja

  # https://squidfunk.github.io/mkdocs-material/setup/setting-up-navigation/#navigation-sections
  features:
    - navigation.sections
  hide:
    - footer

  # フォント https://squidfunk.github.io/mkdocs-material/setup/changing-the-fonts/#regular-font
  # ここから選ぶ https://fonts.google.com/
  font:
    text: Open Sans
    code: Inconsolata

extra_css:
  # コンテンツ幅設定
  - stylesheets/extra.css

markdown_extensions:
  - pymdownx.highlight:
      use_pygments: true
      noclasses: true
      # https://pygments.org/styles/ ここから選択
      pygments_style: borland
      # pygments_style: stata-light
```

## その他

### アイコン

ここから使わせてもらっています。    
[商用可の無料(フリー)のアイコン素材をダウンロードできるサイト『icon rainbow』 | カラフルな商用利用可能なアイコン素材を無料でダウンロード!!](https://icon-rainbow.com/)