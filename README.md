# Customer-Value-Analytics-A-Data-Driven-Retention-Strategy
Developed an end-to-end customer analytics solution using Python, MySQL, and Power BI to segment customers, measure loyalty, and deliver data-driven retention strategies for a D2C fashion brand.
## The Business Problem
The Dataset: [Kaggle Link](https://www.kaggle.com/datasets/iamsouravbanerjee/customer-shopping-trends-dataset)

A direct-to-consumer fashion brand sells clothing, accessories, footwear, and outerwear entirely online across the US. It has behavioral data on ~3,900 customers, runs a promotional discount program, but has never built a structured way to understand its customers beyond surface-level sales numbers.

The founding team needed answers to five questions:

1. **Who are the genuinely loyal customers** vs. those who only buy when there is a discount?
2. **What behavioral patterns today predict high customer value** over time?
3. **Which geographies are commercially underlevered** — organic demand vs. discount-driven volume?
4. **How should the brand restructure its promotional strategy** to protect margins without losing volume?
5. **What does the brand's ideal customer look like**, and how can it acquire more of them?

The core analytical constraint: the dataset has **no loyalty score, no churn label, and no timestamps**. Every metric had to be constructed from available variables, not assumed.

---

## Repository Structure

```
.
├── Customer_Value_Analytics.ipynb          # Python: data cleaning + feature engineering
├── Customer_Value_Analytics.sql            # SQL: 5 segmentation queries (CTEs + window functions)
├── customer_value_analytics_cleaned.csv    # Output: cleaned + enriched dataset (3,900 rows)
├── Customer_Value_Analytics_Dashboard.pdf  # Power BI: 5-page founder dashboard (PDF export)
├── Retention_Playbook_Strategy_Memo.docx   # Strategy memo: promotional sunset plan + ICP
├── Project_Walkthrough_Plain_English.docx  # Plain-language walkthrough of every step
└── README.md
```

---

## What Was Built, in Order

### Stage 1 — Python: Data Preparation & Feature Engineering (`Customer_Value_Analytics.ipynb`)
Cleaned the raw dataset from and engineered four composite metrics from scratch:

| Metric | What it measures | How it was built |
|---|---|---|
| **Customer Health Index (CHI)** | Strength of the overall customer relationship | Correlation-weighted blend of purchase volume, review rating, and purchase cadence |
| **Promotion Dependency Index (PDI)** | How much a customer relies on discounts to transact | Correlation-weighted blend of subscription status, purchase volume, and cadence against discount usage |
| **Commercial Loyalty** | The selected loyalty definition | CHI tier crossed with Promotion tier — High / Moderate / Low |
| **Behavioural Loyalty** | Independent second-opinion loyalty score | Purchase volume + cadence + satisfaction, each worth one point |

**The loyalty decision:** two competing definitions were built, tested against three business criteria (revenue gap, average CHI of the "High" group, average PDI of the "High" group), and one was selected. Commercial Loyalty won: larger revenue gap ($1.28 vs $1.18), near-identical customer health (CHI 86.16 vs 86.82), and dramatically lower promotion dependency (PDI 3.42 vs 30.72). 97% of "High" Commercial Loyalty customers score High or Moderate on the Behavioural measure — strong internal consistency between two independently-built definitions.

---

### Stage 2 — SQL: Customer Segmentation & Analysis (`Customer_Value_Analytics.sql`)

Five queries built in PostgreSQL dialect, each answering one of the five business questions above. Key techniques used:

- **CTEs (`WITH ... AS`)** — break each query into named, readable stages rather than nested subqueries
- **`ROW_NUMBER() OVER`** — ranked leaderboards of top customers by spend within a loyalty tier
- **`NTILE(10) OVER`** — split customers into tenure deciles to check if spend and satisfaction moved consistently with purchase history
- **`RANK() OVER`** — scored every state on three independent axes (revenue, promo dependency, customer count) and added the ranks into one opportunity score
- **`SUM() / AVG() OVER()`** — calculated each segment's share of total revenue/customers in the same row as the segment, without collapsing the table

---

### Stage 3 — Power BI: Founder Dashboard (`Customer_Value_Analytics_Dashboard.pdf`)

A five-page dashboard designed for a non-technical founding team. All panels are driven directly from `customer_value_analytics_cleaned.csv`.

| Page | Panel | What it shows |
|---|---|---|
| 1 | **Customer Pyramid** | How value (CHI-based commercial loyalty) distributes across the base; revenue concentration at the top |
| 2 | **Promo Dependency vs. Retention** | PDI and CHI side-by-side by loyalty tier; the Behavioural Mix stacked bar; the Bargain Hunter (1,053 customers / 27%) vs. genuinely loyal split |
| 3 | **Geographic Opportunity Map** | US choropleth coloured by revenue; ranked bars for lowest promo dependency (Kansas, Wisconsin, Tennessee) and highest loyalty conversion (Michigan, Hawaii, Maryland); Commercial Loyalty distribution by top-revenue states |
| 4 | **Category Funnel** | Revenue and customer distribution by category; loyalty mix within each category; corrected average-previous-purchases figures per category |
| 5 | **Final Executive Dashboard** | One-page summary combining the map, category donut, promo reliance bar, and customer distribution for a single-screen briefing |
<img width="1202" height="780" alt="Screenshot 2026-08-01 025945" src="https://github.com/user-attachments/assets/a5372f5b-8a39-410f-a262-35a82e343604" />

---

### Stage 4 — Strategy Memo: Retention Playbook (`Retention_Playbook_Strategy_Memo.docx`)

A formal strategy memo addressed to the Chief Revenue Officer, structured as a management consulting deliverable. Contains:

#### Key Findings

- **Loyalty is not about basket size.** Average order value is nearly identical across all three loyalty tiers: $60.20 (High) vs $59.73 (Moderate) vs $58.92 (Low). The entire difference is CHI (86.16 vs 68.75 vs 53.90) and PDI (3.42 vs 28.68 vs 97.16).
- **1,053 "Bargain Hunters" (27% of the base) generate 26.9% of revenue — all discount-subsidized.** This group is two sub-segments: 246 Low-tier customers and 807 Moderate-tier customers who carry Low-tier PDI (~98) despite Moderate-tier health.
- **Kansas has the lowest PDI of any state at 14.69** — roughly half the next-lowest — suggesting unusually strong organic pull worth understanding before assuming it generalises.

#### Promotional Sunset Plan (two-segment, phased)

**Segment A — Low Commercial Loyalty (246 customers)**  
*Trigger:* PDI ≥ 97 + CHI < 55 on any transaction  
*Action:* Remove automatic discount eligibility; replace with free shipping on next order  
*Timeline:* 6 weeks — 3-week pilot (50% of segment), 3-week full rollout if CHI holds  
*Track:* Revenue retention rate (post-cut spend ÷ pre-cut spend, treatment vs control); 90-day full-price conversion  
*Trade-off:* 6.3% of customers, 6.2% of revenue at risk — the safest move available. Real risk is abrupt cut causing negative sentiment; the free-shipping substitute is designed to absorb it.

**Segment B — Moderate-tier Bargain Hunters (807 customers)**  
*Trigger:* PDI ≥ 97 + CHI in the 68–71 range (Moderate tier health, Low tier dependency)  
*Action:* Step down discount frequency (every second purchase instead of every purchase), then replace residual discounts with a loyalty-points accrual mechanic  
*Timeline:* One full quarter, in three 4-week stages  
*Track:* Segment-level average CHI held stable while PDI declines stage-over-stage  
*Stop rule:* If CHI falls more than 5 points from Stage 0 baseline at any stage checkpoint, halt and revert  
*Trade-off:* 3× the size of Segment A with meaningfully more revenue at stake. Moving too fast risks pushing engaged customers into the Low tier; moving too slowly leaves margin on the table indefinitely.

#### Ideal Customer Profile (ICP)

Built from the 704 High Commercial Loyalty customers (18.1% of base):

| Attribute | Profile |
|---|---|
| Average age | 43.7 years |
| Gender | 56.7% male / 43.3% female |
| Top category | Clothing (43%), then Accessories (31%) |
| Purchase cadence | Every ~35 days |
| Historical volume | 33.6 previous purchases on average |
| Discount usage | 19.5% of transactions — occasional, not habitual |
| Satisfaction | 98.3% "Satisfied"; avg review rating 4.5 / 5.0 |
| Subscription enrolled | 0% — this loyalty is not subscription-driven |
| Best-fit states | Montana, Idaho (top revenue + above-average loyalty rate); Wisconsin (lowest PDI + high loyalty rate); Michigan, Hawaii (highest loyalty conversion at 28.8% and 26.2%) |

**Acquisition implication:** lead creative with product and service quality, not discount codes. 19.5% discount usage among the most loyal customers confirms the offer isn't what's earning the relationship.

---

## How to Reproduce

```bash
# 1. Run the Python notebook end-to-end
jupyter notebook Customer_Value_Analytics.ipynb
# Output: customer_value_analytics_cleaned.csv

# 2. Load the cleaned CSV into mySQL and run the SQL queries
psql -d your_db -c "\copy customer_data FROM 'customer_value_analytics_cleaned.csv' CSV HEADER"
psql -d your_db -f Customer_Value_Analytics.sql

# 3. Open Customer_Value_Analytics_Dashboard.pdf to view the dashboard export
#    (original .pbix file: connect to customer_value_analytics_cleaned.csv as data source)
```

**Dependencies (Python):** `pandas`, `numpy`  
**Dependencies (SQL):** mySQL 8+

---

## Data Notes & Limitations

- The source dataset is a **single-transaction snapshot** — one row per customer, no timestamps, no repeat-purchase history log. Every metric is a point-in-time proxy.
- CHI and PDI are **rank-and-compare scores** built for internal segmentation, not externally calibrated probabilities.
- Commercial Loyalty was selected over Behavioural Loyalty using stated criteria (Section 1 of the memo), not a held-out predictive test — no future-period data exists. Validate against real timestamped order history once available.
- Before committing budget against the Promotional Sunset Plan, run a controlled pilot with a holdout group. Correlation between low PDI and high CHI does not by itself prove that reducing discounts causes CHI to hold.

---

## Project Context

Presented at the **Consulting & Analytics Club, IIT Guwahati — Summer Projects '26**, problem statement: *Decoding Customer Value: A SQL-Driven Retention Strategy*.
