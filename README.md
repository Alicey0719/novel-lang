# Original Language

## コンセプト

美少女ノベルゲームの世界観を表現した言語。

## 構文ルール

-   文列:
    -   `文 (文)*` (よくわかってない)
-   文:
    -   代入
    -   分岐
    -   繰り返し
    -   出力
    -   分列
-   代入文:
    -   `【変数】式`  
        ※ （）は全角丸括弧  
        ※ 変数が初めに来ると因子との区別が大変かも
-   条件分岐:
    -   `🤔式……文(真)……文(偽)`  
        ※「……」は U+2026 を 2 つ (echo -e "\u2026\u2026")
        <!-- 美少ゲーテキストで多用される「……」 -->
-   繰り返し:
    -   `🕑式……文`  
        ※「……」は U+2026 を 2 つ (echo -e "\u2026\u2026")
        <!-- できない私が繰り返すから時計 -->
-   出力:
    -   `「式」`
-   式:
    -   `⛄calcの式準拠⛄`
        <!-- ハミダシクリエイティブ 雪景シキから雪だるま(肉まん,雪結晶の絵文字が微妙だったため) -->
    -   不等号比較もほしい
-   項:
    -   `因子 (( ‘*’ | ‘/’ ) 因子)*` (Calc 準拠)
-   因子:
    -   `リテラル | 【変数】 | ‘(‘ 式 ‘)’` (Calc 準拠)
-   その他
    -   文字列扱いたい？
    -   Bool がほしい？

## 注意

-   絵文字がちゃんと出力されるターミナルと、うまく出力できないターミナルがある。  
    (VSCode, WindowsTerminal, Terminal(Mac) は問題なし。コマンドプロンプト, PowerShell, Termius はだめ。)

## こんな感じ？

### 例 1

```
【華乃】131
【天梨】317
🤔　華乃】>天梨】……答え】(華乃】-天梨】)……答え】天梨-華乃】)
「答え」
```

> 186

## 内部仕様

### メンバ変数

### メソッド
