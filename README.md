# Funnel Analysis & Cohort Retention Analysis — Cosmetics E-Commerce

## 📌 Project Overview

This project analyses the full user journey — from browsing to purchase — and measures how well a cosmetics e-commerce platform retains its buyers over time. Using 19.5M+ cleaned events across 1.6M unique users, the analysis maps where users drop off in the conversion funnel, quantifies the scale of cart abandonment, tracks cohort-level retention from October 2019 through February 2020, and benchmarks platform performance against industry standards. The goal: convert behavioural data into specific, actionable decisions — not generic recommendations.

---

## 🎯 Business Problem

A cosmetics e-commerce platform operating across five months has accumulated over 20 million user interaction logs but has no visibility into two critical business questions: where users are dropping off in the purchase journey, and whether acquired users are returning in subsequent months.

Without this visibility, the platform cannot prioritize retention investment, identify funnel leakage points, or quantify the revenue impact of user drop-off.

**Questions from stakeholders:**

1. What percentage of users who view a product go on to purchase?
2. Where is the highest drop-off point in the funnel?
3. How much revenue is at risk from cart abandonment?
4. What percentage of users acquired in Month 1 return in Month 2, 3, and 4?
5. Which acquisition cohort retains best over time?
6. Are there seasonal patterns in conversion or retention?

---

## 📂 Dataset & Scope

- **Source:** [E-Commerce Events History — Kaggle](https://www.kaggle.com/datasets/mkechinov/ecommerce-events-history-in-cosmetics-shop)
- **Raw events:** 20,692,840 → **Clean events:** 19,583,742 (1,109,098 duplicates removed — 5.36%)
- **Unique users:** 1,639,358
- **Time period:** October 2019 – February 2020 (5 months)
- **Domain:** Cosmetics e-commerce

---

## 🧠 Approach

### 1. Data Cleaning & Validation
- Removed 1,109,098 duplicate event rows (5.36% of raw data)
- Validated schema consistency across 5 CSVs
- Confirmed 1,639,358 unique users and 19.5M clean events

### 2. Funnel Analysis
- Mapped the three-stage conversion funnel: View → Cart → Purchase
- Calculated stage-by-stage drop-off rates and cart abandonment at scale
- Estimated revenue at risk from unrecovered abandoned carts

### 3. Cohort Retention Analysis
- Defined the October 2019 cohort (399,664 users) as the primary baseline
- Built a month-by-month retention matrix through Month 4
- Benchmarked platform retention against e-commerce industry standards (20–30% Month 1)

---

## 🔍 Key Findings

| Metric | Platform | Industry Benchmark |
|---|---|---|
| Overall Conversion Rate | **6.92%** | 1–3% (above benchmark) |
| Month 1 Retention | **13.71%** | 20–30% (below benchmark) |
| Cart Abandonment Rate | **72.25%** | ~70% (at benchmark) |

- **Funnel:** 1,597,754 unique users entered the funnel. View → Cart: 24.93%. Cart → Purchase: 27.75%. 288,701 abandoned carts — $1,518,567 in recoverable revenue.
- **Retention:** October cohort (399,664 users) dropped from 13.71% at Month 1 to 6.74% by Month 4. Platform loses 86% of new users after their first month — well below the 20–30% benchmark.
- **Repeat buyers:** 89.66% of users who converted bought again. The problem is not the purchase experience — it's getting users there in the first place.
- **Revenue:** November 2019 peaked at $1,530,831. Total 5-month revenue: $6,348,267. Average time to first purchase: 11.91 days.

---

## ⚡ Strategic Recommendation Snapshot

- **Activate first-month re-engagement** — 86% churn after Month 1 is the single largest value leak. Trigger automated touchpoints at Days 7, 14, and 21 post-signup.
- **Deploy cart recovery within 24 hours** — 288,701 abandoned carts, $1.52M at risk. Price point ($5.26 avg) is low enough that a small incentive closes the deal.
- **Invest ahead of November** — Peak revenue month ($1.53M) requires pre-season inventory and campaign readiness, not reactive spend.
- **Scale eunyul** — 51.32% conversion rate is a product-market fit signal. Increase visibility and inventory allocation.
- **Protect runail** — #1 by volume and revenue. Any supply or margin disruption here has outsized impact.
- **Expand apparel.glove** — 39.59% category conversion rate is the highest on the platform. Expand range and promote within funnel.
- **Align attribution windows to 12-day cycle** — Average 11.91 days to first purchase. Attribution models set below this window will misattribute conversions.
- **Plan December gifting strategy** — Post-November drop requires a gifting campaign to sustain Q4 revenue momentum.

> 📋 Full strategic breakdown available in the Executive Presentation — uploaded in the repository.

---

## 🗂️ Project Assets

- 📓 **Notebook:** Full PACE-structured analysis with outputs and insights
- 🗄️ **SQL:** 6-section query file covering all analysis components
- 📊 **Dashboard:** Power BI report (.pbix) + PDF for instant view 
- 📋 **Executive Presentation:** Detailed strategy deck 
- 📁 **Dataset:** External link above (5 CSVs not included due to size)

---

## 🛠️ Tools & Technologies

- **PostgreSQL 18** — Primary analysis engine: funnel queries, cohort construction, retention matrix, brand/category breakdowns
- **Python** (Pandas, Matplotlib, Seaborn, SQLAlchemy) — Data validation, visualisation, PACE notebook
- **Power BI** — Single-page interactive dashboard (amber/gold on black)
- **Jupyter Notebook** — Full PACE-structured analysis

---

## 🚀 Final Takeaway

The platform's conversion rate beats industry average. Its retention rate doesn't come close.
The opportunity is not in acquisition — it's in the first 30 days after a user arrives.
