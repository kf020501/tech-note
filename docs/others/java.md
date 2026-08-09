# Java

Java屋さんと仕事をしているがJavaの事が全然わからないので、
ちょっとだけかじってみる。

## 環境

- RedHat版 OpenJDK 1.8.0
- WindowsServer 2019

## 環境構築

### JDLインストール

JDK (Java Development Kit)をインストールする。  
今回はRedHat版を使用。

ダウンロードはここから      
[Red Hat build of OpenJDK Download | Red Hat Developer](https://developers.redhat.com/products/openjdk/download)

PATHも通っているはず。
```text
PS C:\Users\Administrator> java -version
openjdk version "1.8.0_345"
OpenJDK Runtime Environment (build 1.8.0_345-b01)
OpenJDK 64-Bit Server VM (build 25.345-b01, mixed mode)
PS C:\Users\Administrator>
```

そもそもJDKとは？ ⇒ Javaを開発するためのソフトウェア一式。以下のものが入っている

- javac(コンパイラ)
- JRE(Java実行環境: HavaRuntimeEnvironment)
    - JVM(Java Virtual Machine) → コンパイルした中間言語が、この上で動く
    - API
        - Java SE(Java Platform, Standard Edition) → Java で使用される基本的なAPIをまとめたもの
        - Java EE(Java Platform, Enterprise Edition) → 大規模なシステムを開発する場合に必要となる APIをまとめたもの

### IDE

Eclipse使いたかったけど、参考にした資料に使い方が乗っていなかった。。   
ので、VScodeで開発。

### HelloWorld

実行までの流れは以下

1. .java にコード記載
2. `javac <.javaのファイルパス>`で、コードをコンパイル (クラス名.class ファイルが出来る)
3. `java <クラス名>` で実行

HelloWorld.java を作成し、以下を記入。(コメントありの場合はSHIFT-JISでないとダメ??)

```java
// class名は、ファイル名に合わせる
class HelloWorld {
	public static void main(String[] args) {

        // メイン処理部分
		System.out.println("Helloworld!");

	}
}
```

```powershell
# コンパイル
# HelloWorld.class というファイルが出来る
javac .\HelloWorld.java

# 実行
java HelloWorld

    # 実行結果
    # PS ...\java> java HelloWorld        
    # Helloworld!
```

## .jarについて

中身を確認
```sh
# パターン1
jar tf some.jar

# パターン2
unzip -l some.jar
```

展開せずに中身を確認
```sh
unzip -p some.jar path/to/file.properties
```

.properties の編集
```sh
# .jarファイルから特定の.propertiesファイルを抽出
jar xf some.jar path/to/file.properties

# 編集した.propertiesファイルで.jarファイルを更新
jar uf some.jar path/to/file.properties
```



## 参考

- [Java - Wikipedia](https://ja.wikipedia.org/wiki/Java)
- [Java | Java SEとJDK、JRE、JVMの違いに関する解説](https://www.javadrive.jp/start/install/index5.html#section3)

