# GeminiAPI


## 資料概要
無料で使用できる生成AIのAPIを探したところ見つけたので、使い方のメモ。


## 事前準備
以下ページでAPIキーを取得。GoogleアカウントがあればOK.  
[API キーを取得 | Google AI Studio](https://aistudio.google.com/apikey)

## 使い方
```sh
api_key="YOUR_API_KEY"
curl \
  -H "Content-Type: application/json" \
  -d "{'contents':[{'parts':[{'text':'初めてGeminiAPIを使用します。どんな事が出来ますか？'}]}]}" \
  -X POST "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent?key=$api_key"
```

## 整形メモ

```sh
result.txt | jq -r '.candidates[].content.parts[].text'
```


## 参考資料
- [Gemini APIの使い方 #Python - Qiita](https://qiita.com/RyutoYoda/items/a51830dd75a2dac96d72)
- [API キーを取得 | Google AI Studio](https://aistudio.google.com/apikey)

