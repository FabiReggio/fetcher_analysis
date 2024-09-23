-- Average migrations per week

SELECT 
      MIN(temp.migrations_per_week) AS min_migrations_per_week
    , MAX(temp.migrations_per_week) AS max_migrations_per_week
    , AVG(temp.migrations_per_week) AS avg_migrations_per_week
FROM (
    SELECT 
        YEAR(timestamp) AS year 
        , MONTH(timestamp) AS month
        , WEEK(timestamp) AS week
        , COUNT(*) AS migrations_per_week
    FROM mpm_migrations
    WHERE 1=1
    [[AND YEAR(timestamp) >= {{year}}]]
    GROUP BY YEAR(timestamp), MONTH(timestamp), WEEK(timestamp)
    ORDER BY YEAR(timestamp) DESC, MONTH(timestamp) DESC, WEEK(timestamp) DESC 
) AS temp;
    