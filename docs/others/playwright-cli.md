# Playwright CLI

## 概要

### Playwright CLIとは

`playwright-cli` は、Playwright を CLI で直接操作するためのツール。
公式 README では「Playwright CLI with SKILLS」として、
コーディングエージェント（Claude Code / Copilot など）での利用を主用途にしている。

### インストール
グローバルインストール:
```bash
npm install -g @playwright/cli@latest
playwright-cli --help
```

Skill をローカルへインストール:
```bash
playwright-cli install --skills
```

README では、Skill-less でも `--help` からエージェントが使える説明がある。

## 使い方
### ステップ例1（最初の1本）
目的: TodoMVC に2件追加し、1件完了して証跡を残す。
1. ブラウザを起動して対象ページを開く（目視確認のため `--headed` を付与）。
```bash
playwright-cli open https://demo.playwright.dev/todomvc/ --headed
```
2. 1件目を入力して Enter。
```bash
playwright-cli type "Buy groceries"
playwright-cli press Enter
```
3. 2件目を入力して Enter。
```bash
playwright-cli type "Water flowers"
playwright-cli press Enter
```
4. `snapshot` で要素参照（`e21` のような ref）を取得。
```bash
playwright-cli snapshot
```
5. 取得した ref を使って完了状態にする。
```bash
playwright-cli check e21
```
6. 状態をスクリーンショットで保存。
```bash
playwright-cli screenshot
```
補足: 既定は headless。表示したいときだけ `--headed` を使う。

### ステップ例2（セッションを分けて継続）
目的: 作業ごとにセッションを分離し、状態を保持する。
1. `work-a` セッションで開く（`--persistent` で状態保持）。
```bash
playwright-cli -s=work-a open https://example.com --persistent
```
2. 別作業を `work-b` セッションで開く。
```bash
playwright-cli -s=work-b open https://playwright.dev --persistent
```
3. セッション一覧を確認。
```bash
playwright-cli list
```
4. 不要セッションを閉じる。
```bash
playwright-cli close-all
# 強制終了が必要なときのみ
playwright-cli kill-all
```
5. エージェント起動時に固定セッションを渡す。
```bash
PLAYWRIGHT_CLI_SESSION=work-a claude .
```

### ステップ例3（失敗時の確認）
目的: 「クリックできない」「画面が違う」を短時間で切り分ける。
1. 監視ダッシュボードを開く。
```bash
playwright-cli show
```
2. 現在 DOM の参照を取り直す。
```bash
playwright-cli snapshot
```
3. 問題箇所を画像で残す。
```bash
playwright-cli screenshot
```
4. 画面全体を PDF で残す（報告向け）。
```bash
playwright-cli pdf
```
5. 必要なら戻って再試行する。
```bash
playwright-cli go-back
playwright-cli reload
```

### 最小コマンドセット（覚える順）
1. `open` / `goto`: ページを開く
2. `snapshot`: ref を取得する
3. `click` / `fill` / `type` / `press`: 操作する
4. `screenshot` / `pdf`: 証跡を残す
5. `list` / `close-all` / `show`: 運用と監視

### 現在ページのHTMLを取得する
全体を取得する方法:
```bash
# ページ全体
playwright-cli eval "() => document.documentElement.outerHTML"

# body配下だけ
playwright-cli eval "() => document.body.outerHTML"
```

DOMを選択して取得する方法:
```bash
# CSSセレクタで指定（例: main）
playwright-cli eval "() => document.querySelector('main')?.outerHTML"

# id/classで指定
playwright-cli eval "() => document.querySelector('#app')?.outerHTML"
playwright-cli eval "() => document.querySelector('.card')?.outerHTML"
```

`snapshot` の ref を使って取得する方法:
```bash
playwright-cli snapshot
# 例: e21 のHTMLを取得
playwright-cli eval "(el) => el.outerHTML" e21
```

## Edge と AD認証

### 認証を維持した運用(AI出力 未検証)

Microsoft Edge の操作は可能。認証を維持したい場合は次の2パターンを使う。

パターン1: Playwright 側で Edge プロファイルを継続利用
```bash
playwright-cli open https://your-app.example --browser=msedge --persistent --profile=/path/to/profile-dir
```
同じ `--profile` を使い続けることで、ログイン状態や cookie の再利用がしやすくなる。

パターン2: 実行中のEdgeに接続（認証引き継ぎ向け）
```bash
playwright-cli open https://your-app.example --extension
```
README 記載の Edge/Chrome 拡張連携を使う方法で、既存のブラウザ認証状態を活用しやすい。

### Edge運用の注意点
- 企業ポリシーでブラウザ自動化が制限される場合がある
- 既存本番プロファイルを直接使うとロック/破損リスクがあるため、専用プロファイル運用が安全

