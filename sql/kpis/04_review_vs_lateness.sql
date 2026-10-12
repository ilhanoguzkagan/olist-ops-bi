-- How much does a late delivery hurt the customer rating?
SELECT
    CASE
        WHEN NOT is_late     THEN '0. On time'
        WHEN days_late <= 3  THEN '1. 1-3 days late'
        WHEN days_late <= 7  THEN '2. 4-7 days late'
        WHEN days_late <= 14 THEN '3. 8-14 days late'
        ELSE                      '4. 15+ days late'
    END                                                   AS lateness_bucket,
    COUNT(*)                                              AS orders,
    AVG(review_score)                                     AS avg_review,
    AVG((review_score <= 2)::INT)                         AS share_1_2_star,
    AVG((review_score = 5)::INT)                          AS share_5_star,
    -- Share of ALL 1-2 star reviews that come from this bucket.
    SUM((review_score <= 2)::INT) * 1.0
        / SUM(SUM((review_score <= 2)::INT)) OVER ()      AS share_of_negative_reviews,
    COUNT(*) * 1.0 / SUM(COUNT(*)) OVER ()                AS share_of_orders
FROM v_delivered
WHERE review_score IS NOT NULL
GROUP BY ALL
ORDER BY lateness_bucket;
