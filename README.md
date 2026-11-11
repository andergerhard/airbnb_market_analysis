# Airbnb Market Analysis: Barcelona vs Berlin vs Amsterdam

## Context
Short-term rentals have become a significant part of the accommodation supply in major European cities, competing directly with hotels for the same travellers. However, the size, pricing, professionalisation and regulation of this market vary widely from city to city.

This project analyses Airbnb listings in **Barcelona, Berlin and Amsterdam** from the perspective of a **hospitality company** seeking to understand the short-term rental market in each city: how large and competitive it is, what prices and performance listings achieve, how professionalised the supply is, and how regulation shapes it.

## Business Questions
1. **Supply size:** How many listings does each city have, and what share are entire homes (the listing type most likely to substitute a hotel stay)?
2. **Pricing:** What nightly prices do listings charge by city, room type, size and neighbourhood?
3. **Performance:** What occupancy and revenue do listings achieve, and where?
4. **Professionalisation:** What share of the supply is run by professional operators (10+ listings), and do they outperform individual hosts?
5. **Regulation:** What share of listings declares a license in each city, and where is the short-term rental supply most controlled?

## Data
- Source: Inside Airbnb (insideairbnb.com)
- Snapshots: Barcelona (18 Sep 2026), Berlin (20 Sep 2026), Amsterdam (17 Sep 2026)

## Data Cleaning Decisions

All cleaning steps were first explored on Barcelona and then grouped into a single function (`clean_listings()`) applied to the three cities, so the same rules are used everywhere. No listings were removed during cleaning: the final dataset contains 38,224 listings (Barcelona 15,236 · Berlin 12,376 · Amsterdam 10,612).

**Data quality checks**
- No duplicate listings were found.
- Missing values follow clear patterns: missing reviews correspond exactly to listings with 0 reviews, and missing revenue corresponds exactly to listings without price. Missing values are therefore kept, as they reflect real situations rather than errors.
- `minimum_nights` is missing for 13.4% of Barcelona listings; the cause could not be identified, and the column is not central to the analysis.
- `neighbourhood_group_cleansed` is empty for Amsterdam, so district-level comparisons across the three cities are not possible.

**Column selection**
- From ~80 original columns, 21 were kept, covering location, property type, price, host, reviews and license.

**Price**
- Prices were stored as text (e.g. `"$1,234.00"`); the `$` and thousands separator were removed and the column converted to numeric. All three cities use EUR, despite the `$` symbol in the raw data.
- Some listings have no price: 17.2% in Barcelona, 34.1% in Berlin and 43.1% in Amsterdam. They are kept in the dataset but excluded from price and revenue analyses, since revenue estimates depend on price. These listings are mostly inactive, so price analyses mainly reflect the active market (see Limitations).
- Prices are strongly right-skewed (in Barcelona, mean 253€ vs median 191€), so the **median** is used instead of the mean.
- Listings above the **99th price percentile of each city** are flagged as outliers (`is_price_outlier`) and excluded from price analyses. The most expensive listings had no reviews, and at least one showed a monthly price entered as nightly. A city-specific threshold is used because price levels differ between cities.

**Data types**
- `host_is_superhost` converted from `"t"`/`"f"` to boolean.
- `last_review` converted from text to date.

**Host type**
- Hosts are grouped by the number of listings they manage in the city (`calculated_host_listings_count`): **single** (1), **multi** (2–9) and **professional** (10+).

**License status**
The `license` field is free text written by hosts, with a different format in each city. It was grouped into four categories, applied in this order (each rule overrides the previous one):
1. `missing`: no license information
2. `exempt`: contains "Exempt"
3. `number_declared`: contains a digit (registration code)
4. `identity_info`: contains "Legal entity name" or "First name and Last name". In Berlin, many hosts publish company or personal details instead of a registration number. These texts contain digits (postcodes, street numbers), so without this rule they would have been wrongly counted as `number_declared`.

Limitations of this field:
- Registration numbers are **self-declared and not validated** against official registries. Some are clearly placeholders (e.g. `HUTB-123456` in 12 listings in Barcelona, `ABCD 1234 AB12 89EF A0F9` in 10 listings in Amsterdam), so `number_declared` is an **upper bound** of properly licensed listings.
- `identity_info` does not mean the listing is unlicensed, only that no registration number is shown.

**Personal data**
- The original `license` text was dropped from the clean dataset, as it contains host names and addresses. Raw license texts from Berlin are not displayed in the notebooks.

## Analysis & Key Findings


## Limitations

- **Single snapshot:** the data shows each market at one point in time, not trends.
- **Estimates:** occupancy and revenue are estimated by Inside Airbnb, not actual booking data.
- **No hotel data:** the analysis describes short-term rentals as a competitive context for hotels, but does not compare them directly.
- **Missing prices:** 43.1% of listings in Amsterdam, 34.1% in Berlin and 17.2% in Barcelona have no price or revenue estimate. These listings are mostly inactive, but 27.3% of active listings in Amsterdam have no price (13.2% in Berlin, 8.7% in Barcelona), so Amsterdam's price and revenue figures are the least representative.
- **Licenses:** registration numbers are self-declared and not validated; some are clearly placeholders.
- **Neighbourhoods:** cities use neighbourhood units of very different size (22 in Amsterdam, 68 in Barcelona, 137 in Berlin), so neighbourhood shares are only comparable within each city.
- **City size:** Berlin's lower density partly reflects its large residential outskirts.

## Tools

Python (pandas, seaborn), PostgreSQL, Power BI
