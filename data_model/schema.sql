CREATE TABLE dim_product (
    product_id INT PRIMARY KEY,
    product_name VARCHAR(255) NOT NULL,
    category VARCHAR(255),
    brand VARCHAR(255),
    main_keyword VARCHAR(255)
);

CREATE TABLE dim_date (
    week_id VARCHAR(10) PRIMARY KEY,
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    month INT,
    quarter INT,
    year INT
);

CREATE TABLE stg_google_trends_raw (
    id BIGSERIAL PRIMARY KEY,
    date DATE NOT NULL,
    keyword VARCHAR(255) NOT NULL,
    product_id INT NOT NULL,
    raw_trends_index FLOAT,
    anchor_keyword_index FLOAT,
    is_anchor_keyword BOOLEAN,
    snapshot_timestamp TIMESTAMP NOT NULL,
    batch_id VARCHAR(255),

    CONSTRAINT chk_raw_trends_index
        CHECK (raw_trends_index BETWEEN 0 AND 100),

    CONSTRAINT chk_anchor_keyword_index
        CHECK (anchor_keyword_index BETWEEN 0 AND 100)
);

CREATE TABLE stg_mentions_raw (
    mention_id VARCHAR(255),
    published_at TIMESTAMP NOT NULL,
    tone FLOAT,
    author_influence_score FLOAT,
    keyword VARCHAR(255),
    product_id INT,
    snapshot_timestamp TIMESTAMP NOT NULL,
    batch_id VARCHAR(255),

    PRIMARY KEY (mention_id, snapshot_timestamp),

    CONSTRAINT chk_tone CHECK (tone BETWEEN -1 AND 1),
    CONSTRAINT chk_author_influence CHECK (author_influence_score BETWEEN 0 AND 100)
);

CREATE TABLE stg_sales_raw (
    order_id VARCHAR(255) PRIMARY KEY,
    order_date DATE NOT NULL,
    product_id INT NOT NULL,
    quantity INT,
    revenue NUMERIC(12,2),
    snapshot_timestamp TIMESTAMP NOT NULL,
    batch_id VARCHAR(255),

    CONSTRAINT chk_quantity CHECK (quantity >= 0),
    CONSTRAINT chk_revenue CHECK (revenue >= 0)
);

CREATE TABLE fact_product_popularity (
    week_id VARCHAR(10),
    product_id INT,

    sales_volume INT,
    revenue NUMERIC(12,2),

    mentions_count INT,
    weighted_sentiment FLOAT,
    avg_author_influence FLOAT,

    raw_trends_index FLOAT,
    anchor_keyword_index FLOAT,
    normalized_trends_index FLOAT,

    load_timestamp TIMESTAMP,
    batch_id VARCHAR(255),

    PRIMARY KEY (week_id, product_id)
);