# Gitメモ

## インストール後の初期設定

設定は `/,gitconfig に保存される
```sh
# 必須
git config --global user.name "UserName"
git config --global user.email "username@example.com"

# 必須ではないが推奨? (設定していないとgit init した際に怒られる)
git config --global init.defaultBranch master

# あると便利
git config --global core.editor vim           # コメント時のエディタをvimに
git config --global core.editor 'code --wait' # コメント時のエディタをvscodeに
git config --global color.ui auto

# 確認
git config --global -l
```


## ローカルでの操作

### プロジェクトの初期化
```sh
git init
```

### ステージング

```sh
# ファイル/ディレクトリ をステージに入れる (VsCodeでは、Mとなっているのがステージされた)
git add readme.md
git add sampledir

# 既にステージにあるファイルを全てステージ
git add -u

# 確認 -s でハッシュ値も表示
git ls-files -s
git status
```

- readme.md はステージに入っていない新規ファイル
- hello.txt は前回commit済みのファイル

```text
[user@redhat8 git_test]$ git status
On branch master
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        new file:   readme.md

Changes not staged for commit:
  (use "git add <file>..." to update what will be committed)
  (use "git restore <file>..." to discard changes in working directory)
        modified:   hello.txt
```

↓ `git add -u` を実行

```text
[user@redhat8 git_test]$ git status
On branch master
Changes to be committed:
  (use "git restore --staged <file>..." to unstage)
        modified:   hello.txt
        new file:   readme.md
```

### コミット

```sh
git commit
```
コマンド実行後、コメントの入力が求められる。  
例えば、以下のように書くといいかも。

| 書き方       | 説明         |
| ------------ | ------------ |
| first commit | 初回コミット |
| update: xxxx | 機能修正     |
| fix: xxxx    | バグ修正     |

## リモートへの操作

### gitリポジトリへの登録

GitHubのリポジトリをローカルリポジトリとして追加。  
構文: `git remote add <name> <url>`
```sh
git remote add origin https://github.com/YourUsername/YourRepoName
```
上記コマンドを実行すると、`.git/config`に記録される
```text
[remote "origin"]
    url = https://github.com/YourUsername/YourRepoName.git
    fetch = +refs/heads/*:refs/remotes/origin/*
```

### リモートリポジトリにpush

```sh
# git push <プッシュ先> <ブランチ名>
git push origin master
```

### リモートとの差分を確認
```sh
git fetch
git status

   # リモートと同じ場合の例
   # $ git status
   # On branch master
   # Your branch is up to date with 'origin/master'.
   #
   # nothing to commit, working tree clean

   # ローカルに、より新しいファイルがある場合の例
   # $ git status
   # On branch master
   # Your branch is up to date with 'origin/master'.
   #
   # Changes not staged for commit:
   #   (use "git add <file>..." to update what will be committed)
   #   (use "git restore <file>..." to discard changes in working directory)
   #         modified:   readme.md
   #
   # no changes added to commit (use "git add" and/or "git commit -a")
```


## その他使い方

### HEAD、ステージ、作業ツリーの比較

```sh
# 作業ツリー(現在のファイル) vs ステージ
git diff

# HEAD(最新のコミット) vs ステージ
git diff --staged

# 作業ツリー(現在のファイル) vs HEAD(最新のコミット)
git diff HEAD
```

### commitの取り消し

```
git reset --soft HEAD^
```
初回コミットの取り消しは上記コマンドでは出来ない。
(ChatGPT曰くあきらめて.gitを刑してやり直せとの事)



### .gitignore


### ブランチ

```sh
# ブランチを作成
git branch <ブランチ名>

# ブランチ一覧を表示
git branch
git branch -a # リモートリポジトリ込み

# フォーカスしているブランチを変更
git switch <ブランチ名>

# ブランチを新規作成して切り替え
git switch -c <ブランチ名>
```

### ファイルサーバをリポジトリに

1. ファイルサーバーで、ベアリポジトリを作成します：
   ```bash
   git init --bare /path/to/repository.git
   ```
2. ローカルマシンで、この新しいリポジトリをリモートとして追加します：
   ```bash
   git remote add fileserver /path/to/repository.git
   ```
3. ローカルブランチをファイルサーバーにプッシュします：
   ```bash
   git push fileserver your-branch
   ```

### コメント書き方
参考:   
[Gitのコミットメッセージの書き方 - Qiita](https://qiita.com/itosho/items/9565c6ad2ffc24c09364)


## リモートリポジトリ関連

### APIでリポジトリを作成

GitHubのsettings > Developer settings(項目下部) > Personal access tokens からPATを生成

```sh
curl -u 'username:token' -X POST https://api.github.com/user/repos -d '{"name":"repo-name", "private":false}'
```