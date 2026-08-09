---
title: "AutHotKey"
tags: ["memo"]
date: 2022-01-08
weight: 100
draft: false
---

```

vk1D & R::Reload ;スクリプトを再読み込み(デバッグ用)

;----------------------------------------
;無変換+ で方向キー,Home,End,Delete
;----------------------------------------
vk1D & P::Send, {Blind}{Up}
vk1D & N::Send, {Blind}{Down}
vk1D & B::Send, {Blind}{Left}
vk1D & F::Send, {Blind}{Right}
;----------------------------------------
vk1D & A::Send, {Blind}{Home}
vk1D & E::Send, {Blind}{End}
;----------------------------------------
vk1D & D::Send, {Blind}{Delete}
vk1D & H::Send, {Blind}{BackSpace}
;----------------------------------------
vk1D & [::Send, {Blind}{Esc}
vk1D & M::Send, {Blind}{Enter}

;----------------------------------------
; F13::return     ;無変換を無効化(間違い防止)
; F13 & [::Send, {Blind}{PgUp}
; F13 & ]::Send, {Blind}{PgDn}

;----------------------------------------
;無変換+"-" で入力
;----------------------------------------
F13 & -::
    Clipboard =  ----------
    Send, ^v
return

;----------------------------------------
;無変換+I で現在時刻入力
;----------------------------------------
F13 & I::
    TimeString = A_Now
    FormatTime, TimeString,, yyyy/MM/dd HH:mm:ss
    clipboard = %TimeString%
    Send, ^v
return

;----------------------------------------
;無変換+T テスト用
;----------------------------------------
F13 & T::
    Clipboard = hogehoge
    send, {Tab}
    Send, ^v
    Send, {Down}
    send, {Tab}
    Send, ^v
    Send, {Down}
    send, {Tab}
    Send, ^v
    Send, {Down}
return

; 参考: emacsのキーバインド
; - カーソル移動
;     - Ctrl + F: 1文字右
;     - Ctrl + B: 1文字左
;     - Ctrl + P: 1行上
;     - Ctrl + N: 1行下
;     - Ctrl + A: 行の先頭
;     - Ctrl + E: 行の末尾
;     - Ctrl + Option + F: 1単語後
;     - Ctrl + Option + B: 1単語前
;     - Ctrl + V: 1ページ前
;     - Ctrl + L: カーソルを中央になるようにスクロール
; - 削除
;     - Ctrl + H: 前の文字を削除
;     - Ctrl + D: 後の文字を削除
;     - Ctrl + K: 行末まで削除(カット)
;     - Ctrl + Y: 貼り付け(yank)
; - その他
;     - Ctrl + T: カーソル前後の文字を入れ替え
;     - Ctrl + O: 改行追加
;     - Ctrl + [: Esc

```