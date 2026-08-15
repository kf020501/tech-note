# winget（Windows Package Manager）

Windows標準のパッケージ管理ツール。Windows 11には標準搭載。
アプリの検索・インストール・更新・アンインストールをコマンド一つで行える。

## よく使うコマンド

### 検索
```powershell
winget search "アプリ名"
```

### インストール
```powershell
winget install <ID>
```
例:
```powershell
winget install Microsoft.VisualStudioCode
winget install Git.Git
winget install JGraph.Draw
winget install Python.Python.3.13
winget install 7zip.7zip
winget install SQLite.SQLite
```

### インストール済み一覧を見る
```powershell
winget list
```

### 更新があるものを確認
```powershell
winget upgrade
```

### 全部まとめて更新
```powershell
winget upgrade --all
```

### 特定のアプリのみ更新
```powershell
winget upgrade 7zip.7zip
```

### アンインストール
```powershell
winget uninstall <ID>
```

## メモ

- `search`で出てくる「ID」列の値を`install`に渡す（名前だけだと候補が複数出ることがある）。
- すでにGUIでインストール済みのアプリでも、レジストリ情報からwingetが自動認識してくれることが多い（`winget list`で確認可能）。
