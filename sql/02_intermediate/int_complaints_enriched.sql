-- Intermediate: in-scope complaints with theme + company classification.
CREATE OR REPLACE TABLE `cfpb.int_complaints_enriched` AS
SELECT
  s.*,
  COALESCE(c.parent_group, s.company)        AS company_group,
  COALESCE(c.company_type, 'unclassified')   AS company_type,
  c.fintech_segment,
  c.confidence                               AS classification_confidence,
  -- Main comparison: fintechs vs. banks and credit unions
  CASE
    WHEN c.company_type = 'fintech' THEN 'fintech'
    WHEN c.company_type IN ('bank', 'digital_bank', 'credit_union') THEN 'bank_or_cu'
    ELSE 'other'
  END AS sector_main,
  -- Sensitivity check: count digital banks (e.g. SoFi, Ally) as fintech
  CASE
    WHEN c.company_type IN ('fintech', 'digital_bank') THEN 'fintech'
    WHEN c.company_type IN ('bank', 'credit_union') THEN 'bank_or_cu'
    ELSE 'other'
  END AS sector_alt
FROM `cfpb.stg_complaints` AS s
LEFT JOIN `cfpb.company_classification` AS c
  ON c.company = s.company
WHERE s.theme NOT IN ('out_of_scope_credit_reporting', 'unknown');