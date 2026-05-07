INSERT INTO fact_product_popularity (
    week_id,
    product_id,
    mentions_count,
    weighted_sentiment,
    avg_author_influence,
    raw_trends_index,
    anchor_keyword_index,
    normalized_trends_index,
    load_timestamp,
    batch_id
)
SELECT
    TO_CHAR(t.week_date, 'IYYY-IW'),
    t.product_id,

    COALESCE(m.mentions_count, 0),
    COALESCE(m.weighted_sentiment, 0),
    COALESCE(m.avg_author_influence, 0),

    t.raw_trends_index,
    t.anchor_keyword_index,
    t.normalized_trends_index,

    NOW(),
    t.batch_id
FROM agg_trends t
LEFT JOIN agg_mentions m
ON t.week_date = m.week_date
AND t.product_id = m.product_id;