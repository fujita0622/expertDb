5-1 下記5つのテーブルから、以下の要件を満たす結果を得るためのSQL文を考えてください。
なお、テーブル名、列名、データの値は下記のテーブルのものを使用するものとします。

-支店商品テーブル
支社コード/支店コード/商品コード
001/01/001
001/01/002
001/01/003
001/02/002
001/02/003
001/02/004
001/02/005
001/02/006
002/01/001
002/01/002
002/02/007
002/02/008


-支社テーブル
支社コード/支社名
001/東京
002/大阪


-支店テーブル
支社コード/支店コード/支店名
001/01/渋谷
001/02/八重洲
002/01/堺
002/02/豊中


-商品テーブル
商品コード/商品名/商品分類コード
001/石鹸/C1
002/タオル/C1
003/歯ブラシ/C1
004/コップ/C1
005/箸/C2
006/スプーン/C2
007/雑誌/C3
008/爪切り/C4


-商品分類テーブル
商品分類コード/商品名
C1/水洗用品
C2/食器
C3/書籍
C4/日用品


[SQL文1] 商品の分類ごとの商品数、結果には分類名を含むものとする。
[SQL文2] 支社/支店別の取り扱い商品の一覧。結果には支社名、支店名、商品名を含むものとします。
[SQL文3] 最も取り扱い商品数が多い支店の支店コードと商品数。

5-2 演習5-1の解答のSQL文に対して、パフォーマンス向上を実施します。本章で学んだ非正規化を含むテーブル構成の変更による方法を考えてください。

[5-1.回答]
[SQL文1]
-- 取得列
-- 商品テーブルのp_c_code列の値ごとの集計値
-- 商品分類テーブルのp_c_name列
SELECT 
  COUNT(product.p_c_code) AS 商品分類ごとの商品数,
  p_classification.p_c_name AS 分類名
-- 商品テーブル(product)を商品分類テーブル(p_classification)と内部結合
FROM
  product
LEFT JOIN
  p_classification
-- 結合条件
-- 商品テーブル(product)のp_c_code列と商品分類テーブル(p_classification)のp_c_code列
ON
  product.p_c_code = p_classification.p_c_code
GROUP BY
  -- グループ化する列
  -- 商品分類テーブル(p_classification)のp_c_name列をグループ化
  p_classification.p_c_name
;

[出力結果]
 商品分類ごとの商品数 |  分類名  
----------------------+----------
                    2 | 食器
                    1 | 書籍
                    4 | 水洗用品
                    1 | 日用品
(4 rows)


[SQL文2]
SELECT
  -- 取得列
  o_name AS 支社名,
  s_name AS 支店名,
  p_name AS 商品名
FROM
  -- サブクエリ
  (SELECT 
    b_shop_product.o_code, -- 支店商品.支社コード
    b_shop_product.s_code, -- 支店商品.支店コード
    b_shop_product.p_code, -- 支店商品.商品コード
    b_office.o_name -- 支社.支社名
  -- 支店商品テーブルに支社テーブルを内部結合
  FROM
      b_shop_product -- 支店商品テーブル
    INNER JOIN
      b_office -- 支社テーブル
    ON
    -- 結合条件
    -- 支社テーブルのo_code列と支店商品テーブルの o_code列
      b_office.o_code = b_shop_product.o_code
    ) AS o_shop_product -- 支社/支店商品テーブル
  -- 支社/支店商品テーブルに支店テーブルを内部結合
  INNER JOIN
    b_shop -- 支店テーブル
  ON
    -- 結合条件
    -- 支店テーブルのo_code列と支社/支店商品テーブルの o_code列 かつ
    -- 支店テーブルのs_code列と支社/支店商品テーブルの s_code列
    b_shop.o_code = o_shop_product.o_code
  AND
    b_shop.s_code = o_shop_product.s_code
  -- 商品/支店商品テーブルに支店テーブルを内部結合
  INNER JOIN
    product -- 商品テーブル
  ON
    -- 結合条件
    -- 商品テーブルのp_code列と支社/支店商品テーブルの p_code列 かつ
    product.p_code = o_shop_product.p_code
;

[出力結果]
 支社名 | 支店名 |  商品名  
--------+--------+----------
 東京   | 渋谷   | 石鹸
 東京   | 渋谷   | タオル
 東京   | 渋谷   | ハブラシ
 東京   | 八重洲 | タオル
 東京   | 八重洲 | ハブラシ
 東京   | 八重洲 | コップ
 東京   | 八重洲 | 箸
 東京   | 八重洲 | スプーン
 大阪   | 堺     | 石鹸
 大阪   | 堺     | タオル
 大阪   | 豊中   | 雑誌
 大阪   | 豊中   | 爪切り
(12 rows)


[SQL文3]
SELECT
  -- 取得列
  s_code AS 支店コード,
  p_count AS 商品数
FROM
-- サブクエリ
-- 支店商品テーブルから
-- 支社コード,支店コード,支店別の商品数 を取得
  (SELECT o_code, s_code, COUNT(p_code) AS p_count FROM b_shop_product GROUP BY o_code,s_code) AS count_shop_product
WHERE 
  -- 取得条件
  -- 商品数の最大値
  p_count = (SELECT MAX(p_count)
    FROM
-- サブクエリ
-- 支店商品テーブルから
-- 支店別の商品数 を取得
    (SELECT COUNT(p_code) AS p_count FROM b_shop_product GROUP BY o_code,s_code) AS count_s_product_only);


[出力結果]
 支店コード | 商品数 
------------+--------
 02         |      5
(1 row)


[5-2.回答]
[SQL文1]
商品分類テーブルに商品数の合計値を入れる「商品数」列を追加し、内部結合せずに商品分類テーブルで完結するテーブル構造に変更する。

[SQL文2]
支店商品テーブルの各コードと関連する名の列を追加すれば4表を内部結合することなく支店商品テーブルだけで完結するテーブル構造に変更する。

[SQL文3]
本章で学んだ非正規化を行う箇所がありません。


