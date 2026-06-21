# signal-to-sales

PostgreSQL ETL pipeline that combines Google Trends and Mention API data into a weekly product popularity fact table (`fact_product_popularity`). 
Data is ingested from both APIs, stored as snapshots, transformed in SQL, and aggregated to weekly product metrics. Sales staging is in the schema but not connected yet.

Inspired by Kolchyna's research on using social media and Google Trends data for sales forecasting.

---

## How it works

Scripts in `ingestion/` fetch data for keywords defined in `config/keywords.csv` and append rows to staging (`stg_google_trends_raw`, `stg_mentions_raw`). Each run gets a `batch_id` and `snapshot_timestamp`.

In SQL (`sql/staging_views.sql`), the latest record wins via `ROW_NUMBER()` — Last-Value-Wins on the natural key. Transformations (`sql/transformations.sql`) normalize trends, aggregate to weekly grain, and compute influence-weighted sentiment from mentions. Finally, `sql/load_fact_product_popularity.sql` loads trends and mentions into `fact_product_popularity`.

```
keywords.csv → ingest → stg_*_raw → latest_* → agg_* → fact_product_popularity
```

---

## Problems the pipeline had to solve

### Google Trends snapshots

Google Trends returns a relative popularity score (0–100), not search volume. Historical values can change between pulls, so each request is appended as a snapshot rather than overwriting existing rows.

SQL then selects the latest snapshot per `(date, keyword, product_id)`.

Each product keyword is fetched alongside **"Weather"** as an anchor — a stable reference point for normalizing the scale:

```sql
raw_trends_index / NULLIF(anchor_keyword_index, 0) AS normalized_trends_index
```

### Different grain and duplicate loads

Trends and mentions are daily; early attempts to load directly into the fact table caused primary key conflicts and duplicates. The fix was **weekly aggregation** before the load — a shared calendar for both sources.

### Weighted mention sentiment

From the Mention API, the pipeline uses `tone` (sentiment) and `author_influence_score` (author reach). Weekly sentiment is an influence-weighted average, rescaled to 0–100 so it can be compared with Trends metrics:

```sql
((SUM(tone * author_influence_score) / NULLIF(SUM(author_influence_score), 0)) + 1) * 50 AS weighted_sentiment
```

### Keyword → product mapping

The current mapping relies on exact keyword matches from `config/keywords.csv`. More flexible solution would include searches matching based on meaning rather than exact keywords. 

---

## Repository structure

- `ingestion/` – Google Trends and Mention API ingestion
- `config/keywords.csv` – keyword → product_id → alert_id mapping
- `data_model/schema.sql` – staging, fact, and sales scaffold tables
- `sql/staging_views.sql` – Last-Value-Wins deduplication views
- `sql/transformations.sql` – trend normalization, mention metrics, and weekly aggregations
- `sql/load_fact_product_popularity.sql` – load into `fact_product_popularity`

## Next step

The schema already includes sales-related tables and fact columns. The next step is to ingest sales data, integrate it into the fact load, and see if spikes in search interest or sentiment show up before sales increase.