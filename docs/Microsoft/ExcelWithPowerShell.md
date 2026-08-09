# ExcelをPowershellで操作

## 共通 前処理

```ps1
# オブジェクト作成(Excel起動)
$excel = New-Object -ComObject Excel.Application

# Excel を表示
$excel.Visible = $true

# 警告メッセージを表示？
$excel.DisplayAlerts = $true
```

## Excelを開く

### パターン1: 既存のExcelを開く

```ps1
$excelFilePath = "C:\work\sample.xlsx"

# Excelファイルを開く 
#.Workbooks.Open(ファイルパス, 関数やリンクなどを更新するか, 読み込み専用か)
$book = $excel.Workbooks.Open($excelFilePath, 0, $false)
```

### パターン2: 新規Excelを開く

```ps1
$book = $excel.Workbooks.Add()
```

## 基本的な編集

### シート関連

```ps1
# シートの追加
$sheet = $workbook.Worksheets.Add()

# 変数にシートを格納
$sheet = $book.Sheets("hoge")

# 1 番目のシートの名前を取得
$sheet = $book.Sheets(1)

# アクティブになっているシート名を取得
$sheet = $book.ActiveSheet.Name

# シートの数を取得
$book.Sheets.Count

# シート名の変更
$book.Sheets(1).Name = "hoge"
```

### セルの値の操作

```ps1
# 100 を挿入
$sheet.Cells.Item(1, 1) = 100

# テキストを取得
$text = $sheet.Cells(1, 1).Text

# 計算式を表示
$formula = $sheet.Cells(1, 1).Formula
```

### セルの装飾

### 最終行の取得
```ps1
$eof = $sheet.UsedRange.Rows.Count
```

## 保存

```PS1
# 警告メッセージを非表示(上書き確認しないことで強制上書き)
$excel.DisplayAlerts = $false

$book.SaveAs("C:\work\sample.xlsx")
$excel.Quit()
```

## 共通 変数の破棄

```ps1
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($excel) # 変数の破棄
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($book) # 変数の破棄
[System.Runtime.Interopservices.Marshal]::ReleaseComObject($sheet) # 変数の破棄
```

## 応用的な編集

### 関数を使用

```ps1
$excel.WorksheetFunction.VLookup($lookupValue, $tableArray, $columnIndex, $rangeLookup)
```