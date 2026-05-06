CREATE OR REPLACE VIEW latest_google_trends AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY date, keyword, product_id
               ORDER BY snapshot_timestamp DESC
           ) rn
    FROM stg_google_trends_raw
) t
WHERE rn = 1;

CREATE OR REPLACE VIEW latest_mentions AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY mention_id
               ORDER BY snapshot_timestamp DESC
           ) rn
    FROM stg_mentions_raw
) t
WHERE rn = 1;

CREATE OR REPLACE VIEW latest_sales AS
SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY order_id
               ORDER BY snapshot_timestamp DESC
           ) rn
    FROM stg_sales_raw
) t
WHERE rn = 1;