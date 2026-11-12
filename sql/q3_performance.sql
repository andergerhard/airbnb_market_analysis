-- ============================================================
-- Q3. PERFORMANCE
-- What occupancy and revenue do listings achieve, and where?
--
-- Occupancy and revenue are estimates by Inside Airbnb based on
-- reviews, not actual booking data. Revenue requires a price,
-- so revenue queries only use listings with a price.
-- ============================================================

-- ------------------------------------------------------------
-- 3.1 Occupancy by city
-- Share of listings with zero estimated occupancy (idle supply),
-- and median nights occupied per year for active listings.

SELECT
	city,
	COUNT(*) AS total_listings,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE estimated_occupancy_l365d = 0) / COUNT(*), 1
	) AS pct_zero_occupancy,
	ROUND(
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_occupancy_l365d)
			FILTER (WHERE estimated_occupancy_l365d > 0)::numeric, 1) AS median_nights_active,
	ROUND(
		100.0 / 365 * (PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_occupancy_l365d)
			FILTER (WHERE estimated_occupancy_l365d > 0))::numeric, 1
	) AS median_occupancy_rate_active
FROM listings
GROUP BY city
ORDER BY median_occupancy_rate_active DESC;

-- Result: Active listings in Amsterdam are occupied a median of only 39 nights
-- per year (10.7%), versus 150 in Barcelona (41.1%) and 176 in Berlin (48.2%),
-- consistent with Amsterdam's 30-night cap on entire-home rentals.
-- Berlin has the highest share of idle listings (43.9% with zero occupancy),
-- but its active listings are the most occupied.

-- ------------------------------------------------------------
-- 3.2 Occupancy and revenue by city and room type
-- Median nights occupied and median annual revenue of active
-- listings (with a revenue estimate), for entire homes and
-- private rooms.

SELECT
	city,
	room_type,
	COUNT(*) AS active_listings,
	ROUND(
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_occupancy_l365d)::numeric, 0
	) AS median_nights_occupied,
	ROUND(
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_revenue_l365d)::numeric, 0
	) AS median_annual_revenue
FROM listings
WHERE estimated_occupancy_l365d > 0 
	AND estimated_revenue_l365d IS NOT NULL
	AND NOT is_price_outlier
	AND room_type IN ('Entire home/apt', 'Private room')
GROUP BY city, room_type
ORDER BY room_type, median_annual_revenue DESC;

-- Result: Amsterdam's entire homes are occupied only 31 nights per year
-- (30-night cap) and earn the lowest revenue (11,821€), while its private
-- rooms reach 242 nights and 29,770€. Barcelona's entire homes earn the most
-- (34,710€, 168 nights); Berlin's are the most occupied (189 nights) but
-- earn less (27,540€) due to lower prices.

-- ------------------------------------------------------------
-- 3.3 Occupancy by price level
-- Do more expensive listings get fewer bookings? Active entire
-- homes are split into four price groups (quartiles) within
-- each city, and their median occupancy is compared.

WITH price_quartiles AS(
SELECT city,
	price,
	estimated_occupancy_l365d,
	NTILE(4) OVER (PARTITION BY city ORDER BY price) AS price_quartile
FROM listings
WHERE estimated_occupancy_l365d > 0 
	AND price IS NOT NULL AND NOT is_price_outlier
	AND room_type = 'Entire home/apt'
)

SELECT 
	city,
	price_quartile,
	COUNT(*) AS listings,
	MIN(price) AS min_price,
	MAX(price) AS max_price,
	ROUND(
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_occupancy_l365d)::numeric, 0
	) AS median_nights
FROM price_quartiles
GROUP BY city, price_quartile
ORDER BY city, price_quartile;

-- Result (active entire homes, by price quartile within each city):
-- In Amsterdam, quartiles 2-4 are all occupied 31 nights regardless of price
-- (250-1,170€): the 30-night cap dominates over price. In Barcelona and
-- Berlin, occupancy peaks in the second quartile (162-231€: 198 nights;
-- 125-173€: 227 nights) and declines for higher prices.
