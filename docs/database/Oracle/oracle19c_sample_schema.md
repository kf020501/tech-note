# Oracle19cサンプルスキーマ

## OverView

dbcaからのインストール時にもインストールできるが、後付けで入れたい場合やほかのサンプルも使用したい場合、Githubから取得してインストール可能。

- ダウンロード: [Releases · oracle-samples/db-sample-schemas](https://github.com/oracle-samples/db-sample-schemas/releases)
- スキーマの説明: [Introduction to Sample Schemas](https://docs.oracle.com/en/database/oracle/oracle-database/19/comsc/introduction-to-sample-schemas.html#GUID-844E92D8-A4C8-4522-8AF5-761D4BE99200)

今回は db-sample-schemas-19.2 を使用する。

## インストール

`/home/oracle`に、ダウンロードしたdb-sample-schemas-19c.zipを配置。

```sh
# 解凍
unzip db-sample-schemas-19.2.zip
# インストーラーで指定する、ログの出力先を作成
mkdir /home/oracle/db-sample-install_log

# 移動
cd db-sample-schemas-19.2
# スクリプト内のカレントディレクトリを修正する(pwdで/が返ってくるので、#を区切り文字にしている模様)
sed -i "s#__SUB__CWD__#`pwd`#g" *.sql */*.sql */*.dat

sqlplus / as sysdba
```
```sql
-- サンプルスキーマ用の表領域を作成(任意)
CREATE TABLESPACE sample;

-- @?/demo/schema/mksample <SYSTEM_password> <SYS_password> 
--                 <HR_password> <OE_password> <PM_password> <IX_password> 
--                 <SH_password> <BI_password> EXAMPLE TEMP 
--                 $ORACLE_HOME/demo/schema/log/ localhost:1521/pdb
@mksample system sys hr oe pm ix sh bi sample temp /home/oracle/db-sample-schemas_log/ localhost:1521/orcl
```


## アンインストール


## 

### 参考

- [サンプル・スキーマのインストール](https://docs.oracle.com/cd/E96517_01/comsc/installing-sample-schemas.html#GUID-4D4984DD-A5F7-4080-A6F8-6306DA88E9FC)
- [Oracle DBでサンプルスキーマを作成する手順について – Rainbow Engine](https://rainbow-engine.com/oracle-db-sample-schema/)
- [[Oracle21c]サンプルスキーマのインストール – ラーメン屋になりたいシステムエンジニアのメモ張](https://www.fuku.tokyo/tools/2022/09/23/sample-schemas/)
