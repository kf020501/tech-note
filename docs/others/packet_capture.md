# パケットキャプチャ


## Windows

netsh コマンドで採取
```ps1
# 開始
netsh trace start capture=yes tracefile=FILENAME.etl

# 停止
netsh trace stop
```
etlファイルは直接WireShaekで読み込めないため、etl2pcapng(Microsoft製のツール) で変換する。

[GitHub - microsoft/etl2pcapng: Utility that converts an .etl file containing a Windows network packet capture into .pcapng format.](https://github.com/microsoft/etl2pcapng)

```ps1
.\etl2pcapng.exe FILENAME.etl FILENAME.cap
```

なお、以前.etl → .cap 変換で使用されていた、Microsoft Network Monitorは廃止?された模様

Windows10/WindowsServer2019以上は、キャプチャにkptmonというのもある。

## Linux

tcpdump コマンドで採取
```sh
# 構文
tcpdump [option] [filter]

# 例1: 「インターフェイスens192」「arpでない」「ポート22を含まない」
tcpdump -i ens192 not arp and not port 22

# 例2: 「インターフェイスens192」「ホストに192.168.10.110を含む」「ポート22を含まない」「dumpfile.cap に書き出す」
tcpdump -i ens192 -w dumpfile.cap host 192.168.10.110 and not port 22

# 例3: 「インターフェイスens192」「arpでない」「ホストに192.168.10.254を含まない」 
tcpdump -i ens192 not arp and not host 192.168.10.254
```

| オプション      | 説明                                                        |
| --------------- | ----------------------------------------------------------- |
| -i ens192       | インターフェイス ens192 をキャプチャ                        |
| -w dumpfile.cap | キャプチャ結果をファイル名「dumpfile.cap」に書き出す        |
| -A              | キャプチャデータをASCIIで表示                               |
| -r              | dumpfile.cap   # キャプチャデータ「dumpfile.cap」を読み込む |


| フィルタ        | 説明                       |
| --------------- | -------------------------- |
| port 22         | 22番ポートを含む           |
| host 10.30.0.100 | ホストに 10.30.0.100 を含む |
| src host        | ソースホストが  10.30.0.100 |
| dst host        | 宛先ホストが 10.30.0.100    |



## 解析(WireShark)