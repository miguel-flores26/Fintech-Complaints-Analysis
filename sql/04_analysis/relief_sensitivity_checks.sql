-- Sensitivity checks on relief rates (full years 2021-2025).
-- Purpose: test whether the fintech vs. bank relief gap is real or driven by
-- product mix or individual companies.

-- 1. Relief by product and sector (controls for product mix).
--    Finding: gap holds in checking (21.5% vs 9.4%); in money-transfer fraud
--    the rates are nearly identical (10.9% vs 10.6%).
SELECT
  product_group,
  sector_main AS sector,
  COUNT(*) AS n_complaints,
  ROUND(SAFE_DIVIDE(COUNTIF(is_relief), COUNTIF(is_closed)), 3) AS relief_rate,
  ROUND(SAFE_DIVIDE(COUNTIF(is_relief AND theme = 'fraud_unauthorized'),
                    COUNTIF(is_closed AND theme = 'fraud_unauthorized')), 3) AS fraud_relief_rate
FROM `cfpb.int_complaints_enriched`
WHERE NOT is_partial_year
  AND sector_main != 'other'
GROUP BY product_group, sector
ORDER BY product_group, sector;

-- 2. Response mix for selected large companies.
--    Finding: Block closed 55,614 of 55,637 complaints "with explanation"
--    (99.96%), suggesting a company-level reporting practice.
SELECT company_group, company_response, COUNT(*) AS n,
       ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY company_group), 3) AS share
FROM `cfpb.int_complaints_enriched`
WHERE NOT is_partial_year
  AND company_group IN ('Block, Inc.', 'PayPal', 'Chime',
                        'WELLS FARGO & COMPANY', 'BANK OF AMERICA, NATIONAL ASSOCIATION')
GROUP BY company_group, company_response
ORDER BY company_group, n DESC;

-- 3. Relief by product and sector, excluding Block.
--    Finding: money transfer reverses (fintech 19.7% vs bank 13.2%);
--    checking gap remains (11.8% vs 21.5%).
SELECT
  product_group,
  sector_main AS sector,
  COUNT(*) AS n_complaints,
  ROUND(SAFE_DIVIDE(COUNTIF(is_relief), COUNTIF(is_closed)), 3) AS relief_rate,
  ROUND(SAFE_DIVIDE(COUNTIF(is_relief AND theme = 'fraud_unauthorized'),
                    COUNTIF(is_closed AND theme = 'fraud_unauthorized')), 3) AS fraud_relief_rate
FROM `cfpb.int_complaints_enriched`
WHERE NOT is_partial_year
  AND sector_main != 'other'
  AND company_group != 'Block, Inc.'
GROUP BY product_group, sector
ORDER BY product_group, sector;