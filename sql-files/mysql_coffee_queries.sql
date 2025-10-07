/* Q1
Table considered: <baristacoffeesalesTBL> 
How many product categories are there? For each product category, show the number of records. */

-- Shows each of the 7 product categories and counts the number of records belonging to it.
SELECT product_category, COUNT(*) AS records
FROM baristacoffeesalestbl
GROUP BY product_category;

/* Q2
Table considered: <baristacoffeesalesTBL>
For each customer_gender and loyalty_member type, show the number of records. 
Within the same outcome, within each customer_gender and loyalty_member type, for each is_repeat_customer type, show the number of records. */

-- This query shows two different counts as records in the same outcome.
-- 1) The total number of rows per customer_gender + loyalty_member (computed in the subquery called t2).
-- 2) The total number of rows per customer_gender + loyalty_member + is_repeat_customer (computed in the outer query).
-- The subquery calculates the first count and is joined back to the main table so both counts can appear in the same result.
SELECT 
    t1.customer_gender, 
    t1.loyalty_member, 
    t2.records AS records, 
    t1.is_repeat_customer, 
    COUNT(*) AS records
FROM baristacoffeesalestbl AS t1
JOIN (
    SELECT 
        customer_gender, 
        loyalty_member, 
        COUNT(*) AS records
    FROM baristacoffeesalestbl
    GROUP BY customer_gender, loyalty_member
) AS t2
    ON t1.customer_gender = t2.customer_gender 
   AND t1.loyalty_member = t2.loyalty_member
GROUP BY 
    t1.customer_gender, 
    t1.loyalty_member, 
    t2.records, 
    t1.is_repeat_customer
ORDER BY 
    t1.customer_gender, 
    t1.is_repeat_customer DESC;

/* Q3
Table considered: <baristacoffeesalesTBL> 
For each product_category and customer_discovery_source, display the sum of total_amount. */

-- This query sums the values in the total_amount column per product_category and customer_discovery_source.
-- The total_amount column is stored as text, so we convert it to a decimal using CAST(total_amount AS DECIMAL(10,2)) to preserve two decimal places.
-- Using DECIMAL(10,2) ensures that cents are captured accurately, avoiding rounding errors in the sum.
-- The SUM() function then correctly aggregates the converted numeric values for each category and discovery source.
SELECT 
    product_category, 
    customer_discovery_source, 
    SUM(CAST(total_amount AS DECIMAL(10,2))) AS total_sales
FROM baristacoffeesalestbl
GROUP BY 
    product_category, 
    customer_discovery_source
ORDER BY product_category;

/* Q4
Tables considered: <caffeine_intake_tracker> 
Consider consuming coffee as the beverage, for each time_of_day category and gender, display the average focus_level and average sleep_quality. */

-- This query calculates the average focus level and sleep quality for coffee drinkers, grouped by time of day and gender.
-- The avg_focus_level and avg_sleep_quality columns are stored as text, so they are converted to DECIMAL(24,18) before averaging.
-- Converting to DECIMAL with sufficient precision preserves decimal places and ensures accurate calculations.
SELECT 
    CASE
        WHEN time_of_day_morning = 'True' THEN 'morning' 
        WHEN time_of_day_afternoon = 'True' THEN 'afternoon'
        WHEN time_of_day_evening = 'True' THEN 'evening'
    END AS time_of_day, -- Convert morning, afternoon, and evening flags to string
    CASE
        WHEN gender_male = 'True' THEN 'male'
        WHEN gender_female = 'True' THEN 'female'
    END AS gender, -- Convert male and female flags to string
    ROUND(AVG(CAST(focus_level AS DECIMAL(24,18))), 4) AS avg_focus_level, -- Convert text to decimal, average, round to 4 dp
    ROUND(AVG(CAST(sleep_quality AS DECIMAL(24,18))), 4) AS avg_sleep_quality -- Convert text to decimal, average, round to 4 dp
FROM caffeine_intake_tracker
WHERE beverage_coffee = 'True' -- Only include rows where beverage_coffee is true
GROUP BY time_of_day, gender
ORDER BY FIELD(time_of_day, 'morning', 'afternoon', 'evening'), gender;

/* Q5
Tables considered: <list_coffee_shops_in_kota_bogor> 
There are problems with the data in this table. List out the problematic records. */

-- This query identifies one representative row for each set of duplicate coffee shop entries based on url_id, link, location_name, category, and address. 
-- It ensures that only one problematic duplicate per combination is shown, while retrieving all columns from the original table.
SELECT 
    t1.no, 
    t1.url_id, 
    t1.link, 
    t1.location_name, 
    t1.category, 
    t1.address
FROM list_coffee_shops_in_kota_bogor AS t1
JOIN (
    SELECT 
        url_id, 
        link, 
        location_name, 
        category, 
        address, 
        MIN(no) AS min_no -- Ensure only one of the duplicate rows shows up
    FROM list_coffee_shops_in_kota_bogor
    GROUP BY url_id, link, location_name, category, address
    HAVING COUNT(*) > 1
) AS t2 -- Subquery to find duplicate combinations of identifying columns
ON t1.no = t2.min_no
ORDER BY t1.location_name;

/* Q6
Tables considered: <coffeesales> 
List the amount of spending (money) recorded before 12 and after 12.
Before 12 is defined as the time between 0 and < 12 hours.
After 12 is defined as the time between =12 and <24 hours. */

-- This query calculates the total sales amount for coffee, split into 'Before 12' and 'After 12' periods.
-- There are issues with the data in the datetime column where some rows have hours exceeding 24.
-- To avoid including invalid data, I choose to exclude these rows from the summation of amt. 
-- These rows could still be summed into a third row with a NULL period, but I exclude them from the visible output.
SELECT period, SUM(CAST(money AS DECIMAL(10,2))) AS amt
FROM 
(
    SELECT 
        DATETIME, 
        cash_type, 
        card, 
        money, 
        coffee_name,
        CASE
            WHEN HOUR(CONVERT(DATETIME, TIME)) >= 0 AND HOUR(CONVERT(DATETIME, TIME)) < 12 THEN 'Before 12' -- Convert the original datetime column to extract the hour, then assign rows to 'Before 12' or 'After 12' buckets
            WHEN HOUR(CONVERT(DATETIME, TIME)) >= 12 AND HOUR(CONVERT(DATETIME, TIME)) < 24 THEN 'After 12'
        END AS period
    FROM coffeesales
    WHERE HOUR(CONVERT(DATETIME, TIME)) < 24 -- Only sum rows with valid hours, any rows with hours > 24 are excluded
) AS t1
GROUP BY period 
ORDER BY period DESC;

/* Q7
7)	Tables considered: <consumerpreference>
Consider 7 categories of pH values
-	pH >= 0.0 && pH < 1.0
-	pH >= 1.0 && pH < 2.0
-	pH >= 2.0 && pH < 3.0
-	pH >= 3.0 && pH < 4.0
-	pH >= 4.0 && pH < 5.0
-	pH >= 5.0 && pH < 6.0
-	pH >= 6.0 && pH < 7.0
For each category of pH values, show the average Liking, Flavor Intensity, Acidity, and Mouthfeel. */

-- This query calculates average consumer preference scores (liking, flavor intensity, acidity, mouthfeel) for predefined pH ranges. 
-- It ensures all pH ranges from 0–7 are included, even if no data exists for some ranges, by left joining the aggregated averages to a table of all ranges.
SELECT 
    t1.pH, 
    ROUND(t2.avgLiking, 2) AS avgLiking, 
    ROUND(t2.avgFlavorIntensity, 2) AS avgFlavorIntensity, 
    ROUND(t2.avgAcidity, 2) AS avgAcidity, 
    ROUND(t2.avgMouthfeel, 2) AS avgMouthfeel
FROM 
(
    SELECT '0 to 1' AS pH
    UNION ALL SELECT '1 to 2'
    UNION ALL SELECT '2 to 3'
    UNION ALL SELECT '3 to 4'
    UNION ALL SELECT '4 to 5'
    UNION ALL SELECT '5 to 6'
    UNION ALL SELECT '6 to 7'
) AS t1
LEFT JOIN
(
    SELECT
        CASE
            WHEN CONVERT(pH, DECIMAL(4,2)) >= 0.0 AND CONVERT(pH, DECIMAL(4,2)) < 1.0 THEN '0 to 1'
            WHEN CONVERT(pH, DECIMAL(4,2)) >= 1.0 AND CONVERT(pH, DECIMAL(4,2)) < 2.0 THEN '1 to 2'
            WHEN CONVERT(pH, DECIMAL(4,2)) >= 2.0 AND CONVERT(pH, DECIMAL(4,2)) < 3.0 THEN '2 to 3'
            WHEN CONVERT(pH, DECIMAL(4,2)) >= 3.0 AND CONVERT(pH, DECIMAL(4,2)) < 4.0 THEN '3 to 4'
            WHEN CONVERT(pH, DECIMAL(4,2)) >= 4.0 AND CONVERT(pH, DECIMAL(4,2)) < 5.0 THEN '4 to 5'
            WHEN CONVERT(pH, DECIMAL(4,2)) >= 5.0 AND CONVERT(pH, DECIMAL(4,2)) < 6.0 THEN '5 to 6'
            WHEN CONVERT(pH, DECIMAL(4,2)) >= 6.0 AND CONVERT(pH, DECIMAL(4,2)) < 7.0 THEN '6 to 7'
        END AS ph_range,
        AVG(CONVERT(liking, DECIMAL(4,2))) AS avgLiking,
        AVG(CONVERT(flavorintensity, DECIMAL(4,2))) AS avgFlavorIntensity,
        AVG(CONVERT(acidity, DECIMAL(4,2))) AS avgAcidity,
        AVG(CONVERT(mouthfeel, DECIMAL(4,2))) AS avgMouthfeel
    FROM consumerpreference
    GROUP BY ph_range
) AS t2
ON t1.pH = t2.ph_range
ORDER BY t1.pH;

/* Q8 
Tables considered: <coffeesales> + <list_coffee_shops_in_kota_bogor> + <top-rated-coffee> + <baristacoffeesalestbl>
IMPORTANT: The table name “top-rated-coffee” contains hyphens.
Which stores are consistently top performers from March to July, and what characteristics do they share? */

-- This query lists the top 3 coffee shops per month based on the sum of money.
-- The subquery joins the 4 tables together, groups by store, shop, and month, calculates total money, number of transactions, and average agtron, and ranks shops by total money within each month.
-- The outer query filters to keep only the top 3 per month, formats the months as MAR–JUL from numerical values, and rounds avg_agtron for display.
SELECT 
    CASE month_num
        WHEN 3 THEN 'MAR'
        WHEN 4 THEN 'APR'
        WHEN 5 THEN 'MAY'
        WHEN 6 THEN 'JUN'
        WHEN 7 THEN 'JUL'
    END AS trans_month, 
    store_id, 
    store_location, 
    location_name, 
    ROUND(avg_agtron, 2) AS avg_agtron, 
    trans_amt, 
    total_money
FROM 
(
    SELECT 
        b.store_id,
        MAX(b.store_location) AS store_location, -- MAX() makes it so just one store_location is selected per group
        MAX(s.location_name) AS location_name,
        cs.shopID,
        EXTRACT(MONTH FROM STR_TO_DATE(cs.date,'%d/%m/%y')) AS month_num,
        SUM(CAST(cs.money AS DECIMAL(10,2))) AS total_money,
        COUNT(*) AS trans_amt,
        AVG(CAST(trc.agtron AS DECIMAL(10,6))) AS avg_agtron,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(MONTH FROM STR_TO_DATE(cs.date,'%d/%m/%y'))
            ORDER BY SUM(CAST(cs.money AS DECIMAL(10,2))) DESC
        ) AS rn -- Assigns a unique rank to each combination within the same month based on money, with 1 being the highest total money. This allows the outer query to later filter for the top 3 per month.
    FROM coffeesales AS cs
    JOIN `top-rated-coffee` AS trc 
        ON cs.coffeeid = trc.ID
    JOIN list_coffee_shops_in_kota_bogor AS s 
        ON cs.shopID = s.no
    JOIN baristacoffeesalestbl AS b 
        ON cs.customer_id = SUBSTRING(b.customer_id, 6)
    WHERE EXTRACT(MONTH FROM STR_TO_DATE(cs.date,'%d/%m/%y')) BETWEEN 3 AND 7
    GROUP BY b.store_id, cs.shopID, month_num
) AS subq
WHERE rn <= 3
ORDER BY month_num, total_money DESC;