# signal-to-sales

PostgreSQL ETL pipeline that ingests demand signals from Google Trends and the Mention API, processes them in SQL, and loads a weekly product popularity mart (`fact_product_popularity`).

The pipeline covers the full flow from API ingestion and snapshot-based staging, transformations, and mart loading. The current implementation focuses on external demand signals; sales ingestion and correlation analysis are planned as the next stage.

Inspired by Kolchyna's research on using social media and Google Trends data for sales forecasting.

---

## Overview

The goal was to combine Google Trends and social media data into a weekly product-level fact table while preserving source and ingestion lineage.

The two sources have different constraints, levels of granularity, and data quality challenges that the pipeline had to handle.

---

## How it works

Scripts in `ingestion/` fetch data for keywords defined in `config/keywords.csv` and append rows to staging (`stg_google_trends_raw`, `stg_mentions_raw`). Each run gets a `batch_id` and `snapshot_timestamp`.

In SQL (`sql/staging_views.sql`), the latest record wins via `ROW_NUMBER()` — Last-Value-Wins on the natural key. Transformations (`sql/transformations.sql`) normalize trends, aggregate to weekly grain, and compute influence-weighted sentiment from mentions. Finally, `sql/load_fact_product_popularity.sql` loads trends and mentions into `fact_product_popularity`.

```
keywords.csv → ingest → stg_*_raw → latest_* → agg_* → fact_product_popularity
```

---

## Problems the pipeline had to solve

### Google Trends rewrites history

Trends does not return search counts — only a relative index (0–100) that may change between pulls, so the pipeline stores snapshots instead of overwriting data.

Each run appends new rows with a timestamp. SQL then selects the latest snapshot per `(date, keyword, product_id)`.

Each product keyword is fetched alongside **"Weather"** as an anchor — a stable reference point for normalizing the scale:

```sql
raw_trends_index / NULLIF(anchor_keyword_index, 0) AS normalized_trends_index
```

### Different grain and duplicate loads

Trends and mentions are daily; early attempts to load directly into the fact table caused primary key conflicts and duplicates. The fix was **weekly aggregation** before the load — a shared calendar for both sources.

### Social sentiment — not every mention counts equally

From the Mention API, the pipeline uses `tone` (sentiment) and `author_influence_score` (author reach). Weekly sentiment is an influence-weighted average, rescaled to 0–100 so it can be compared with Trends metrics:

```sql
((SUM(tone * author_influence_score) / NULLIF(SUM(author_influence_score), 0)) + 1) * 50 AS weighted_sentiment
```

### Keyword → product mapping

For now, a manual exact-match map in `config/keywords.csv`. A future improvement would be semantic matching instead of exact keyword mapping.

---

## Repository structure

- `ingestion/` – Google Trends and Mention API ingestion
- `config/keywords.csv` – keyword → product_id → alert_id mapping
- `data_model/schema.sql` – schema definition, dimensions, staging and fact tables
- `sql/staging_views.sql` – Last-Value-Wins deduplication views
- `sql/transformations.sql` – trend normalization, mention metrics, and weekly aggregations
- `sql/load_fact_product_popularity.sql` – load into `fact_product_popularity`

## Next step

The schema already includes sales-related tables and fact columns. The next step is to ingest sales data, integrate it into the fact load, and evaluate whether search interest or social sentiment can act as leading indicators of future sales.