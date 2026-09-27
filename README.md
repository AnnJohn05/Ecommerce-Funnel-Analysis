# E-Commerce Customer Funnel Analysis & Drop-off Optimization

Analysis of a simulated e-commerce customer journey — **Homepage → Search → Product View → Add to Cart → Checkout → Purchase** — to find where users drop off, why, and what to do about it. Framed as a product manager would: **Problem → Hypothesis → Recommendation → Success KPI**, not just "here's a chart."

**Tools:** SQL · Excel · Tableau
**Dataset:** 50,000 simulated user sessions

---

## Headline Finding

The largest drop-off in the entire funnel is **Product View → Add to Cart (55.6%)**. Segmenting by device shows why it's worth fixing:

| Device  | Product Views | Add to Cart | PV → Cart Rate | Overall Conversion | Avg Order Value |
|---------|--------------:|------------:|----------------:|--------------------:|-----------------:|
| Desktop | 8,611         | 5,576       | **64.8%**        | 17.2%               | $81.55           |
| Mobile  | 14,107        | 4,368       | **31.0%**        | 6.7%                | $83.17           |
| Tablet  | 2,502         | 1,256       | **50.2%**        | 11.7%               | $82.99           |

Mobile is the **largest traffic segment** but converts at less than half the desktop rate at this one stage — and average order value is flat across devices, which rules out "mobile shoppers just spend less" as the explanation. That points to friction in the mobile product-page experience, not a demand problem.

> **Problem:** High mobile Product View → Add to Cart drop-off, the single largest revenue leak in the funnel.
> **Hypothesis:** Poor information hierarchy and a low-visibility Add to Cart CTA on mobile product pages.
> **Recommendation:** Redesign the mobile product page (price/rating/sticky CTA above the fold); A/B test a persistent bottom add-to-cart bar.
> **Success KPI:** Product View → Add to Cart conversion rate, mobile segment.

Full write-up, including traffic-source, category, and new-vs-returning segmentation, is in [`Ecommerce_Funnel_Project_Report.docx`](./Ecommerce_Funnel_Project_Report.docx).

---

## Repository Contents

| File | Description |
|---|---|
| `ecommerce_funnel_data.csv` | Raw session-level dataset (50,000 rows) — one row per session |
| `generate_data.py` | Script that generates the dataset (fixed random seed, fully reproducible) |
| `funnel_analysis.sql` | SQL schema + queries: funnel conversion/drop-off, device/traffic-source/category/user-type segmentation, AOV, monthly trend |
| `Ecommerce_Funnel_Analysis.xlsx` | Excel workbook — raw data + live formula-driven analysis tabs (SUMIFS/AVERAGEIFS, no hardcoded numbers) |
| `Ecommerce_Funnel_Project_Report.docx` | Full report: methodology, findings, and the Problem → Hypothesis → Recommendation → KPI write-up |

### Dataset schema

| Column | Type | Notes |
|---|---|---|
| `User_ID`, `Session_ID` | string | Identifiers |
| `Session_Date` | date | Session date within a 90-day window |
| `Device` | string | Mobile / Desktop / Tablet |
| `Traffic_Source` | string | Organic Search / Paid Search / Social Media / Direct / Email |
| `Product_Category` | string | Electronics / Fashion / Home & Kitchen / Beauty & Personal Care / Sports & Outdoors |
| `User_Type` | string | New / Returning |
| `Homepage_Visit` ... `Purchase` | 0/1 | Funnel stage flags, each conditional on the previous stage |
| `Order_Value` | float | Populated only when `Purchase = 1` |

---

## Excel Workbook Structure

- **PM_Insights** — the Problem/Hypothesis/Recommendation/KPI summary
- **Funnel_Summary** — stage-wise volume, conversion rate, drop-off rate
- **By_Device**, **By_Traffic_Source**, **By_Category**, **New_vs_Returning** — segmented conversion and AOV
- **Mobile_Deep_Dive** — Device × Category cross-tab isolating where the mobile drop-off concentrates
- **Raw_Data** — the full 50,000-row dataset the formulas reference
- **Notes_ReadMe** — assumptions and data dictionary

Every number is a live formula against `Raw_Data`, so replacing that tab with a real analytics export (same column headers) recalculates the entire workbook automatically.

---

## How to Reproduce / Extend

**Regenerate the dataset:**
```bash
python3 generate_data.py
```

**Run the SQL analysis** (any SQL engine — MySQL, PostgreSQL, SQLite):
```sql
-- create the table and load ecommerce_funnel_data.csv, then run funnel_analysis.sql
```
Note: query #9 (monthly trend) uses `DATE_FORMAT`, which is MySQL/SQL Server syntax — swap in `strftime('%Y-%m', Session_Date)` for SQLite or `TO_CHAR(Session_Date, 'YYYY-MM')` for PostgreSQL.

**Build a Tableau dashboard:**
Connect Tableau to `ecommerce_funnel_data.csv` (or the `Raw_Data` tab of the Excel file). The data is already shaped for a funnel chart — one 0/1 flag column per stage, plus `Device`, `Traffic_Source`, `Product_Category`, and `User_Type` as dimensions for filters/segmentation.

---

## Methodology Notes

- This is a **simulated dataset** built for a portfolio/resume project, not real company data — see `Notes_ReadMe` in the workbook for full assumptions.
- The mobile drop-off effect was intentionally modeled on a friction pattern commonly observed in real mobile commerce funnels, so the analysis workflow and PM framing transfer directly to a real dataset with the same column structure — no changes needed to the SQL or Excel formulas.

---

