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

### 1. Supply size

**1.1 Supply size and density**

Barcelona has the largest absolute supply, but **Amsterdam has the highest density** of short-term rentals relative to its population:

- **Amsterdam:** 11.3 listings and 9.1 entire homes per 1,000 residents
- **Barcelona:** 8.8 listings and 6.1 entire homes per 1,000 residents
- **Berlin:** 3.2 listings and 2.2 entire homes per 1,000 residents

Amsterdam also has the highest share of entire homes (**80.8%**), the listing type most likely to substitute a hotel stay.

*Note: Berlin's lower density partly reflects its size, as the city includes large residential outskirts with little tourist activity.*

**1.2 Room type mix**

Entire homes and private rooms make up **over 98% of supply** in all three cities. Hotel rooms are marginal (**≤0.5%**), so competition for hotels comes almost entirely from **residential properties**, not from other hotels listing on Airbnb.

- **Amsterdam** is the most focused on entire homes: **80.8%** entire homes and only **18.7%** private rooms.
- **Barcelona** and **Berlin** show a very similar mix: around **69% entire homes** and **30% private rooms**.

**1.3 Geographic concentration**

In all three cities, supply concentrates in **central or near-central areas**:

- **Barcelona:** la Dreta de l'Eixample alone holds **14.3%** of the city's listings, followed by el Raval, Gràcia, Sagrada Família and the Barri Gòtic.
- **Berlin:** Alexanderplatz leads with **6.9%**, with supply more evenly spread across the city.
- **Amsterdam:** the top area is De Baarsjes - Oud-West (**17.3%**), next to the historic centre; Centrum-West and Centrum-Oost together add another 20.7%.

*Note: cities use neighbourhood units of very different size (22 areas in Amsterdam, 68 in Barcelona, 137 in Berlin), so neighbourhood shares are only comparable within each city, not between cities. The maps in the Python analysis provide a fairer comparison of geographic concentration.*

### 2. Pricing

**2.1 Median price by city**

**Amsterdam is by far the most expensive market**, with a median price of **284€ per night**:

- **1.5x** Barcelona (**190€**)
- **2.2x** Berlin (**128€**)

Means are higher than medians in all cities (by 29–42€), confirming that prices are **right-skewed** even after removing outliers. This is why medians are used throughout the analysis.

Amsterdam has a higher share of entire homes, which could partly explain its higher median; however, query 2.2 shows that the price gap holds when comparing the same room type.

*Caution: 43% of Amsterdam listings have no price, so its price figures are the least representative of the three cities.*

**2.2 Median price by room type**

Price differences **hold when comparing the same room type**, so they are not explained by differences in supply mix.

| City | Entire home | Private room |
|---|---|---|
| Amsterdam | **329€** | **176€** |
| Barcelona | 220€ | 73€ |
| Berlin | 154€ | 85€ |

- A median entire home in Amsterdam costs **1.5x** Barcelona and **2.1x** Berlin.
- **Private rooms in Amsterdam cost more than twice as much** as in Berlin or Barcelona, at a price close to a hotel room.
- In Barcelona, the mean price of private rooms (**120€**) is far above the median (73€), suggesting a mix of very cheap rooms and a smaller group of expensive ones.

**2.3 Price by property size (entire homes)**

**Amsterdam is the most expensive market for every property size**, so its price premium is robust and not driven by differences in the type or size of listings. For 1-bedroom homes (the most comparable to a hotel room):

- **Amsterdam:** 280€
- **Barcelona:** 163€
- **Berlin:** 132€

**Barcelona and Berlin differ mainly in small units:**

| Size | Barcelona | Berlin | Difference |
|---|---|---|---|
| Studio | 165€ | 115€ | +44% |
| 1 bedroom | 163€ | 132€ | +24% |
| 2 bedrooms | 214€ | 206€ | +4% |
| 3 bedrooms | 262€ | 270€ | −3% |

Barcelona's supply also **skews towards larger homes** (2–3 bedrooms), while 1-bedroom homes dominate in Amsterdam and Berlin. This partly inflates Barcelona's overall median price for entire homes.

*Note: groups with fewer listings (Amsterdam studios: 72; 4+ bedrooms in Amsterdam and Berlin: fewer than 200) are less reliable.*

**2.4 Most expensive neighbourhoods (entire homes)**

*Neighbourhoods with more than 30 listings.*

- **Amsterdam:** the most expensive neighbourhoods are the **same central areas that concentrate most listings** (Centrum-West, De Pijp, Centrum-Oost…), with a narrow price range of **354–393€**: the whole centre is expensive.
- **Barcelona:** the highest prices are found **on the seafront** (Diagonal Mar and Vila Olímpica, **~290–311€**) rather than in the old town. La Dreta de l'Eixample is both the largest and the **2nd most expensive** neighbourhood.
- **Berlin:** the priciest areas are in **Mitte and Prenzlauer Berg** (**~183–203€**).

Even **Berlin's most expensive neighbourhood (203€) is below Barcelona's median entire-home price (220€)**, and far below Amsterdam's top 5 (all above 350€).

### 3. Performance

**3.1 Occupancy by city**

| City | Idle listings (zero occupancy) | Median nights occupied (active listings) | % of the year |
|---|---|---|---|
| Berlin | **43.9%** | **176** | **48.2%** |
| Barcelona | 34.8% | 150 | 41.1% |
| Amsterdam | 38.1% | **39** | **10.7%** |

**Amsterdam's listings are occupied far less than in the other cities.** This is consistent with Amsterdam's cap on holiday rentals of entire homes: **30 nights per year**, reduced to **15 nights in eight central areas since April 2026**. Combined with Q2, Amsterdam operates as a **low-occupancy, high-price market**.

**Berlin has a dual profile:** it has the highest share of idle listings (43.9%), but its active listings are the most occupied of the three cities.

*Note: occupancy is estimated by Inside Airbnb from reviews, not actual booking data.*

**3.2 Occupancy and revenue by room type**

*Active listings with a revenue estimate.*

| | City | Median nights | Median annual revenue |
|---|---|---|---|
| **Entire homes** | Barcelona | 168 | **34,710€** |
| | Berlin | **189** | 27,540€ |
| | Amsterdam | **31** | **11,821€** |
| **Private rooms** | Amsterdam | **242** | **29,770€** |
| | Berlin | 189 | 15,484€ |
| | Barcelona | 117 | 7,628€ |

- **Amsterdam:** entire homes are occupied a median of only **31 nights per year**, matching the **30-night cap** on holiday rentals of entire homes. Despite having the highest nightly prices, they generate the **lowest revenue** of the three cities. Private rooms, which are not subject to that cap, show the opposite pattern (**242 nights**, **29,770€**), likely operating as **B&B-style accommodation**.
- **Barcelona:** entire homes are the **strongest performers**, combining good occupancy (168 nights) with medium-high prices, and competing with hotels throughout the year.
- **Berlin:** a **high-occupancy, low-price market**. Its entire homes are the most occupied (189 nights) but earn less than in Barcelona due to lower prices; entire homes and private rooms show the same occupancy.

*Note: occupancy and revenue are estimated by Inside Airbnb, not actual booking data.*

**3.3 Occupancy by price level (entire homes)**

*Active entire homes, split into four price groups (quartiles) within each city.*

**In Amsterdam, price has almost no effect on occupancy:** quartiles 2 to 4 are all occupied a median of **31 nights**, whether listings cost 250€ or 1,170€ per night. The **30-night cap dominates over price**.

**In Barcelona and Berlin, the cheapest listings are not the most occupied.** Occupancy peaks in the second quartile and declines for higher prices:

| Quartile | Barcelona: price | Nights | Berlin: price | Nights |
|---|---|---|---|---|
| 1 (cheapest) | 19–162€ | 128 | 28–125€ | 184 |
| **2** | **162–231€** | **198** | **125–173€** | **227** |
| 3 | 231–307€ | 180 | 173–248€ | 176 |
| 4 (most expensive) | 307–1,798€ | 150 | 249–686€ | 176 |

The **strongest competition for hotels** therefore comes from **mid-priced entire homes**, the segment closest to mid-range hotels.

### 4. Professionalisation

**4.1 Market structure by host type**

The three cities show **very different market structures**:

| | Amsterdam | Barcelona | Berlin |
|---|---|---|---|
| Single hosts: % of hosts | 93.5% | 64.8% | 83.7% |
| Single hosts: % of listings | **81.3%** | 19.5% | 53.6% |
| Professionals: % of hosts | 0.3% | 5.3% | 1.1% |
| Professionals: % of listings | 3.0% | **48.9%** | 15.7% |

- **Barcelona is highly professionalised:** only **5.3% of hosts** (243 professionals) control **48.9% of listings**, while single-listing hosts, who represent 64.8% of all hosts, account for only 19.5% of supply.
- **Amsterdam is a market of individual hosts:** 93.5% of hosts have a single listing and provide 81.3% of supply, while professionals (only 24 hosts) hold just 3.0%. This is consistent with Amsterdam's rule that **hosts must live at the address they rent out**.
- **Berlin sits in between:** single hosts provide 53.6% of listings and professionals 15.7%.

Q4.
Ámsterdam es un mercado de particulares. El 93,5% de los anfitriones tiene un solo anuncio, y los profesionales apenas suman un 3% de la oferta. Encaja con su regulación: además del límite de noches, el anfitrión debe vivir y estar empadronado en la dirección. Es decir, la ley solo permite alquilar tu propia vivienda, lo que hace casi imposible gestionar muchos pisos. 
airroi
Barcelona es un mercado profesionalizado. Un 5,3% de anfitriones controla casi la mitad de los anuncios. Solo un 19,5% de la oferta es de particulares con un único piso.
Berlín está en medio: la mayoría de los anuncios son de particulares (53,6%), pero los profesionales tienen un peso relevante (15,7%).

**4.2 Performance by host type (entire homes)**

*Active entire homes, with price, excluding outliers.*

**Guests rate professional operators lower.** Review scores decrease consistently with host size in all three cities (medians and means show the same pattern):

| City | Single | Multi | Professional |
|---|---|---|---|
| Amsterdam | **4.96** | 4.84 | 4.73 |
| Barcelona | **4.82** | 4.78 | 4.64 |
| Berlin | **4.90** | 4.77 | 4.73 |

**Whether professionals perform better depends on the city:**

- **Barcelona:** professionals charge the highest prices (**241€**) but have lower occupancy (**150 nights**) and revenue (**33,132€**) than other hosts. Multi-listing hosts earn the most (**37,812€**).
- **Berlin:** multi and professional hosts are occupied around **235 nights** and earn **~45% more** than single hosts.
- **Amsterdam:** single hosts stay at the **30-night cap** (31 nights), while professionals reach **191 nights** and the highest revenue in the table (**41,193€**). This suggests they operate under other licences (e.g. hotel or B&B) or exceed the cap. *Based on only 62 listings, so less reliable.*

*Note: in Q3, Amsterdam's median occupancy was ~31 nights for all price levels because single hosts make up 87% of active entire homes. The higher occupancy of multi and professional hosts (13%) only becomes visible when segmenting by host type.*

**4.3 Largest operators**

The size of the largest operators **differs greatly between cities**:

| City | Largest operator | Top 5 operators combined |
|---|---|---|
| Barcelona | **579 listings** (3.8%) | **12.6%** of the city |
| Berlin | 199 listings (1.6%) | 4.3% |
| Amsterdam | 24 listings (0.2%) | 0.9% |

- **Barcelona:** the 5 largest operators control **about 1 in 8 listings**. The largest one alone manages 579 listings, more than all professional hosts in Amsterdam combined (322), and the top 2 each have more than 500.
- **Berlin:** there are some mid-sized operators but **no dominant player**.
- **Amsterdam:** the largest operator has **only 24 listings**, consistent with the requirement that hosts must live at the address they rent out.

Together with 4.1, this shows that **Barcelona's supply is not only professionalised but also concentrated in a few large operators**, whose business model is closer to that of an **aparthotel** than to home sharing.

### 5. Regulation

**5.1 License status by city**

| City | Number declared | Identity info | Exempt | Missing |
|---|---|---|---|---|
| Amsterdam | **89.9%** | 0% | 5.7% | **4.4%** |
| Barcelona | 59.6% | 0% | 4.5% | **35.9%** |
| Berlin | **34.9%** | 31.9% | 0.6% | 32.6% |

License declaration **varies widely between cities**:

- **Amsterdam** has the highest share of listings declaring a registration number and very few with no license information, consistent with its **strict registration and permit system**.
- **Barcelona:** 59.6% declare a number, but **more than a third** show no license information at all.
- **Berlin** has the lowest share of declared numbers: a similar share of listings show **identity details** (company or personal) instead, or no information.

Exempt listings are a small share everywhere (0.6–5.7%).

*Note: registration numbers are self-declared and not validated, and some are clearly fake (e.g. `HUTB-123456` in Barcelona). The real share of properly licensed listings is therefore **at most** these figures, and likely lower.*

**5.2 License status by host type**

License declaration by host type follows **a different pattern in each city**:

| City | Host type | Listings | Number declared | Exempt | Identity info | Missing |
|---|---|---|---|---|---|---|
| Amsterdam | Single | 8,627 | **97.9%** | 0.8% | 0% | 1.3% |
| | Multi | 1,663 | 61.2% | 21.6% | 0% | 17.3% |
| | Professional | 322 | 23.9% | **55.3%** | 0% | 20.8% |
| Barcelona | Single | 2,974 | **48.6%** | 5.5% | 0% | **45.9%** |
| | Multi | 4,810 | 62.1% | 3.0% | 0% | 34.9% |
| | Professional | 7,452 | 62.4% | 5.1% | 0% | 32.5% |
| Berlin | Single | 6,630 | 46.2% | 0.1% | 12.4% | 41.3% |
| | Multi | 3,809 | 31.1% | 1.0% | 45.5% | 22.4% |
| | Professional | 1,937 | **3.7%** | 1.5% | **71.7%** | 23.1% |

- **Amsterdam:** single hosts almost all declare a registration number, while **more than half of professional listings declare themselves exempt**. Combined with their high occupancy in 4.2 (191 nights, far above the 30-night cap), this suggests professionals operate under a **different regime** (e.g. hotel or B&B licences) rather than as holiday rentals.
- **Barcelona:** **single hosts comply least**, with nearly half showing no license information. Multi and professional hosts declare a number more often.
- **Berlin:** professionals rarely show a registration number but mostly **publish company details** instead, consistent with commercial operators. Single hosts are split between declared numbers and no information.

**5.3 License status of active listings**

*Active listings: at least one review in the last 12 months.*

| City | Number declared (all) | Number declared (active) | Missing (all) | Missing (active) |
|---|---|---|---|---|
| Amsterdam | 89.9% | 88.4% | 4.4% | 5.0% |
| Barcelona | 59.6% | 68.5% | 35.9% | **29.7%** |
| Berlin | 34.9% | 48.1% | 32.6% | **7.9%** |

**Separating active listings changes the picture:**

- **Berlin:** most listings without license information are **inactive**. The share with no information drops from 32.6% of all listings to **7.9%** of active ones, and declared numbers rise from 34.9% to 48.1%.
- **Barcelona:** the gap **persists in the active market**. Nearly **3 in 10 active listings** still show no license information, the **largest compliance gap among listings actually competing with hotels**.
- **Amsterdam** remains stable (around 89% declared numbers and 5% missing) for all and active listings.

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
