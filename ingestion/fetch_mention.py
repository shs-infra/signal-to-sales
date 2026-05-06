import requests
import pandas as pd
from datetime import datetime
import os
import uuid
from sqlalchemy import create_engine

API_TOKEN = os.getenv("MENTION_API_TOKEN")
ACCOUNT_ID = "YOUR_ACCOUNT_ID"

engine = create_engine(os.getenv("DB_URL"))
batch_id = str(uuid.uuid4())

keywords_df = pd.read_csv("config/keywords.csv", sep=";")

headers = {
    "Authorization": f"Bearer {API_TOKEN}",
    "Accept": "application/json"
}

all_mentions = []

for _, row in keywords_df.iterrows():

    keyword = row["keyword"]
    product_id = row["product_id"]
    alert_id = row["alert_id"]

    try:

        url = f"https://api.mention.com/api/accounts/{ACCOUNT_ID}/alerts/{alert_id}/mentions"

        response = requests.get(url, headers=headers)
        response.raise_for_status()

        mentions = response.json().get("mentions", [])

        for m in mentions:

            mention_id = m["id"]

            detail_url = f"{url}/{mention_id}"

            detail = requests.get(detail_url, headers=headers).json()

            all_mentions.append({
                "mention_id": mention_id,
                "keyword": keyword,
                "product_id": product_id,
                "published_at": detail.get("published_at"),
                "tone": detail.get("tone"),
                "author_influence_score": detail.get("author_influence", {}).get("score"),
                "snapshot_timestamp": datetime.now(),
                "batch_id": batch_id
            })

        print(f"Fetched: {keyword}")

    except Exception as e:
        print(f"Error: {e}")

if all_mentions:

    df = pd.DataFrame(all_mentions)

    df.to_sql(
        "stg_mentions_raw",
        engine,
        if_exists="append",
        index=False
    )