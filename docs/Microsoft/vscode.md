# VScode Tips

## ショートカット

### 領域移動

| Key               | 説明                             |
| ----------------- | -------------------------------- |
| Ctrl + Shift + E  | エクスプローラーに移動(Ctrl + Q) |
| Ctrl + 1          | 領域1個目をフォーカス            |
| Ctrl + Shift + O  | アウトラインを選択               |
| Ctrl + Alt + 左右 | 開いているタブの領域移動         |
| Ctrl + P          | ファイルを検索                   |
| Ctrl + @          | ターミナル開閉 & 移動            |
| Ctrl + ←          | フォルダを閉じる                 |


### テキスト編集中

| Key              | 説明                           |
| ---------------- | ------------------------------ |
| Ctrl + B         | サイドバー開閉                 |
| Ctrl + \         | エディタを左右に分割           |
| Ctrl + Shift + \ | 対応するカッコに飛ぶ           |
| Ctrl + Shift + L | 選択されている単語をすべて選択 |
| F3               | 選択している次の単語に移動     |
| Alt+Left         | カーソル位置を戻る             |



### 参考

[キーボードから手を離さずにVS Codeで開発したいという気持ちを大切にしています - 10bace LOG](https://insider.10bace.com/2019/02/22/vs-code%E3%81%A8%E3%81%8B%E3%81%AE%E3%82%B7%E3%83%A7%E3%83%BC%E3%83%88%E3%82%AB%E3%83%83%E3%83%88%E3%81%AE%E3%81%AF%E3%81%AA%E3%81%97/)

## 自分用設定

### フォント設定

設定 > "font"を検索 > Editor: Font Family を編集
```
Consolas, 'Courier New', monospace
↓
'BIZ UDゴシック', Consolas, 'Courier New', monospace
```
- `MS Gothic` でもいい？
- BIZ UDGothic

### ローカル編集履歴

ローカル編集履歴を有効/無効化

workbench.localHistory.enabled

C:\Users\<username>\AppData\Roaming\Code\User\History

[VS Code Local history ローカル履歴（タイムライン）の使い方](https://www.webdesignleaves.com/pr/plugins/vscode-local-history.html)

### エクスプローラの改行

Settings > 検索項目にTree Indent

### サジェスト

Enterを押してもSuggestされたワードが入力されないようにする      
Settings > accept > Accept Suggestion On Enter をオフに

### 表示ファイル設定変更

[ファイルの表示・検索・監視のExclude設定をする](https://dlrecord.hatenablog.com/entry/2020/11/22/144540)

### スティッキースクロール

```
Sticky Scroll: Enabled
Sticky Scroll: Max Line Count
```