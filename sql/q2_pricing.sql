-- ============================================================
-- Q2. PRICING
-- What nightly prices do listings charge by city, room type,
-- size and neighbourhood?
--
-- All queries use listings with a price and exclude outliers
-- (above the 99th percentile of each city). Medians are used
-- because prices are strongly right-skewed.
-- ============================================================

-- ------------------------------------------------------------
-- 2.1 Median nightly price by city
-- Median and mean price per night for listings with a price,
-- excluding outliers. The mean is shown to illustrate the gap
-- with the median caused by right-skewed prices.

SELECT 
	city,
	COUNT(*) AS listings_with_price,
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::numeric, 1) AS median_price,
	ROUND(AVG(price)::numeric,1) AS avg_price
FROM listings
WHERE price IS NOT NULL AND NOT is_price_outlier
GROUP BY city
ORDER BY median_price DESC;

-- Result: Amsterdam is the most expensive market (median 284€ per night),
-- 1.5x Barcelona (190€) and 2.2x Berlin (128€). Means exceed medians in all
-- cities by 29-42€, confirming right-skewed prices even after removing outliers.
-- Caution: 43% of Amsterdam listings have no price.

-- ------------------------------------------------------------
-- 2.2 Median nightly price by city and room type
-- Compares the same type of listing across cities, to separate
-- real price differences from differences in supply mix.

SELECT 
	city,
	room_type,
	COUNT(*) AS listings_with_price,
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::numeric, 1) AS median_price,
	ROUND(AVG(price)::numeric,1) AS avg_price
FROM listings
WHERE price IS NOT NULL AND NOT is_price_outlier
   AND room_type IN ('Entire home/apt', 'Private room')
GROUP BY city, room_type
ORDER BY room_type, median_price DESC;

-- Result: Price gaps hold within the same room type, so they are not explained
-- by supply mix. Median entire home: 329€ Amsterdam, 220€ Barcelona, 154€
-- Berlin. Median private room: 176€ Amsterdam, more than twice Berlin (85€)
-- and Barcelona (73€). In Barcelona, the mean private room price (120€) is far
-- above the median, suggesting a mix of very cheap and expensive rooms.

-- ------------------------------------------------------------
-- 2.3 Median nightly price of entire homes by number of bedrooms
-- Like-for-like comparison of similar-sized properties across cities.

SELECT 
	city,
	CASE
		WHEN bedrooms = 0 THEN '0 (studio)'
		WHEN bedrooms = 1 THEN '1'
		WHEN bedrooms = 2 THEN '2'
		WHEN bedrooms = 3 THEN '3'
		ELSE '4+'
	END AS bedroom_group,
	COUNT(*) AS listings_with_price,
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::numeric, 1) AS median_price,
	ROUND(AVG(price)::numeric,1) AS avg_price
FROM listings
WHERE price IS NOT NULL AND NOT is_price_outlier
	AND room_type = 'Entire home/apt' AND bedrooms IS NOT NULL
GROUP BY city,bedroom_group
ORDER BY bedroom_group, median_price DESC;

-- Result: Amsterdam is the most expensive for every size (1-bedroom: 280€ vs
-- 163€ Barcelona, 132€ Berlin), so its price premium is robust. Barcelona and
-- Berlin differ mainly in small units (studios +44%, 1-bedroom +24%), while
-- 2-3 bedroom homes are priced almost equally. Barcelona's supply skews
-- towards larger homes, which partly inflates its overall entire-home median.
-- Note: Amsterdam studios (72) and 4+ bedroom groups (<200) are less reliable.

-- ------------------------------------------------------------
-- 2.4 Top 5 most expensive neighbourhoods in each city (entire homes)
-- Neighbourhoods with the highest median price (minimum number
-- of listings required to avoid unreliable medians).

WITH neighbourhood_rank AS(
SELECT city,
	neighbourhood_cleansed,
	COUNT(*) AS listings_with_price,
	RANK() OVER (PARTITION BY city 
					ORDER BY PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price) DESC) AS rank_in_city,
	ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::numeric, 1) AS median_price,
	ROUND(AVG(price)::numeric,1) AS avg_price
FROM listings
WHERE price IS NOT NULL AND NOT is_price_outlier
	AND room_type = 'Entire home/apt'
GROUP BY city, neighbourhood_cleansed
	HAVING COUNT(*) >= 30	
)

SELECT city,
	neighbourhood_cleansed,
	listings_with_price,
	rank_in_city,
	median_price,
	avg_price
FROM neighbourhood_rank
WHERE rank_in_city <= 5
ORDER BY city, rank_in_city;

-- Result (entire homes, neighbourhoods with 30+ listings): Amsterdam's most
-- expensive areas are its central ones (354-393€). Barcelona's top prices are
-- on the seafront (Diagonal Mar, Vila Olimpica: ~290-311€), not the old town.
-- Berlin's priciest areas are in Mitte and Prenzlauer Berg (~183-203€); even
-- the top one is below Barcelona's median entire-home price (220€).