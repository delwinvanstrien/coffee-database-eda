## SQL Queries & Results
**1. How many product categories are there? For each product category, show the number of records.**
```sql
SELECT product_category, COUNT(*) AS records
FROM baristacoffeesalestbl
GROUP BY product_category;
```

**Explanation:**
- Group all records by `product_category`.
- Count the number of rows in each group using `COUNT(*)`.
- Rename the count column as `records` for clarity.
- The result shows how many sales records belong to each product category.

**Result:**
| product_category | records |
|----------------|----------|
| Pizza          | 14453    |
| Coffee         | 14263    |
| Snacks         | 14159    |
| Tea            | 14183    |
| Cake           | 14105    |
| Merchandise    | 14518    |
| Cold Drinks    | 14319    |

- Most product categories have a similar number of records (around 14k–14.5k), showing that customer activity is fairly evenly distributed across offerings.
- Beverage items (Coffee, Tea, Cold Drinks) together account for a significant portion of transactions, suggesting that drinks are a core part of sales.
- Cake has the lowest number of records, showing it is less commonly ordered compared to other product categories.

---

**2. For each** `customer_gender` **and** `loyalty_member` **type, show the number of records. Within the same outcome, within each** `customer_gender` **and** `loyalty_member` **type, for each** `is_repeat_customer` **type, show the number of records.**
``` sql
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
```

**Explanation:**
- Count the total number of records per `customer_gender` and `loyalty_member` using a subquery.
- Join this back to the main table to also count records per `customer_gender` + `loyalty_member` + `is_repeat_customer`.
- The result shows both the overall totals and the breakdown by repeat customer status in the same table.

**Result:**
| customer_gender | loyalty_member | records | is_repeat_customer | records |
|-----------------|----------------|---------|------------------|---------|
| Female          | False          | 16690   | True             | 8297    |
| Female          | True           | 16609   | True             | 8297    |
| Female          | False          | 16690   | False            | 8297    |
| Female          | True           | 16609   | False            | 8404    |
| Male            | False          | 16566   | True             | 8328    |
| Male            | True           | 16532   | True             | 8336    |
| Male            | False          | 16566   | False            | 8238    |
| Male            | True           | 16532   | False            | 8196    |

(Partial results shown for brevity. Full output can be reproduced by running the query in the SQL script.)

- There is a balanced customer distribution. The total records for each `customer_gender` are fairly similar (around 16–17k), indicating no single gender dominates the dataset.
- The effect of loyalty member is subtle. Counts for `loyalty_member = True` vs `False` are very close for each gender, suggesting a roughly even split between loyalty members and non-members.

---

**3. For each** `product_category` **and** `customer_discovery_source`, **display the sum of** `total_amount`.
``` sql
SELECT 
    product_category, 
    customer_discovery_source, 
    SUM(CAST(total_amount AS DECIMAL(10,2))) AS total_sales
FROM baristacoffeesalestbl
GROUP BY 
    product_category, 
    customer_discovery_source
ORDER BY product_category;
```

**Explanation:**
- Group all records by `product_category` and `customer_discovery_source`.
- Convert the `total_amount` column, which is stored as text, into a decimal type with two decimal places using `CAST()`.
- Sum the converted values within each group to calculate `total_sales`.

**Result:**
| product_category | customer_discovery_source | total_sales |
|------------------|---------------------------|-------------|
| Coffee           | Event                     | 77125.57    |
| Coffee           | Friend                    | 77442.70    |
| Coffee           | Online Ad                 | 82028.06    |
| Coffee           | Social Media              | 78863.43    |
| Coffee           | Walk-in                   | 79961.91    |

(Partial results shown for brevity. Full output can be reproduced by running the query in the SQL script.)
 
- Social Media and Walk-in sources often appear among the higher totals, hinting that both digital visibility and in-person traffic contribute strongly to performance.
- For Coffee, the highest total comes from Online Ads, suggesting that digital advertising has a noticeable impact on Coffee sales. 
- Coffee and Merchandise show relatively strong totals across multiple channels, indicating broad customer engagement with these categories.

---

**4. Consider consuming coffee as the beverage. For each** `time_of_day` **category and** `gender`, **display the average** `focus_level` **and average** `sleep_quality`.
``` sql
SELECT 
    CASE
        WHEN time_of_day_morning = 'True' THEN 'morning' 
        WHEN time_of_day_afternoon = 'True' THEN 'afternoon'
        WHEN time_of_day_evening = 'True' THEN 'evening'
    END AS time_of_day,
    CASE
        WHEN gender_male = 'True' THEN 'male'
        WHEN gender_female = 'True' THEN 'female'
    END AS gender,
    ROUND(AVG(CAST(focus_level AS DECIMAL(24,18))), 4) AS avg_focus_level,
    ROUND(AVG(CAST(sleep_quality AS DECIMAL(24,18))), 4) AS avg_sleep_quality
FROM caffeine_intake_tracker
WHERE beverage_coffee = 'True'
GROUP BY time_of_day, gender
ORDER BY FIELD(time_of_day, 'morning', 'afternoon', 'evening'), gender;
```

**Explanation:**
- Group coffee drinkers by time of day and gender, using `CASE` statements to convert morning/afternoon/evening and male/female flags into readable labels.
- Calculate the average focus level and sleep quality for each group.
- Only include rows where coffee was consumed.
- Round the averages for readability and order the output chronologically by time of day and then gender.

**Result:**
| time_of_day | gender | avg_focus_level | avg_sleep_quality |
|------------|--------|----------------|-----------------|
| morning    | female | 0.8862         | 0.5580          |
| morning    | male   | 0.8785         | 0.5604          |
| afternoon  | female | 0.8656         | 0.5936          |
| afternoon  | male   | 0.9231         | 0.6010          |
| evening    | female | 0.8440         | 0.5591          |
| evening    | male   | 0.8823         | 0.4401          |

- Focus levels are generally higher in the morning and afternoon compared to the evening.
- Males show higher focus levels than females in the afternoon and evening, but sleep quality for males drops notably in the evening, unlike females whose sleep quality stays fairly consistent.

---

**5. There are problems with the data in the table:** `list_coffee_shops_in_kota_bogor`. **List out the problematic records.**
``` sql
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
        MIN(no) AS min_no
    FROM list_coffee_shops_in_kota_bogor
    GROUP BY url_id, link, location_name, category, address
    HAVING COUNT(*) > 1
) AS t2
ON t1.no = t2.min_no
ORDER BY t1.location_name;
```

**Explanation:**
- Identify duplicate coffee shop entries in the `list_coffee_shops_in_kota_bogor` table based on key columns (`url_id`, `link`, `location_name`, `category`, `address`).
- Use a subquery to find the minimum `no` value for each duplicate combination to represent that group.
- Join the subquery back to the main table to retrieve only one row per duplicate group, including all original columns.

**Result:**
| no | url_id | link | location_name | category | address |
|----|--------|------|---------------|----------|---------|
| 14 | 0x2e6... | `https://www.google.com/maps/place/Agreya+C...` | Agreya Coffee - Bogor | Restaurant | Jl. Kol. E... |
| 31 | 0x2e6... | `https://www.google.com/maps/place/Antholog...` | Anthology Coffee And Tea | Cafe | Komplek... |
| 60 | 0x2e6... | `https://www.google.com/maps/place/Aumont+K...` | Aumont Kofie | Coffee Shop | Jl. A. Yan... |

(Partial results shown for brevity. Full output can be reproduced by running the query in the SQL script.)

- There are 12 coffee shop entries with duplicate records in the table.  
- The query shows one representative row for each duplicate combination, instead of listing every duplicate.  

---

**6. List the amount of spending (money) recorded before 12 and after 12. Before 12 is defined as the time between 0 and < 12 hours. After 12 is defined as the time between =12 and <24 hours.**
``` sql
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
            WHEN HOUR(CONVERT(DATETIME, TIME)) >= 0 AND HOUR(CONVERT(DATETIME, TIME)) < 12 THEN 'Before 12'
            WHEN HOUR(CONVERT(DATETIME, TIME)) >= 12 AND HOUR(CONVERT(DATETIME, TIME)) < 24 THEN 'After 12'
        END AS period
    FROM coffeesales
    WHERE HOUR(CONVERT(DATETIME, TIME)) < 24
) AS t1
GROUP BY period 
ORDER BY period DESC;
```

**Explanation:**
- The query calculates total sales amounts (`money`) for two time periods: 'Before 12' and 'After 12'.
- A subquery extracts the hour from the `DATETIME` column and assigns each row to a period using a `CASE` statement.
- Rows with invalid hours (>=24) are excluded to ensure accuracy.
- The outer query aggregates the sales by `period` using `SUM()` and displays the totals for each period.

**Result:**
| period     | amt |
|------------|-----|
| Before 12  | 6837.56 |
| After 12   | 8991.96 |

- Coffee sales are higher in the afternoon and evening (After 12) than in the morning (Before 12). Customer demand for coffee likely increases later in the day.

---

**7. Consider 7 categories of pH values betwen 0 and 7. For each category of pH values, show the average Liking, Flavor Intensity, Acidity, and Mouthfeel.**
``` sql
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
```

**Explanation:**
- Create a list of predefined pH ranges from '0 to 1' up to '6 to 7'.
- Calculate the average consumer ratings (liking, flavor intensity, acidity, mouthfeel) for each pH range from the `consumerpreference` table.
- Use a LEFT JOIN to ensure all pH ranges appear in the result, even if no data exists for a range (averages show as NULL in that case).

**Results:**
| pH     | avgLiking | avgFlavorIntensity | avgAcidity | avgMouthfeel |
|--------|-----------|------------------|------------|--------------|
| 4 to 5 | 5.52      | 2.88             | 3.31       | 2.88         |
| 5 to 6 | 5.92      | 2.79             | 3.11       | 2.79         |
| 6 to 7 | NULL      | NULL             | NULL       | NULL         |

(Partial results shown for brevity. Full output can be reproduced by running the query in the SQL script.)

- Consumers slightly prefer coffees in the 5 to 6 pH range compared to those in the 4 to 5 pH range, based on the avgLiking scores.
- Flavor intensity and mouthfeel are slightly higher for 4 to 5 pH, while acidity is slightly higher for 4 to 5 pH than 5 to 6 pH.
- No coffees fall outside these ranges, so the other pH ranges have no recorded data.

---

**8. Which stores are consistently top performers from March to July, and what characteristics do they share?**
``` sql
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
FROM (
    SELECT 
        b.store_id,
        MAX(b.store_location) AS store_location,
        MAX(s.location_name) AS location_name,
        cs.shopID,
        EXTRACT(MONTH FROM STR_TO_DATE(cs.date,'%d/%m/%y')) AS month_num,
        SUM(CAST(cs.money AS DECIMAL(10,2))) AS total_money,
        COUNT(*) AS trans_amt,
        AVG(CAST(trc.agtron AS DECIMAL(10,6))) AS avg_agtron,
        ROW_NUMBER() OVER (
            PARTITION BY EXTRACT(MONTH FROM STR_TO_DATE(cs.date,'%d/%m/%y'))
            ORDER BY SUM(CAST(cs.money AS DECIMAL(10,2))) DESC
        ) AS rn
    FROM coffeesales AS cs
    JOIN `top-rated-coffee` AS trc ON cs.coffeeid = trc.ID
    JOIN list_coffee_shops_in_kota_bogor AS s ON cs.shopID = s.no
    JOIN baristacoffeesalestbl AS b ON cs.customer_id = SUBSTRING(b.customer_id, 6)
    WHERE EXTRACT(MONTH FROM STR_TO_DATE(cs.date,'%d/%m/%y')) BETWEEN 3 AND 7
    GROUP BY b.store_id, cs.shopID, month_num
) AS subq
WHERE rn <= 3
ORDER BY month_num, total_money DESC;
```

**Explanation:**
- The query finds the top-performing store locations for each month from March to July based on total money spent.  
- It calculates relevant metrics for these stores, such as average Agtron score, transaction count, and total sales.  
- Only the top 3 stores per month are shown, giving a clear picture of the best-performing locations.

**Results:**
| trans_month | store_id | store_location | location_name | avg_agtron | trans_amt | total_money |
|------------|----------|----------------|---------------|------------|-----------|-------------|
| APR        | STORE_5  | Uptown  | Cafe de Aut               | 61.67 | 3         | 115.12      |
| APR        | STORE_10 | Uptown  | Kopi Oey Bogor            | 63.50 | 2         | 78.70       |
| APR        | STORE_5  | Uptown  | High & Dry Coffee Company | 60.00 | 2         | 77.40       |

(Partial results shown for brevity. Full output can be reproduced by running the query in the SQL script.)

- Most months show a similar range of average Agtron scores (56–63), indicating coffee quality is fairly consistent across top stores.
- The top-performing stores by `total_money` are not always the same as those with the highest number of transactions, suggesting some stores earn more per transaction.
- Uptown locations appear frequently among top stores, indicating higher traffic or more lucrative sales in these areas.
