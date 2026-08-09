# OpenSSL

## Linuxから、対象ホスト:ポートのスキャン

```sh
# 対象ポートがTLS1.1を使用しているか確認
openssl s_client -connect 10.30.0.xx:443 -tls1_1
```