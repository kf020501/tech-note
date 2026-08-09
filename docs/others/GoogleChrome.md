# GoogleChrome Tips

## キャッシュクリア(Chrome)

Ctrl + Sheft + R


## 現在のページのリンクを作成

ブックマークレット用

### Markdown用


```js
javascript:(function(){var title=document.title;var url = document.location.href;var result='['+title+']('+url+')';var CC = document.createElement('textarea');CC.textContent = result;var BD = document.getElementsByTagName('body')[0];BD.appendChild(CC);CC.select();var cpEXE = document.execCommand('copy');BD.removeChild(CC);window.alert('結果'+'\n'+result);})()
```
結果
```test
[Google](https://www.google.com/)
```

ブックマークレットは最終的に1行にしなければならないっぽい。     
改行したものは以下
```js
function(){
    var title=document.title;
    var url = document.location.href;
    var result='['+title+']('+url+')';

    var CC = document.createElement('textarea');
    CC.textContent = result;
    
    var BD = document.getElementsByTagName('body')[0];
    BD.appendChild(CC);
    CC.select();
    
    var cpEXE = document.execCommand('copy');
    BD.removeChild(CC);window.alert('結果'+'\n'+result); // 結果通知の表示
}
```

### Excel用

```js
javascript:(function(){var title=document.title;var url = document.location.href;var result='=HYPERLINK("'+url+'","'+title+'")';var CC = document.createElement('textarea');CC.textContent = result;var BD = document.getElementsByTagName('body')[0];BD.appendChild(CC);CC.select();var cpEXE = document.execCommand('copy');BD.removeChild(CC);window.alert('%E7%B5%90%E6%9E%9C'+'\n'+result);})();
```
結果
```test
=HYPERLINK("https://www.google.com/","Google")
```

### html用

```js
javascript:(function(){var title=document.title;var url = document.location.href;var result='<a href="'+url+'" target="_blank">'+title+'</a>';var CC = document.createElement('textarea');CC.textContent = result;var BD = document.getElementsByTagName('body')[0];BD.appendChild(CC);CC.select();var cpEXE = document.execCommand('copy');BD.removeChild(CC);window.alert('結果'+'\n'+result);})()
```
結果
```test
<a href="https://www.google.com/" target="_blank">Google</a>
```


### タイトル URL テキスト

```js
javascript:(function(){var title=document.title;var url = document.location.href;var result=title+'\n'+url;var CC = document.createElement('textarea');CC.textContent = result;var BD = document.getElementsByTagName('body')[0];BD.appendChild(CC);CC.select();var cpEXE = document.execCommand('copy');BD.removeChild(CC);window.alert('結果'+'\n'+result);})()
```
結果
```test
Google
https://www.google.com/
```

## URLを新しいタブで開く

```js
javascript:(function(){open('https://xxxx.xxxx/xxxx/xxxx','_blank','width=800,height=600,scrollbars=1');})()
```