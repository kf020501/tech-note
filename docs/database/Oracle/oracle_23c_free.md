# Oracle 23c Free

## Oracle Database 23c Freeとは？

Express Editionの名称変更ver

> - CPU性能上限 2コア相当まで
> - Oracle メモリ 2GB
> - ユーザーデータ 12GB
> - 論理環境ごとに1つのインストールのみ

[Oracle Database 23c Free – Developer Releaseがリリースされました！ | コーソルDatabaseエンジニアのBlog](https://cosol.jp/techdb/2023/04/oracle_23c_free_released/)


## インストール

AlmaLinux 8.xへのインストールをしてみる。  
ダウンロードはここから  
[Oracle Database 23cを使い始める | オラクル | Oracle 日本](https://www.oracle.com/jp/database/free/get-started/)  
-> RedHat互換Oracle Linux 8ディストリビューション

```sh
dnf install -y oracle-database-preinstall*
dnf install -y oracle-database-free*
/etc/init.d/oracle-free-23c configure
```




