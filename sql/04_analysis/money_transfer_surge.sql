-- Analysis: what drove the 2025 jump in money-transfer complaints?
-- (16,751 in 2024 -> 84,619 in 2025)

-- 1. Which companies account for the increase?
--    Finding: Block (+40,643, 60% of increase) and Early Warning Services /
--    Zelle (+19,220, 28%) together account for ~88%.
WITH by_company AS (
  SELECT
    company_group,
    company_type,
    COUNTIF(year_received = 2023) AS n_2023,
    COUNTIF(year_received = 2024) AS n_2024,
    COUNTIF(year_received = 2025) AS n_2025
  FROM `cfpb.int_complaints_enriched`
  WHERE product_group = 'money_transfer'
  GROUP BY company_group, company_type
)
SELECT
  *,
  n_2025 - n_2024 AS change_2024_to_2025,
  ROUND((n_2025 - n_2024) / SUM(n_2025 - n_2024) OVER (), 3) AS share_of_total_increase
FROM by_company
ORDER BY change_2024_to_2025 DESC
LIMIT 10;

-- 2. Which issues account for the increase?
--    Finding: "Other transaction problem" (generic catch-all) rose
--    3,007 -> 53,893, about 75% of the increase.
SELECT
  issue,
  COUNTIF(year_received = 2024) AS n_2024,
  COUNTIF(year_received = 2025) AS n_2025,
  COUNTIF(year_received = 2025) - COUNTIF(year_received = 2024) AS change
FROM `cfpb.int_complaints_enriched`
WHERE product_group = 'money_transfer'
GROUP BY issue
ORDER BY change DESC;

-- 3. Is the catch-all growth concentrated in Block and Zelle?
--    Finding: Block 160 -> 32,562 and EWS 52 -> 16,407 "Other transaction
--    problem" complaints.
SELECT
  CASE WHEN company_group IN ('Block, Inc.', 'Early Warning Services, LLC')
       THEN company_group ELSE 'All others' END AS company,
  issue = 'Other transaction problem' AS is_other_transaction_problem,
  COUNTIF(year_received = 2024) AS n_2024,
  COUNTIF(year_received = 2025) AS n_2025
FROM `cfpb.int_complaints_enriched`
WHERE product_group = 'money_transfer'
GROUP BY 1, 2
ORDER BY 1, 2;

-- 4. Monthly timing.
--    Finding: the jump is concentrated in January 2025 (Block 30,466;
--    EWS 16,521) versus ~150-200 and ~30-80 in typical 2024 months.
SELECT
  month_received,
  COUNTIF(company_group = 'Block, Inc.')                 AS block,
  COUNTIF(company_group = 'Early Warning Services, LLC') AS zelle_ews,
  COUNTIF(company_group NOT IN ('Block, Inc.', 'Early Warning Services, LLC')) AS all_others
FROM `cfpb.int_complaints_enriched`
WHERE product_group = 'money_transfer'
  AND month_received BETWEEN '2024-07-01' AND '2025-12-01'
GROUP BY month_received
ORDER BY month_received;

-- 5. Daily timing and submission channel around the spike.
--    Finding: Block's spike begins Jan 16, 2025 (the date of the CFPB order
--    against Block) and peaks Jan 17 at 12,638; EWS begins Jan 15. All via web.
--    Cause cannot be confirmed from structured data.
SELECT
  date_received,
  submitted_via,
  COUNTIF(company_group = 'Block, Inc.')                 AS block,
  COUNTIF(company_group = 'Early Warning Services, LLC') AS zelle_ews
FROM `cfpb.int_complaints_enriched`
WHERE product_group = 'money_transfer'
  AND date_received BETWEEN '2024-12-15' AND '2025-02-15'
  AND company_group IN ('Block, Inc.', 'Early Warning Services, LLC')
GROUP BY 1, 2
HAVING block + zelle_ews >= 100
ORDER BY 1, 2;