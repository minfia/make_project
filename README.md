# プロジェクト生成スクリプト
プロジェクトの新規生成、ソースコードの生成を行う

## 環境
* bash

## 対応言語
* C言語
* Python


## 使い方

### 新規プロジェクト生成
`$ ./make_project.sh project new_project`  
デフォルト設定
* カレントディレクトリに`new_project`ディレクトリを生成  
* 言語は`C言語`  
* 文字コードと改行コードは`UTF-8`と`LF`  
* Doxyfile生成

### 新規ファイル生成
`$ ./make_project.sh file file_name -o ./src`  
デフォルト設定
* カレントディレクトリに`file_name`を作成(C言語はソースとヘッダ)
* 言語は`C言語`
* 文字コードと改行コードは`UTF-8`と`LF`

### 引数一覧
* --lang  
   言語を指定
* --enc  
   文字コードを指定
* --lf  
   改行コードを指定
* -o, --output  
   出力先を指定
* --no-doxyfile  
   Doxyfileを作らない
* -h, --help  
   ヘルプを表示

