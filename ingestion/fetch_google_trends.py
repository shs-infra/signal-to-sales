from pytrends.request import TrendReq
import pandas as pd
from datetime import datetime
import os
import time
import uuid
from sqlalchemy import create_engine

engine = create_engine(os.getenv("DB_URL"))
batch_id = str(uuid.uuid4())

pytrends = TrendReq(hl='pl-PL', tz=360)

keywords_df = pd.read_csv("config/keywords.csv", sep=";")

for _, row in keywords_df.iterrows():

    keyword = row["keyword"]
    product_id = row["product_id"]

    try:

        pytrends.build_payload(
            [keyword, "Weather"],
            timeframe='today 3-m',
            geo='PL'
        )

        df = pytrends.interest_over_time()

        if not df.empty:

            df = df.reset_index()

            df.rename(columns={
                keyword: "raw_trends_index",
                "Weather": "anchor_keyword_index"
            }, inplace=True)

            df["keyword"] = keyword
            df["product_id"] = product_id
            df["is_anchor_keyword"] = False
            df["snapshot_timestamp"] = datetime.now()
            df["batch_id"] = batch_id

            df.to_sql(
                "stg_google_trends_raw",
                engine,
                if_exists="append",
                index=False
            )

            print(f"Loaded trends: {keyword}")

        time.sleep(15)

    except Exception as e:
        print(f"Error: {e}")