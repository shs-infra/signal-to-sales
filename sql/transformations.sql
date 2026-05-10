CREATE OR REPLACE VIEW clean_trends AS
SELECT
    date,
    keyword,
    product_id,
    batch_id,
    DATE_TRUNC('week', date) AS week_date,
    raw_trends_index,
    anchor_keyword_index,
    raw_trends_index / NULLIF(anchor_keyword_index, 0) AS normalized_trends_index
FROM latest_google_trends;

CREATE OR REPLACE VIEW agg_trends AS
SELECT
    week_date,
    product_id,

    AVG(raw_trends_index) AS raw_trends_index,
    AVG(anchor_keyword_index) AS anchor_keyword_index,
    AVG(normalized_trends_index) AS normalized_trends_index,

    MAX(batch_id) AS batch_id

FROM clean_trends
GROUP BY 1,2;

CREATE OR REPLACE VIEW agg_mentions AS
SELECT
    DATE_TRUNC('week', published_at) AS week_date,
    product_id,

    COUNT(*) AS mentions_count,

    (
        (
            SUM(tone * author_influence_score)
            / NULLIF(SUM(author_influence_score), 0)
        ) + 1
    ) * 50 AS weighted_sentiment,

    AVG(author_influence_score) AS avg_author_influence

FROM latest_mentions
GROUP BY 1,2;