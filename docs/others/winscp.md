# WinSCP Tips

## コマンドでファイルダウンロード

どうしてもパスワード認証しなければならない環境で、定期的にログ採取する事になったので調べてみた。    
teratermマクロとかもあったが、複数ファイルダウンロードがめんどくさそう。    
なお前提として、パスワードを平文保存することになるので、可能なら素直に鍵認証したほうが当然いい。

[スクリプト機能 - WinSCP Wiki - WinSCP - OSDN](https://ja.osdn.net/projects/winscp/wiki/scripting)

以下のようにスクリプトを作成し保存。`C:\work\winscp_macro.txt`
```sh
# バッチモードに設定し、確認/問い合わせを無効にする
option batch on
# ファイル上書きの確認などを無効にする
option confirm off

# サーバーに接続
#   ユーザー名: username
#   パスワード: xxxxxxxxxx
#   ホスト名: 10.30.0.10
open username:xxxxxxxxxx@10.30.0.10

# リモートディレクトリを変更
cd /var/log
# バイナリモードに変更
option transfer binary
# ファイルを C:\work\ に保存
get messages* C:\work\
# 切断
close
# 終了
exit
```

コマンドプロンプトで以下のように指定して実行できる
```
.\WinSCP.exe /console /script=C:\work\winscp_macro.txt /log=C:\work\winscp.log
```

補足    

- 今回使用したのは WinSCP-5.19.2-Portable
- 同名ファイルがあった場合上書きされる