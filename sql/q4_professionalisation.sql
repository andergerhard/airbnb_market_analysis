-- ============================================================
-- Q4. PROFESSIONALISATION
-- What share of the supply is run by professional operators
-- (10+ listings), and do they outperform individual hosts?
--
-- Host types (based on listings per host in each city):
-- single (1), multi (2-9), professional (10+).
-- ============================================================

-- ------------------------------------------------------------
-- 4.1 Share of hosts and listings by host type
-- Percentage of hosts and percentage of listings for each host
-- type in each city, to measure how concentrated the supply is.

SELECT
	city,
	host_type,
	COUNT(DISTINCT host_id) AS hosts,
	ROUND(
		100.0 * COUNT(DISTINCT host_id) 
			/ SUM(COUNT(DISTINCT host_id)) OVER (PARTITION BY city),1
	) AS pct_hosts,
	COUNT(*) AS listings,
	ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY city), 1) AS pct_listings
FROM listings
GROUP BY city, host_type
ORDER BY city,
	CASE host_type
		WHEN 'single' THEN 1
		WHEN 'multi' THEN 2
		WHEN 'professional' THEN 3
	END;

-- Result: Barcelona is highly professionalised: 5.3% of hosts (professionals)
-- control 48.9% of listings, while single hosts (64.8% of hosts) hold only
-- 19.5%. Amsterdam is a market of individual hosts (93.5% of hosts, 81.3% of
-- listings), with professionals holding just 3.0%. Berlin sits in between:
-- single hosts provide 53.6% of listings and professionals 15.7%.

-- ------------------------------------------------------------
-- 4.2 Performance by host type
-- Median price, nights occupied, annual revenue and review score
-- of active entire homes (with price, excluding outliers), to
-- compare professional operators with individual hosts.

SELECT 
	city,
	host_type,
	COUNT(*) AS active_listings,
	ROUND(
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY price)::numeric, 0
	) AS median_price,
	ROUND(
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_occupancy_l365d)::numeric, 0
	) AS median_nights,
	ROUND(
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY estimated_revenue_l365d)::numeric, 0
	) AS median_revenue,
	ROUND(
		PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY review_scores_rating)::numeric, 2
	) AS median_rating,
	ROUND(AVG(review_scores_rating)::numeric,2) AS avg_rating
FROM listings
WHERE estimated_occupancy_l365d > 0 
	AND price IS NOT NULL AND NOT is_price_outlier
	AND room_type = 'Entire home/apt'
GROUP BY city, host_type
ORDER BY city,
	CASE host_type
		WHEN 'single' THEN 1
		WHEN 'multi' THEN 2
		WHEN 'professional' THEN 3
	END;
	
-- Result (active entire homes): review scores decrease with host size in all
-- cities (single 4.82-4.96 vs professional 4.64-4.73). Professionals do not
-- outperform in Barcelona (lower occupancy and revenue than other hosts), but
-- earn more in Berlin (~45% above single hosts). In Amsterdam, single hosts
-- stay at the 30-night cap (31 nights), while professionals reach 191 nights
-- and 41,193€ (only 62 listings, less reliable).

-- ------------------------------------------------------------
-- 4.3 Top 5 largest operators in each city
-- Hosts with the most listings in each city and the share of
-- the city's supply they control.

WITH host_ranking AS(
SELECT city,
	host_id,
	COUNT(*) AS listings,
	ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY city),2) AS pct_of_city,
	RANK() OVER (PARTITION BY city ORDER BY COUNT(*) DESC) as rank_in_city
FROM listings
GROUP BY city, host_id
)

SELECT
	city,
	rank_in_city,
	host_id,
	listings,
	pct_of_city,
	SUM(pct_of_city) OVER (PARTITION BY city ORDER BY rank_in_city) AS cumulative_pct
FROM host_ranking
WHERE rank_in_city <= 5
ORDER BY city, rank_in_city;

-- Result: In Barcelona, the 5 largest operators control 12.6% of all listings
-- (about 1 in 8); the largest alone manages 579 listings and the top 2 each
-- have more than 500. In Berlin, the top 5 hold 4.3% (largest: 199 listings).
-- In Amsterdam, they hold less than 1% (largest: only 24 listings).