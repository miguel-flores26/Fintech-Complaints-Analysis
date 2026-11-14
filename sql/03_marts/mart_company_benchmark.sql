-- Mart: company-level outcomes vs. sector peers, full years 2021-2025.
CREATE OR REPLACE TABLE `cfpb.mart_company_benchmark` AS
WITH company_stats AS (
  SELECT
    company_group,
    company_type,
    sector_main AS sector,
    product_group,
    COUNT(*)            AS n_complaints,
    COUNTIF(is_closed)  AS n_closed,
    COUNTIF(is_relief)  AS n_relief,
    COUNTIF(theme = 'fraud_unauthorized') AS n_fraud,
    COUNTIF(is_timely)  AS n_timely
  FROM `cfpb.int_complaints_enriched`
  WHERE NOT is_partial_year
    AND sector_main != 'other'
  GROUP BY 1, 2, 3, 4
)
SELECT
  *,
  ROUND(SAFE_DIVIDE(n_relief, n_closed), 3) AS relief_rate,
  ROUND(n_fraud / n_complaints, 3)          AS fraud_share,
  ROUND(n_timely / n_complaints, 3)         AS timely_rate,
  -- share of the sector's complaints in this product that this company accounts for
  ROUND(n_complaints / SUM(n_complaints) OVER (PARTITION BY sector, product_group), 3)
                                            AS share_of_sector_product,
  -- sector-product average relief rate, for comparison
  ROUND(SAFE_DIVIDE(SUM(n_relief) OVER (PARTITION BY sector, product_group),
                    SUM(n_closed) OVER (PARTITION BY sector, product_group)), 3)
                                            AS sector_product_relief_rate,
  RANK() OVER (PARTITION BY sector, product_group ORDER BY n_complaints DESC)
                                            AS volume_rank
FROM company_stats;