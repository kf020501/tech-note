# DNSサーバ構築

## 環境

```text
[root@dns-sv ~]# hostnamectl
  Operating System: AlmaLinux 8.7 (Stone Smilodon)
            Kernel: Linux 4.18.0-348.2.1.el8_5.x86_64
```

## インストール

```sh
# インストール
dnf -y install bind

# バージョン確認
named -v
# BIND 9.11.36-RedHat-9.11.36-5.el8_7.2 (Extended Support Version)
```

## named.conf 設定

/etc/named.conf

```js
options {
        // 受ける範囲を指定
        // listen-on port 53 { 127.0.0.1; };    // コメントアウト  
        // listen-on-v6 port 53 { ::1; };       // コメントアウトls
        listen-on port 53 { any; };             // 追記

        // ゾーンファイルを格納するディレクトリ
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";

        // 問い合わせを受け付けるホスト
        // allow-query     { localhost; };                      // コメントアウト
        // allow-query     { localhost; internal-network; };    // 例: internal-networkを許可する場合
        allow-query     { any; };                               // 追記

        // 再帰問い合わせ
        recursion yes;            // 追記 再帰問い合わせ可否 キャッシュサーバならそのままyes
        allow-recursion { any; }; // 追記 再帰問い合わせを許可するホスト

        dnssec-enable yes;
        dnssec-validation yes;

        managed-keys-directory "/var/named/dynamic";

        pid-file "/run/named/named.pid";
        session-keyfile "/run/named/session.key";

        /* https://fedoraproject.org/wiki/Changes/CryptoPolicy */
        include "/etc/crypto-policies/back-ends/bind.config";

        //バージョンの隠蔽
        version "DNS Server"; // 追記 
};

logging {
        channel default_debug {
                file "data/named.run";
                severity dynamic;
        };
};

// ルートDNSサーバの設定
zone "." IN {
        type hint;
        file "named.ca";
};

// キャッシュならここまででOK
// 名前解決するなら以下も記載

// 追記 example.net の正引き設定
zone "example.net" IN {
        type master;
        file "example.net.zone";
};

// 追記 example.net の逆引き設定
zone "0.0.10.in-addr.arpa" IN {
        type master;
        file "0.0.10.in-addr.arpa,zone";
};

include "/etc/named.rfc1912.zones";
include "/etc/named.root.key";
```

## 参考

[CentOS Stream 8 : BIND : 内部ネットワーク向けの設定 : Server World](https://www.server-world.info/query?os=CentOS_Stream_8&p=dns&f=1)
