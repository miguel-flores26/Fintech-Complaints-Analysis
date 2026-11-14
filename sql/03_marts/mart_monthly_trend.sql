-- Mart: monthly complaint counts for trend charts, 2021 to Sept 2026.
-- Includes the "other" sector so Early Warning Services (Zelle) appears.
-- Stops at Sept 2026 because Oct 2026 was incomplete at download (Oct 14, 2026).
CREATE OR REPLACE TABLE `cfpb.mart_monthly_trend` AS
SELECT
  month_received,
  product_group,
  sector_main AS sector,
  CASE
    WHEN company_group IN ('Block, Inc.', 'Early Warning Services, LLC', 'PayPal', 'Chime')
      THEN company_group
    ELSE 'All other companies'
  END AS company_highlight,
  theme,
  COUNT(*)           AS n_complaints,
  COUNTIF(is_closed) AS n_closed,
  COUNTIF(is_relief) AS n_relief
FROM `cfpb.int_complaints_enriched`
WHERE month_received <= '2026-09-01'
GROUP BY 1, 2, 3, 4, 5;