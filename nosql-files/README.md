## NoSQL Queries & Results
**1. How many product categories are there? For each product category, show the number of records.**
```javascript
db.baristacoffeesalestbl.aggregate([
    {
        $group: {_id: "$product_category", records: {$sum:1}}
    }  
])
```

**Explanation:**
- Group all documents by `product_category`.
- Count the number of documents in each group using `$sum: 1`.
- Rename the count field as `records` for clarity.
- The result shows how many sales records belong to each product category.

**Result:**
```javascript
/* 1 */
{
	"_id" : "Merchandise",
	"records" : 14518
},

/* 2 */
{
	"_id" : "Cold Drinks",
	"records" : 14319
},

/* 3 */
{
	"_id" : "Coffee",
	"records" : 14263
},

/* 4 */
{
	"_id" : "Pizza",
	"records" : 14453
},

/* 5 */
{
	"_id" : "Snacks",
	"records" : 14159
},

/* 6 */
{
	"_id" : "Tea",
	"records" : 14183
},

/* 7 */
{
	"_id" : "Cake",
	"records" : 14105
}
```

- There are 7 product categories, and all of them have relatively similar sales counts, with no category much higher or lower than the others.

---

**2. What is the average caffeine per beverage type (coffee/tea/energy drink)?**
```javascript
db.caffeine_intake_tracker.aggregate([
    {
        $project: {
            beverage:{
                $switch: {
                  branches: [
                     {case: {$eq: ["$beverage_coffee", "True"]}, then: "coffee"},
                     {case: {$eq: ["$beverage_energy_drink", "True"]}, then: "energy_drink"},
                     {case: {$eq: ["$beverage_tea", "True"]}, then: "tea"},
                  ],
                  default: "none"
                }
            },
            caffeine_mg:1
        }
    },
    {
        $match: {beverage: {$ne: "none"}}
    },
    {
        $group: {
        _id: "$beverage",
        avg_caffeine: {$avg: "$caffeine_mg"},
        count: {$sum: 1} 
        }
    },
    {
        $sort: {avg_caffeine: -1}
    }
])
```

**Explanation:**
- Creates a new field `beverage` that labels each record as `"coffee"`, `"energy_drink"`, or `"tea"` based on boolean flags.
- Keeps the `caffeine_mg` field for aggregation purposes.
- Filters out any records that do not match one of the three beverages.
- Groups the remaining records by beverage type, calculating the average caffeine and the count of records for each type.

**Result:**
```javascript
/* 1 */
{
	"_id" : "energy_drink",
	"avg_caffeine" : 0.6385880077369439,
	"count" : 47
},

/* 2 */
{
	"_id" : "coffee",
	"avg_caffeine" : 0.4498627787307033,
	"count" : 265
},

/* 3 */
{
	"_id" : "tea",
	"avg_caffeine" : 0.1356624758220503,
	"count" : 188
}
```

- Energy drinks have the highest average caffeine per serving, but are the least frequently recorded (47 records).
- Coffee is the most commonly consumed beverage (265 records) with a moderate average caffeine level.
- Tea is consumed fairly often (188 records) but has the lowest average caffeine.

---

**3. How does sleep impact rate vary by time of day (morning/afternoon/evening)?**
```javascript
db.caffeine_intake_tracker.aggregate([
    {
        $project: {
            time_of_day:{
                $switch: {
                  branches: [
                     {case: {$eq: ["$time_of_day_evening", "True"]}, then: "evening"},
                     {case: {$eq: ["$time_of_day_morning", "True"]}, then: "morning"},
                     {case: {$eq: ["$time_of_day_afternoon", "True"]}, then: "afternoon"},
                  ],
                  default: "none"
                }
            },
            sleep_impacted:1
        }
    },
    {
        $match: {time_of_day: {$ne: "none"}}
    },
    {
        $group: {
        _id: "$time_of_day",
        impacted_rate: {$avg: {$toDouble: "$sleep_impacted"}},
        n: {$sum: 1} 
        }
    },
    {
        $sort: {impacted_rate: -1}
    }
])
```

**Explanation:**
- Labels each record with a `time_of_day` category (morning, afternoon, or evening) based on the original boolean fields.  
- Calculates the average sleep impact and the number of records for each time category.  
- Orders the results by highest to lowest average sleep impact.

**Result:**
```javascript
/* 1 */
{
	"_id" : "evening",
	"impacted_rate" : 0.5,
	"n" : 94
},

/* 2 */
{
	"_id" : "morning",
	"impacted_rate" : 0.40977443609022557,
	"n" : 266
},

/* 3 */
{
	"_id" : "afternoon",
	"impacted_rate" : 0.3357142857142857,
	"n" : 140
}
```

- Evening caffeine intake has the highest average impact on sleep but occurs in fewer records (94).  
- Morning consumption is more frequent (266 records) with a moderate sleep impact.  
- Afternoon intake is the least impactful on sleep and occurs in the fewest records after evening (140).

--- 

**4. Bucket caffeine into Low/Med/High and compare average sleep quality.**
```javascript
db.caffeine_intake_tracker.aggregate([
    {
        $bucket: {
            groupBy: "$caffeine_mg",
            boundaries: [0, 0.25, 0.5, 1.5],
            default: "Other",
            output: {
            avg_sleep_quality: {$avg: "$sleep_quality"},
            avg_focus: {$avg: "$focus_level"},
            n: {$sum: 1}
        }
    }
  },
  {
      $addFields: {
        caffeine_band: {
            $switch: {
              branches: [
                 {case: {$eq: ["$_id", 0]}, then: "Low"},
                 {case: {$eq: ["$_id", 0.25]}, then: "Med"},
                 {case: {$eq: ["$_id", 0.5]}, then: "High"}
              ],
              default: "Other"
            }
        }
    }
  },
  {$project: {_id: 0}}
])
```

**Explanation:**
- Buckets caffeine values into defined ranges (0–0.25, 0.25–0.5, 0.5–1.5) and assigns any out-of-range values to `"Other"`.
- Calculates the average sleep quality, average focus, and the number of records (n) for each bucket.
- Adds a field 'caffeine_band' with labels "Low", "Med", "High".

**Result:**
```javascript
/* 1 */
{
	"avg_sleep_quality" : 0.6783381825926825,
	"avg_focus" : 0.7201426464068994,
	"n" : 202,
	"caffeine_band" : "Low"
},

/* 2 */
{
	"avg_sleep_quality" : 0.6208150672533052,
	"avg_focus" : 0.8633812004882586,
	"n" : 163,
	"caffeine_band" : "Med"
},

/* 3 */
{
	"avg_sleep_quality" : 0.4584342302066525,
	"avg_focus" : 0.9376842313809266,
	"n" : 135,
	"caffeine_band" : "High"
}
```

- Participants in the Low caffeine band have the highest average sleep quality (0.678) but relatively lower focus (0.720).  
- Those in the Medium caffeine band show a moderate sleep quality (0.621) with increased focus (0.863).  
- The High caffeine band has the lowest sleep quality (0.458) but the highest focus (0.938).  
- The number of records decreases as caffeine level increases, suggesting fewer participants consume high amounts of caffeine.

---

**5. What is the total revenue and order count?**
```javascript
db.coffeesales.aggregate([
  {
    $addFields: { money_num: { $toDouble: "$money" } }
  },
  {
    $group: { _id: null, orders: { $sum: 1 }, revenue: { $sum: "$money_num" } }
  },
  {
    $project: { _id: 0, orders: 1, revenue: 1 }
  }
])
```

**Explanation:**
- Converts the `money` field to a numeric type so that calculations can be performed.  
- Aggregates all documents into a single group, calculating the total number of orders and the total revenue.  
- Removes the `_id` field from the output, displaying only `orders` and `revenue`.

**Result:**
```javascript
{
	"orders" : 1133,
	"revenue" : 37508.88
}
```

---

**6. Which drink is most cash-heavy?**
```javascript
db.coffeesales.aggregate([
    {
        $addFields: {
            is_cash: {$eq: ["$cash_type", "cash"]},
            money_num: {$toDouble: "$money"}
        }
    },
    {
        $group: {
            _id: "$coffee_name",
            cash_orders: {$sum: {$cond: ["$is_cash", 1, 0]}},
            total_orders: {$sum: 1},
            cash_rev: {$sum: {$cond: ["$is_cash", "$money_num", 0]}},
            total_rev: {$sum: "$money_num"}
        }
    },
    {
        $project: {
            coffee_name: "$_id",
            cash_order_share: {$cond: [{$gt: ["$total_orders", 0]}, {$divide: ["$cash_orders", "$total_orders"]}, null]},
            cash_revenue_share: {$cond: [{$gt: ["$total_rev", 0]}, {$divide: ["$cash_rev", "$total_rev"]}, null]},
            _id: 0
        }
    },
    {$sort: {cash_revenue_share: -1}}
])
```

**Explanation:**
- Adds fields to identify cash payments and convert revenue to numeric values.  
- Groups data by coffee type to calculate total orders, total revenue, and cash-specific orders and revenue.  
- Computes the share of cash orders and cash revenue for each coffee type.  
- Sorts the coffee types by cash revenue share in descending order.

**Result:**
```javascript
/* 1 */
{
	"coffee_name" : "Cocoa",
	"cash_order_share" : 0.11428571428571428,
	"cash_revenue_share" : 0.12114758399308609
},

/* 2 */
{
	"coffee_name" : "Espresso",
	"cash_order_share" : 0.10204081632653061,
	"cash_revenue_share" : 0.11266377132888737
},

/* 3 */
{
	"coffee_name" : "Latte",
	"cash_order_share" : 0.102880658436214,
	"cash_revenue_share" : 0.10999940060871516
},

/* 4 */
{
	"coffee_name" : "Americano",
	"cash_order_share" : 0.08284023668639054,
	"cash_revenue_share" : 0.08870630891326159
},

/* 5 */
{
	"coffee_name" : "Hot Chocolate",
	"cash_order_share" : 0.08108108108108109,
	"cash_revenue_share" : 0.08601825458524084
},

/* 6 */
{
	"coffee_name" : "Cappuccino",
	"cash_order_share" : 0.07653061224489796,
	"cash_revenue_share" : 0.08113850274234502
},

/* 7 */
{
	"coffee_name" : "Americano with Milk",
	"cash_order_share" : 0.055970149253731345,
	"cash_revenue_share" : 0.060218973859385204
},

/* 8 */
{
	"coffee_name" : "Cortado",
	"cash_order_share" : 0.050505050505050504,
	"cash_revenue_share" : 0.05464321622684949
}
```

- Cash payments account for roughly 5–12% of total orders and revenue across different coffee types.  
- Cocoa has the highest proportion of cash orders and cash revenue, while Cortado has the lowest.  
- Overall, most coffee sales are made through non-cash payments, with only a small fraction coming from cash.
