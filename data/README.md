# Data

Data files are not included in this repository. To reproduce the analysis:

1. Go to [Inside Airbnb – Get the Data](https://insideairbnb.com/get-the-data/).
2. Download the detailed `listings.csv.gz` file for each city and save it in `data/raw/` as:
   - `barcelona-listings.csv.gz` (snapshot: 18 September 2026)
   - `berlin-listings.csv.gz` (snapshot: 20 September 2026)
   - `amsterdam-listings.csv.gz` (snapshot: 17 September 2026)
3. Run `notebooks/01_cleaning.ipynb`. It creates `data/clean/listings_clean.csv` and loads it into PostgreSQL.
