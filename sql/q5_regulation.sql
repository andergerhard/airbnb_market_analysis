-- ============================================================
-- Q5. REGULATION
-- What share of listings declares a license in each city, and
-- where is the short-term rental supply most controlled?
--
-- License status categories (see Data Cleaning Decisions):
-- number_declared, identity_info, exempt, missing.
-- Registration numbers are self-declared and not validated.
-- ============================================================

-- ------------------------------------------------------------
-- 5.1 License status by city
-- Share of listings in each license category, to compare how
-- controlled the short-term rental supply is in each city.

SELECT
	city,
	license_status,
	COUNT(*) AS listings,
	ROUND(
		100.0 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY city),1) AS pct_of_city
FROM listings
GROUP BY city, license_status
ORDER BY city,
	CASE license_status
		WHEN 'number_declared' THEN 1
		WHEN 'exempt' THEN 2
		WHEN 'identity_info' THEN 3
		WHEN 'missing' THEN 4
	END;

-- Result: Amsterdam has the highest share of declared registration numbers
-- (89.9%) and only 4.4% with no license information. In Barcelona, 59.6%
-- declare a number but 35.9% show no information. Berlin has the lowest share
-- of declared numbers (34.9%), with similar shares of identity details (31.9%)
-- and no information (32.6%). Exempt listings: 0.6-5.7%.

-- ------------------------------------------------------------
-- 5.2 License status by host type
-- Share of listings declaring a registration number, showing
-- identity details or with no license information, for each
-- host type in each city: who complies least?

SELECT
	city,
	host_type,
	COUNT(*) AS listings,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE license_status = 'number_declared')/ COUNT(*), 1
	) AS pct_number_declared,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE license_status = 'exempt')/ COUNT(*), 1
	) AS pct_exempt,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE license_status = 'identity_info')/ COUNT(*), 1
	) AS pct_identity_info,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE license_status = 'missing')/ COUNT(*), 1
	) AS pct_missing
FROM listings
GROUP BY city, host_type
ORDER BY city,
	CASE host_type
		WHEN 'single' THEN 1
		WHEN 'multi' THEN 2
		WHEN 'professional' THEN 3
	END;

-- Result: In Amsterdam, single hosts almost all declare a registration number
-- (97.9%), while 55.3% of professional listings declare themselves exempt.
-- In Barcelona, single hosts comply least (48.6% declare a number, 45.9% show
-- no information) vs ~62% / ~33-35% for multi and professional hosts. In
-- Berlin, professionals rarely show a number (3.7%) but mostly publish
-- company details (71.7% identity_info).

-- ------------------------------------------------------------
-- 5.3 License status of active listings
-- License status of listings with at least one review in the
-- last 12 months, to measure how much of the supply actually
-- competing with hotels lacks license information.

SELECT
	city,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE license_status = 'number_declared')/ COUNT(*), 1
	) AS pct_number_declared_all,
	ROUND(100.0 * 
		COUNT(*) FILTER (WHERE license_status = 'number_declared' AND number_of_reviews_ltm > 0)
		/ COUNT(*) FILTER (WHERE number_of_reviews_ltm > 0), 1) AS pct_number_declared_active,
	ROUND(
		100.0 * COUNT(*) FILTER (WHERE license_status = 'missing')/ COUNT(*), 1
	) AS pct_missing_all,
	ROUND(100.0 * 
		COUNT(*) FILTER (WHERE license_status = 'missing' AND number_of_reviews_ltm > 0)
		/ COUNT(*) FILTER (WHERE number_of_reviews_ltm > 0), 1) AS pct_missing_active
FROM listings
GROUP BY city
ORDER BY pct_missing_active DESC;

-- Result: In Berlin, most unlicensed listings are inactive: the share with no
-- license information drops from 32.6% of all listings to 7.9% of active ones.
-- In Barcelona, the gap persists: 29.7% of active listings show no license
-- information (vs 35.9% overall), the largest gap among listings competing
-- with hotels. Amsterdam is stable (~89% declared, ~5% missing).