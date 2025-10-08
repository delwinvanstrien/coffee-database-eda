/* Q1
Collection considered: <baristacoffeesalesTBL> 
How many product categories are there? For each product category, show the number of records. */

// Groups all documents in the collection by their product_category field then counts how many documents are in each group
db.baristacoffeesalestbl.aggregate([
    {
        $group: {_id: "$product_category", records:{$sum:1}}
    }  
])

/* Q2
Collection considered: <caffeine_intake_tracker>
What is the average caffeine per beverage type (coffee/tea/energy drink)? */

db.caffeine_intake_tracker.aggregate([
    {
        $project: {
            // Creates new field called "beverage" based on the conditions below
            beverage:{
                // Assigns "beverage" as "coffee", "energy_drink" or "tea" based on the original boolean flags in the document
                $switch: {
                  branches: [
                     {case: {$eq: ["$beverage_coffee", "True"]}, then: "coffee"},
                     {case: {$eq: ["$beverage_energy_drink", "True"]}, then: "energy_drink"},
                     {case: {$eq: ["$beverage_tea", "True"]}, then: "tea"},
                  ],
                  default: "none"
                }
            },
            // Keeps caffeine_mg in the projection so it can be used to calculate avg_caffeine
            caffeine_mg:1
        }
    },
    {
        // Filters out any beverage that did not match the three beverages of interest
        $match: {beverage: {$ne: "none"}}
    },
    {
        // Group the selected beverages by their type and display the average caffeine and number of records
        $group: {
        _id: "$beverage",
        avg_caffeine: {$avg: "$caffeine_mg"},
        count: {$sum: 1} 
        }
    },
    {
        // Orders the documents from highest avg_caffeine to lowest
        $sort: {avg_caffeine: -1}
    }
])

/* Q3
Collection considered: <caffeine_intake_tracker> 
How does sleep impact rate vary by time of day (morning/afternoon/evening)? */

// The below query for Q3 is structured similarly to the one in Q2, simply substituing the fields with new ones of interest
db.caffeine_intake_tracker.aggregate([
    {
        $project: {
            // Creates new field called "time_of_day"
            time_of_day:{
                // Assigns time_of_day as "evening", "morning" or "afternoon" based on the original boolean flags in the document
                $switch: {
                  branches: [
                     {case: {$eq: ["$time_of_day_evening", "True"]}, then: "evening"},
                     {case: {$eq: ["$time_of_day_morning", "True"]}, then: "morning"},
                     {case: {$eq: ["$time_of_day_afternoon", "True"]}, then: "afternoon"},
                  ],
                  default: "none"
                }
            },
            // Keeps the sleep_impacted field so it can be used to calculate impacted_rate
            sleep_impacted:1
        }
    },
    {
        // Filter out documents that did not match any of the three branches
        $match: {time_of_day: {$ne: "none"}}
    },
    {
        // Group the selected time_of_day and display the impacted_rate and count (n)
        $group: {
        _id: "$time_of_day",
        // $toDouble converts the sleep_impacted field to numeric for the calculation
        impacted_rate: {$avg: {$toDouble: "$sleep_impacted"}},
        n: {$sum: 1} 
        }
    },
    {
        // Order the documents from highest to lowest
        $sort: {impacted_rate: -1}
    }
])

/* Q4
Collection considered: <caffeine_intake_tracker> 
Bucket caffeine into Low/Med/High and compare average sleep quality. */

db.caffeine_intake_tracker.aggregate([
    {
    // Buckets caffeine_mg values into the ranges defined below
        $bucket: {
            groupBy: "$caffeine_mg",
            // The boundaries create 3 buckets that range between 0 and 1.5, anything outside these buckets fall into "Other"
            boundaries: [0, 0.25, 0.5, 1.5],
            default: "Other",
            output: {
            // Calculates the average sleep quality and focus for the final output, also counts the number of records (n)
            avg_sleep_quality: {$avg: "$sleep_quality"},
            avg_focus: {$avg: "$focus_level"},
            n: {$sum: 1}
        }
    }
  },
  {
      $addFields: {
        // Creates "Low", "Med" and "High" labels or each bucket based on their boundaries
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
  // Hide the _id field from the output
  {$project: {_id: 0}}
])

/* Q5
Collection considered: <coffeesales> 
What is the total revenue and order count? */

db.coffeesales.aggregate([
  {
    // Create a new field called money_num and change "money" to a numeric data type with $toDouble for calculations
    $addFields: { money_num: { $toDouble: "$money" } }
  },
  {
    // Group all documents together into a single group using _id:null and calculate total orders and total revenue
    $group: { _id: null, orders: { $sum: 1 }, revenue: { $sum: "$money_num" } }
  },
  {
    // Hide _id field from the output and display only "orders" and "revenue"
    $project: { _id: 0, orders: 1, revenue: 1 }
  }
])

/* Q6
Collection considered: <coffeesales>
Which drink is most cash-heavy? (cash share by drink) */

db.coffeesales.aggregate([
    // Create two new fields, is_cash and money_num
    {
        $addFields: {
            is_cash: {$eq: ["$cash_type", "cash"]},
            money_num: {$toDouble: "$money"}
        }
    },
    {
        // Group documents by "coffee_name" and calculate cash orders, total orders, cash revenue and total revenue
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
            // Rename the _id field to coffee_name 
            coffee_name: "$_id",
            // Calculate the share of cash orders and cash revenue for each coffee type
            cash_order_share: {$cond: [{$gt: ["$total_orders", 0]}, {$divide: ["$cash_orders", "$total_orders"]}, null]},
            cash_revenue_share: {$cond: [{$gt: ["$total_rev", 0]}, {$divide: ["$cash_rev", "$total_rev"]}, null]},
            _id: 0
        }
    },
    // Order the documents from highest to lowest by proportion of revenue from cash payments
    {$sort: {cash_revenue_share: -1}}
])