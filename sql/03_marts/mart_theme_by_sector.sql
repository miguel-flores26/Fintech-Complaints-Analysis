-- Mart: complaint themes and outcomes by sector and year.
CREATE OR REPLACE TABLE `cfpb.mart_theme_by_sector` AS
WITH base AS (
  SELECT
    sector_main AS sector,
    year_received,
    is_partial_year,
    theme,
    COUNT(*)                         AS n_complaints,
    COUNTIF(is_closed)               AS n_closed,
    COUNTIF(is_relief)               AS n_relief,
    COUNTIF(is_timely)               AS n_timely
  FROM `cfpb.int_complaints_enriched`
  WHERE sector_main != 'other'
  GROUP BY 1, 2, 3, 4
)
SELECT
  *,
  ROUND(n_complaints / SUM(n_complaints) OVER (PARTITION BY sector, year_received), 4)
                                           AS share_of_sector_year,
  ROUND(SAFE_DIVIDE(n_relief, n_closed), 4) AS relief_rate,
  ROUND(n_timely / n_complaints, 4)         AS timely_rate
FROM base;