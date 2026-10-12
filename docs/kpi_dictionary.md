# KPI dictionary

All KPIs are computed in DuckDB SQL (`sql/kpis/`) on the star schema built by `sql/01-05_*.sql`.

**Common scope.** The analysis window is orders purchased **2017-01-01 to 2018-08-31** (view `v_orders`).
Delivery KPIs use **delivered orders** that have a customer delivery date (view `v_delivered`).
Seller and lane KPIs use the order x seller grain (`v_delivered_by_seller`), because one order can ship from several sellers.

| KPI | Business question | Definition / formula | Grain | Filters | Caveats |
|---|---|---|---|---|---|
| Orders placed | How much demand did we get? | `COUNT(order_id)` | Order | All statuses | Includes canceled/unavailable orders |
| GMV (BRL) | How much merchandise did we sell? | `SUM(price)` of order items | Order item, summed | Excludes `canceled` and `unavailable` orders | Excludes freight; BRL, not inflation-adjusted |
| Orders delivered | How many orders reached the customer? | `COUNT(*)` where status = delivered and delivery date present | Order | Orders marked delivered without a delivery date are excluded (8 in the full dataset) | |
| On-time delivery rate | Do we keep our delivery promise? | `1 - late orders / delivered orders`; late = `delivered date > estimated delivery date` | Order | Delivered orders | Date-level comparison (the estimate has no time of day) |
| Lead time (avg, median, P90) | How long does a customer wait? | `delivered_ts - purchase_ts` in days | Order | Delivered orders | Median and P90 matter more than the mean (long tail) |
| Promised days | What did we promise? | `estimated_date - purchase date` in days | Order | Delivered orders | |
| Approval / seller handling / carrier transit days | Which stage causes delays? | approval = `approved - purchase`; handling = `carrier hand-over - approved`; transit = `delivered - carrier hand-over` | Order | Orders with all three stages >= 0 | Orders with negative stages are excluded (full dataset: 1,358 negative handling, 23 negative transit; see reports/data_quality.md) |
| Late rate by hand-over performance | Is lateness caused by sellers or carriers? | Late rate split by `carrier_ts > shipping_limit_date` (seller missed hand-over deadline) | Order | Delivered orders with a carrier date | Uses the latest shipping limit across the order's items |
| Average rating | How satisfied are customers? | `AVG(review_score)` (1-5) | Order | Delivered orders with a review | One review per order: when an order has several, the latest answered one is kept |
| Share of 1-2 star reviews | How many customers are unhappy? | `COUNT(score <= 2) / COUNT(reviews)` | Order | As above | |
| Share of negative reviews by lateness | How much of the dissatisfaction comes from late deliveries? | 1-2 star reviews in a lateness bucket / all 1-2 star reviews | Order | As above | Correlation, not proof of causation (late orders may differ in other ways) |
| Lane on-time rate | Which seller-state -> customer-state routes fail? | On-time rate grouped by seller state and customer state | Order x seller | Lanes with >= 300 orders | Multi-seller orders count once per seller |
| Freight-to-price ratio | How expensive is delivery relative to the product? | `SUM(freight_value) / SUM(price)` | Order or order item | Delivered orders | Ratio of sums, not average of ratios (weights by value) |
| Seller tier | Which sellers need attention? | A: on time >= 95% and rating >= 4.2; C: on time < 85% or rating < 3.8; B: rest | Seller | Sellers with >= 50 delivered orders | Thresholds are a simple, explainable starting point, not optimised |
| Repeat purchase rate by first-order experience | Does a late first delivery cost future sales? | Customers with more than one order / customers, split by whether their first order was late | Customer (`customer_unique_id`) | First order delivered, inside the window | Repeat buying is rare overall (~3%); the window limits how long we observe each customer |
