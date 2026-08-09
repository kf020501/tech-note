# バイナリ編集


```test
★ 全て0の32バイトデータ作製
[user@redhat8 ~]$ dd if=/dev/zero of=testdata bs=32 count=1
1+0 レコード入力
1+0 レコード出力
32 bytes copied, 0.000170184 s, 188 kB/s
[user@redhat8 ~]$
[user@redhat8 ~]$ hexdump -Cv testdata
00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000010  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000020
[user@redhat8 ~]$

★ 16バイト目～ '\x41\x42' を書き込み
[user@redhat8 ~]$ echo -en '\x41\x42' | dd of=testdata bs=1 seek=16 conv=notrunc
2+0 レコード入力
2+0 レコード出力
2 bytes copied, 5.8771e-05 s, 34.0 kB/s
[user@redhat8 ~]$
[user@redhat8 ~]$ hexdump -Cv testdata
00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000010  41 42 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |AB..............|
00000020
[user@redhat8 ~]$

★ 24バイト目～ '\x5A'を書き込み
[user@redhat8 ~]$ echo -en '\x5A' | dd of=testdata bs=1 seek=24 conv=notrunc
1+0 レコード入力
1+0 レコード出力
1 byte copied, 6.7447e-05 s, 14.8 kB/s
[user@redhat8 ~]$
[user@redhat8 ~]$ hexdump -Cv testdata
00000000  00 00 00 00 00 00 00 00  00 00 00 00 00 00 00 00  |................|
00000010  41 42 00 00 00 00 00 00  5a 00 00 00 00 00 00 00  |AB......Z.......|
00000020
[user@redhat8 ~]$

★ 8バイト目～ 'C'を書き込み
[user@redhat8 ~]$ echo -n 'C' | dd of=testdata bs=1 seek=8 conv=notrunc
1+0 レコード入力
1+0 レコード出力
1 byte copied, 5.7408e-05 s, 17.4 kB/s
[user@redhat8 ~]$
[user@redhat8 ~]$ hexdump -Cv testdata
00000000  00 00 00 00 00 00 00 00  43 00 00 00 00 00 00 00  |........C.......|
00000010  41 42 00 00 00 00 00 00  5a 00 00 00 00 00 00 00  |AB......Z.......|
00000020
[user@redhat8 ~]$
```

