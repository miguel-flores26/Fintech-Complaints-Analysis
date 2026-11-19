# Fintech vs. Bank Complaints: What Customers Report and How Companies Respond

An SQL analysis of U.S. consumer complaints about checking/savings accounts, money transfers, and prepaid cards, comparing fintech companies with banks and credit unions. Built in **Google BigQuery** with layered SQL (staging → intermediate → marts), and visualized in **Tableau Public**.

**Dashboard:** [Tableau Public link](https://public.tableau.com/app/profile/miguel.flores2716/viz/FintechvsBankComplaints/Dashboard#2)

---

## Business Questions

1. **What do customers complain about?** Is the mix of problems different for fintechs than for banks and credit unions?
2. **How are complaints resolved?** Do fintechs and banks differ in how often complaints close with relief, and how much does that depend on individual companies?
3. **What drove the 2025 jump in money-transfer complaints?** (16,751 in 2024 → 84,619 in 2025)

## Key Findings (2021–2025 unless noted)

**1. Fintech and bank customers report a similar mix of problems, except fees.**
Transaction problems are the largest theme for both (51.4% of bank/credit-union complaints vs. 59.8% of fintech complaints). Account access/closure (17.4% vs. 17.0%) and fraud/unauthorized activity (16.6% vs. 16.1%) are nearly identical. Fees and overdraft are the exception: 11.0% of bank complaints vs. 2.3% of fintech complaints.

**2. Reported relief depends more on the individual company than on the sector.**
- At first glance, fintech complaints closed with relief far less often in every theme (e.g., fraud: 10.2% vs. 20.2%).
- Controlling for product changes the picture. In **checking & savings** the gap holds (9.4% vs. 21.5%). In **money transfer** it is small (8.4% vs. 13.2%), and for money-transfer **fraud** complaints the rates are nearly identical (10.6% vs. 10.9%).
- Companies differ widely *within* each sector. In checking, Bank of America reported relief on 40.3% of closed complaints and Capital One on 8.5%; among fintechs, PayPal reported 29.9% and Block (Cash App) 0.1%.
- **Block closed 55,614 of 55,637 complaints (99.96%) "with explanation."** Excluding Block reverses the money-transfer comparison (fintechs 19.7% vs. banks 13.2%). In checking (11.8% vs. 21.5%) and prepaid (5.1% vs. 45.4%) the bank rate remains higher.
- Because companies appear to use the CFPB's response categories very differently, relief rates are best compared company by company and read with caution.

**3. The 2025 money-transfer surge was mostly a short spike in mid-January 2025, concentrated in two companies.**
- Block (+40,643) and Early Warning Services, the operator of Zelle (+19,220), account for about 88% of the 2024→2025 increase.
- Most of the increase was filed under the CFPB's generic issue "Other transaction problem" (3,007 → 53,893), so the structured data cannot show what these complaints were about.
- In January 2025 alone, Block received 30,466 money-transfer complaints and Early Warning Services 16,521, versus roughly 150–200 and 30–80 in a typical 2024 month. Block's spike begins on January 16, 2025, the day the CFPB announced an order against Block ([CFPB](https://www.consumerfinance.gov/enforcement/actions/block-inc/)), and peaks the next day at 12,638 complaints. Early Warning Services' spike begins January 15. The data cannot confirm the cause of either spike.

## Data

- **Source:** [CFPB Consumer Complaint Database](https://www.consumerfinance.gov/data-research/consumer-complaints/), full CSV downloaded **October 14, 2026** (18,399,780 complaints).
- **Why not the BigQuery public dataset?** `bigquery-public-data.cfpb_complaints.complaint_database` ends on 2023-03-23, so the current file was downloaded from the CFPB and loaded into a personal BigQuery dataset.
- **Scope:** complaints received from 2021-01-01, excluding credit reporting products (2,136,075 complaints loaded). The analysis uses three products: checking or savings account; money transfer, virtual currency, or money service; and prepaid card, including prepaid sub-products of the pre-August-2023 "Credit card or prepaid card" product. 523,233 complaints after exclusions.
- **Time:** findings use full years 2021–2025. 2026 is partial (through October 14) and appears only in the monthly trend, which stops at September 2026.

## Method

**Pipeline (all SQL in `sql/`):**

| Layer | File | What it does |
|---|---|---|
| Ingest | `scripts/extract_filter.py` | Filters the 5.6 GB CSV with DuckDB to 2021+ and non-credit-reporting products; writes Parquet for BigQuery |
| Exploration | `sql/00_exploration/` | Profiles products, sub-products, and issue labels |
| Staging | `sql/01_staging/stg_complaints.sql` | Scopes products, joins complaints to issue themes, adds closed/timely/relief flags |
| Intermediate | `sql/02_intermediate/int_complaints_enriched.sql` | Joins company classifications; defines fintech vs. bank sectors |
| Marts | `sql/03_marts/` | Theme mix by sector, company benchmark, monthly trend (dashboard tables) |
| Analysis | `sql/04_analysis/` | Sensitivity checks and the money-transfer surge investigation |

**Techniques:** CTEs; joins across complaints, an issue-theme mapping, and a company classification table; window functions for shares of total, sector averages, cumulative coverage, and ranks.

**Analyst decisions (documented in `seeds/`):**
- **Issue themes** (`seeds/issue_theme_map.csv`): 117 product/issue/sub-issue combinations grouped into five themes. The CFPB changed its complaint form in August 2023, so old and new labels were mapped to the same themes (e.g., "Account opened as a result of fraud" and "Account opened without my consent or knowledge" both map to fraud). One mixed money-transfer label ("Unauthorized transactions or other transaction problem") is flagged as *broad* fraud rather than *core* fraud.
- **Company classification** (`seeds/company_classification.csv`): the top 100 companies by complaint volume plus 4 alternate names (about 96% of in-scope complaints; 1,301 companies in total). Types: bank, digital bank, credit union, fintech, bank-owned network (Zelle's operator), traditional money service business, processor/vendor, other. Medium- and low-confidence classifications are flagged.
- **Sectors:** the main comparison is fintech vs. banks and credit unions (including digital banks). An alternative definition counts digital banks (e.g., SoFi, Ally) as fintech. Zelle's operator, traditional money transmitters, processors, and unclassified companies are kept out of the sector comparison.
- **Relief rate** = complaints closed with monetary or non-monetary relief ÷ closed complaints ("In progress" excluded).

## Limitations

- **Complaints are not a representative sample** of customer experiences, and the CFPB does not verify complaint allegations. Counts are not adjusted for company size or customer base, so higher volume does not mean a worse company.
- **Relief is reported by companies, not verified.** Response patterns (e.g., Block's 99.96% "closed with explanation") suggest companies record outcomes differently, which limits comparisons.
- **Unpublished complaints:** complaints about depository institutions under $10 billion in assets are referred to other regulators and are not in the public database, so small banks and credit unions are underrepresented.
- **Classifications are judgment calls.** Fintech/bank labels and issue themes are the author's, and several companies are hard to categorize (e.g., chartered digital banks, Zelle's bank-owned operator).
- **Generic issue labels:** "Other transaction problem" is the largest money-transfer category and drove most of the 2025 increase. Complaint narratives were not analyzed.
- **Causation:** findings are descriptive. The timing of the January 2025 spike coincides with regulatory news but does not establish a cause.
- **BigQuery sandbox** tables expire after 60 days; the pipeline can be rebuilt from the scripts and seed files in this repo.

## Reproduce

1. Download `complaints.csv.zip` from the CFPB link above into `data/raw/` (git-ignored).
2. `pip install -r requirements.txt`, then `python scripts/extract_filter.py`.
3. Upload `data/processed/complaints_2021plus.parquet` to BigQuery as `cfpb.complaints_raw`, and upload the two `seeds/` CSVs as `cfpb.issue_theme_map` and `cfpb.company_classification`.
4. Run the SQL files in order: `01_staging` → `02_intermediate` → `03_marts`.
5. Export the three marts to Google Sheets and connect them to Tableau Public.

## Tools

Google BigQuery (GCP sandbox) · SQL · Python (DuckDB) · GitHub Codespaces · Google Sheets · Tableau Public