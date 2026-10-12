"""Download the public Olist e-commerce dataset from Olist's official GitHub repository.

Source: https://github.com/olist/work-at-olist-data (licence: CC BY-NC-SA 4.0).
The geolocation file is not used in this project and is skipped.
"""
from pathlib import Path
from urllib.request import urlretrieve

BASE = "https://raw.githubusercontent.com/olist/work-at-olist-data/master/datasets/"
FILES = [
    "olist_customers_dataset.csv",
    "olist_order_items_dataset.csv",
    "olist_order_payments_dataset.csv",
    "olist_order_reviews_dataset.csv",
    "olist_orders_dataset.csv",
    "olist_products_dataset.csv",
    "olist_sellers_dataset.csv",
    "product_category_name_translation.csv",
]
RAW = Path(__file__).resolve().parents[1] / "data" / "raw"


def main(force=False):
    RAW.mkdir(parents=True, exist_ok=True)
    for name in FILES:
        target = RAW / name
        if target.exists() and not force:
            print(f"exists   {name}")
            continue
        print(f"download {name}")
        urlretrieve(BASE + name, target)
        assert target.stat().st_size > 0, f"empty download: {name}"


if __name__ == "__main__":
    main()
