CREATE OR REPLACE VIEW latest_google_trends AS
SELECT
    id,
    date,
    keyword,
    product_id,
    raw_trends_index,
    anchor_keyword_index,
    snapshot_timestamp,
    batch_id
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY date, keyword, product_id
               ORDER BY snapshot_timestamp DESC
           ) AS rn
    FROM stg_google_trends_raw
) t
WHERE rn = 1;

CREATE OR REPLACE VIEW latest_mentions AS
SELECT
    mention_id,
    published_at,
    tone,
    author_influence_score,
    keyword,
    product_id,
    snapshot_timestamp,
    batch_id
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY mention_id
               ORDER BY snapshot_timestamp DESC
           ) AS rn
    FROM stg_mentions_raw
) t
WHERE rn = 1;

CREATE OR REPLACE VIEW latest_sales AS
SELECT
    order_id,
    order_date,
    product_id,
    quantity,
    revenue,
    snapshot_timestamp,
    batch_id
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY snapshot_timestamp DESC
           ) AS rn
    FROM stg_sales_raw
) t
WHERE rn = 1;