-- Average migrations per month

SELECT 
    temp.month
    , AVG(temp.migrations_per_month) AS avg_migrations_per_month
FROM (
    SELECT 
        YEAR(timestamp) AS year 
        , MONTH(timestamp) AS month
        , COUNT(*) AS migrations_per_month
    FROM mpm_migrations
    WHERE 1=1
    [[AND YEAR(timestamp) >= {{year}}]]
    GROUP BY YEAR(timestamp), MONTH(timestamp)
    ORDER BY YEAR(timestamp) DESC, MONTH(timestamp) DESC
    ) AS temp
GROUP BY temp.month;