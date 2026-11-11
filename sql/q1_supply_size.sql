-- ============================================================
-- Q1. Supply size
-- How many listings does each city have, and what share are
-- entire homes (the listing type most likely to substitute
-- a hotel stay)?

-- Requires: sql/00_city_population.sql
-- ============================================================

-- ------------------------------------------------------------
-- 1.1 Supply size and density by city
-- Total listings, share of entire homes, and listings per
-- 1000 residents (to compare cities of different sizes).

SELECT 
	city, 
	COUNT(*) AS total_listings,
	COUNT(*) FILTER (WHERE room_type = 'Entire home/apt') AS entire_home,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE room_type = 'Entire home/apt') / COUNT(*), 1
		) AS pct_entire_home,
	ROUND(1000.0 * COUNT(*) / population,1) AS listings_per_1000_residents,
	ROUND(
		1000.0 * COUNT(*) FILTER (WHERE room_type = 'Entire home/apt') / population, 1
		) AS entire_homes_per_1000_residents
FROM listings 
JOIN city_population USING (city)
GROUP BY city, population
ORDER BY total_listings DESC;

-- Result: Barcelona has the largest absolute supply, but Amsterdam has the
-- highest density: 11.3 listings and 9.1 entire homes per 1,000 residents,
-- versus 8.8 / 6.1 in Barcelona and only 3.2 / 2.2 in Berlin.
-- Amsterdam also has the highest share of entire homes (80.8%).
-- Note: Berlin's lower density partly reflects its size, as the city
-- includes large residential outskirts with little tourist activity.

-- ------------------------------------------------------------
-- 1.2 Room type mix by city
-- Share of each room type (entire home, private room, shared
-- room, hotel room) within each city.

SELECT
	city,
	room_type,
	COUNT(*) AS listings,
	ROUND(
		100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY city),1) AS pct_of_city
FROM listings
GROUP BY city,room_type
ORDER BY city, listings DESC;

-- Result: Entire homes and private rooms make up over 98% of supply in all
-- three cities. Hotel rooms are marginal (≤0.5%), so competition for hotels
-- comes almost entirely from residential properties. Amsterdam is the most
-- focused on entire homes (80.8%, with only 18.7% private rooms), while
-- Barcelona and Berlin show a very similar mix (~69% / ~30%).

-- ------------------------------------------------------------
-- 1.3 Top 5 neighbourhoods by number of listings in each city
-- Where the supply is geographically concentrated.

WITH neighbourhood_ranking AS(
SELECT
	city,
	neighbourhood_cleansed,
	COUNT(*) AS listings,
	RANK() OVER (PARTITION BY city ORDER BY COUNT(*) DESC) AS rank_in_city,
	ROUND(
		100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY city),1) AS pct_of_city
FROM listings
GROUP BY city, neighbourhood_cleansed
)

SELECT
	city,
	neighbourhood_cleansed,
	listings,
	rank_in_city,
	pct_of_city
FROM neighbourhood_ranking
WHERE rank_in_city <= 5
ORDER BY city, rank_in_city;

-- Check: number of neighbourhoods per city (to explain Berlin's top 5 low %).
-- Neighbourhood sizes differ between cities, which affects how
-- shares can be compared.

SELECT city, COUNT(DISTINCT neighbourhood_cleansed) AS n_neighbourhoods
FROM listings
GROUP BY city;

-- Result: Supply concentrates in central or near-central areas in all three
-- cities: la Dreta de l'Eixample alone holds 14.3% of Barcelona's listings,
-- Alexanderplatz leads in Berlin (6.9%), and in Amsterdam the top area is
-- De Baarsjes - Oud-West (17.3%), next to the historic centre.
-- Note: cities use neighbourhood units of very different size (22 areas in
-- Amsterdam, 68 in Barcelona, 137 in Berlin), so neighbourhood shares are
-- only comparable within each city, not between cities.