# 🛒 Cart Abandonment Analysis

 **Identifying why 65% of shoppers leave without buying — using SQL + Power BI**

---

## 📊 Project Preview

### 🔹 Overview Dashboard
<img width="1424" height="784" alt="Screenshot 2026-05-06 134008" src="https://github.com/user-attachments/assets/12fc3c59-d583-4077-bd0b-a74b8b1db028" />



### 🔹 Deep Dive — Category & Discount Impact

<img width="1423" height="781" alt="Screenshot 2026-05-06 134258" src="https://github.com/user-attachments/assets/08223c45-5936-45db-ab69-9b892dc77a4f" />


---

## 📘 Introduction

Cart abandonment is one of the most costly problems in e-commerce — customers browse, add products to their cart, and then leave without completing the purchase.

This project analyzes **25,000 e-commerce sessions** across 2024 to identify the root causes of a **65.15% cart abandonment rate**, quantify the revenue impact, and generate actionable business recommendations.

The analysis combines **SQL-based data processing** with an **interactive Power BI dashboard** to uncover patterns across regions, devices, marketing channels, product categories, and customer types.

---

## 🎯 Objectives

- 📉 Calculate the overall cart abandonment rate and conversion funnel drop-off at each stage
- 🌍 Identify which regions, channels, and devices have the highest abandonment
- 💰 Quantify lost revenue from abandoned carts and wasted discount spend
- 🏷️ Test whether discount percentage actually reduces abandonment
- 👥 Compare behavior of new vs returning users
- 📦 Analyse abandonment by product category
- 📈 Track monthly trends to determine if the problem is seasonal or structural

---

## 🗂️ Dataset and Context

**Primary Dataset:** Ecommerce Session Dataset — 25,000 rows, 24 columns

Each row represents a unique customer session.

| Field | Description |
|-------|-------------|
| Session Details | session_id, customer_id, visit_date |
| Customer Info | user_type (New / Returning), rating |
| Device & Channel | device_type, marketing_channel |
| Geography | region (North / South / East / West) |
| Product Details | product_id, product_category, unit_price, quantity |
| Funnel Flags | product_view, added_to_cart, checkout, Payment, purchased, cart_abandoned |
| Revenue | revenue, discount_percent, discount_amount |
| Engagement | pages_viewed, time_on_site_sec, payment_Method |

---

## 🧰 Tools Used

| Tool | Purpose |
|------|---------|
| **SQL** | Funnel analysis, abandonment rates, lost revenue, CTEs, window functions (LAG, RANK, FIRST_VALUE, AVG OVER) |
| **Power BI** | Interactive 2-page dashboard, KPI cards, funnel chart, heatmap matrix, trend line, conditional formatting |
| **CSV / Excel** | Source data storage |

---

## 🧹 Data Preparation

| Step | Action |
|------|--------|
| ✔ Date Formatting | Converted `visit_date` (DD-MM-YY) to proper Date type for time-series analysis |
| ✔ Column Trimming | Applied TRIM() to `marketing_channel` — had trailing whitespace causing duplicate groups |
| ✔ Null Handling | Used NULLIF() in all division operations to prevent divide-by-zero errors |
| ✔ Funnel Validation | Confirmed all funnel columns (product_view → purchased) are binary flags (0/1) |
| ✔ Outlier Check | Verified revenue and unit_price ranges — no anomalies found |

---

## 📊 Key Findings

| # | Finding | Key Number |
|---|---------|------------|
| 🔻 | Overall cart abandonment rate | **65.15%** across 25,000 sessions |
| 🔻 | Biggest funnel drop — Cart → Checkout | **−50.4%** — 8,117 customers lost at one step |
| 🌍 | North region abandonment rate | **83.14%** vs West at 46.72% — a 36pp gap |
| 💰 | Total net lost revenue | **₹1.86 Crore** from 10,501 abandoned sessions |
| 🏷️ | Discount vs abandonment correlation | **r = 0.006** — discounts have zero effect |
| 💸 | Discount wasted on non-converting carts | **₹18.3 Lakhs** — a double loss |
| 👥 | New user abandonment vs returning | **71.31% vs 60.12%** — 11.19pp trust gap |
| 📦 | Worst category by abandonment rate | **Sports — 66.72%** |
| 📦 | Most revenue lost by category | **Home & Garden — ₹37 Lakhs** |
| 📅 | Worst month | **July — 66.93%** (mid-year traffic spike) |
| 📅 | Best month | **January — 63.74%** (post-holiday, focused buyers) |
| ⏱️ | Converted users spend more time on site | **+42.7 seconds** more than abandoned sessions |

---

## 🔍 SQL Analyses Performed

| # | Analysis | Key SQL Concepts Used |
|---|----------|-----------------------|
| 1 | Conversion funnel — 5-stage drop-off | CTE, UNION ALL, LAG(), FIRST_VALUE() |
| 2 | Abandonment rate by device type | GROUP BY, ROUND(), NULLIF() |
| 3 | Abandonment rate by marketing channel | TRIM(), GROUP BY, ORDER BY |
| 4 | Abandonment rate by region × user type | Cross-tab, RANK() OVER, CASE WHEN |
| 5 | Lost revenue from abandoned carts | SUMX logic, CROSS JOIN totals CTE |
| 6 | Recovery scenario — North vs West benchmark | VAR-style CTE, CROSS JOIN |
| 7 | AOV comparison — converted vs abandoned | CASE WHEN aggregation, AVG() |
| 8 | Discount impact analysis | Pearson correlation in SQL, SQRT(), band buckets |
| 9 | Engagement factors — time & pages viewed | AVG() filtered, bucket analysis |
| 10 | Monthly trend  | STR_TO_DATE(), DATE_FORMAT() |


---

## 📈 Dashboard — 2 Pages

### Page 1 — Overview
| Visual | What It Shows |
|--------|--------------|
| 6 KPI Cards | Abandonment Rate, Conversion Rate, Net Lost Revenue, AOV, Total Sessions |
| Funnel Chart | 5-stage conversion funnel with % of first at each stage |
| Region Bar Chart | Abandonment rate by region with conditional colour + avg reference line |
| Channel Bar Chart | Abandonment by marketing channel — Email worst, Digital Ads best |
| Monthly Trend Line | 12-month line chart with annual avg and Oct peak reference lines |
| 5 Slicers | Device, Region, Channel, User Type, Date Range |

### Page 2 — Deep Dive
| Visual | What It Shows |
|--------|--------------|
| Category Dual-Axis Bar | Abandonment rate + lost revenue on same chart — rate and revenue rank differently |
| Region × Device Heatmap | Matrix with auto-colour cells — North critical across all devices |
| Region × User Type Heatmap | New vs returning by region — North + New = 85.91% worst segment |
| Discount Impact Combo Chart | Flat abandonment line across discount bands — r = 0.006 |
| Engagement Bar Chart | Time on site: converted vs abandoned by device — Tablet gap = 84 seconds |

---

## 💬 Conclusion

| Area | Insight |
|------|---------|
| 🔻 Funnel | Half of all cart-adders drop off before checkout — price shock is the likely cause |
| 🌍 Regional | 36pp gap between North and West — geographic, not behavioural root cause |
| 🏷️ Discounts | r = 0.006 — blanket discounting is proven ineffective and wastes margin |
| 👥 New Users | 11pp higher abandonment — trust and familiarity gap for first-time visitors |
| 📅 Trend | Flat annual trend — structural checkout problem, not seasonal |
| 📦 Category | Rate and revenue rank categories differently — intervention must be category-specific |

---

## 💡 Strategic Recommendations

| Priority | Recommendation | Expected Impact |
|----------|----------------|-----------------|
| 🚨 Critical | Audit North region checkout — payment methods, delivery cost transparency, localisation | Recover **₹31 Lakhs** if North matches West |
| 🛒 High | Fix Cart → Checkout drop — show total cost early, add guest checkout, reduce friction | Reduce 50.4% drop-off at biggest funnel leak |
| 💰 High | Stop blanket discounting — shift ₹18.3L to exit-intent triggers and abandoned cart emails | Stop wasting margin on non-converting sessions |
| 🤝 Medium | Add trust signals for new users — reviews, return policy, simplified sign-up | Close the 11pp new vs returning gap |
| 📦 Medium | Prioritise Home & Garden checkout UX — highest revenue loss despite mid-range rate | Recover ₹37L in lost category revenue |
| 🔁 Low | Study what makes Toys perform at 62% — replicate across other categories | Bring all categories toward benchmark rate |

---

## 🎯 Expected Business Impact

```
🌍 ₹31 Lakhs   →  Recoverable revenue if North matches West benchmark (46.72%)
💸 ₹18.3 Lakhs →  Savings from stopping ineffective discount spend
📉 −10 pp      →  Achievable abandonment rate reduction (65% → 55%) in 12 months
💰 +15–20%     →  AOV increase from checkout UX improvements
👥 +15%        →  Conversion volume gain if new users match returning user rate
```

*⭐ If you found this project useful, please give it a star!*
