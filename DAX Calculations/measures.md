# 📊 Measures & Calculations: DailyBrew Sales Analysis

This documentation provides a comprehensive overview of all DAX measures. It is organized by functional area, providing the logic, strategic intent, and formatting for each calculation.

---

### **💰 Revenue & Volume Metrics**

* **Total Sales**: The gross total value of all sales transactions.
    * **Formula**:
    
    
    ```dax
    Total Sales = 
    SUMX (
        'Sales Data',
        'Sales Data'[Qty Sold] * RELATED ( 'Product Details'[Price] ) -- Iterates row-by-row to ensure price changes at the SKU level are captured
    )
    ```
    
    
    * **Formatting**: `\$#,0;(\$#,0);\$#,0`


* **Total Cost**: The aggregate cost of goods sold.
    * **Formula**:
    
    
    ```dax
    Total Cost = 
    SUMX (
        'Sales Data',
        'Sales Data'[Qty Sold] * RELATED ( 'Product Details'[Cost] ) -- Calculates total investment in inventory sold
    )
    ```
    
    
    * **Formatting**: `\$#,0;(\$#,0);\$#,0`


* **Total Profit**: The net financial gain after deducting costs.
    * **Formula**: `[Total Sales] - [Total Cost]`
    * **Formatting**: `\$#,0;(\$#,0);\$#,0`


* **Profit Margin**: The percentage of revenue remaining after costs.
    * **Formula**: `DIVIDE ( [Total Profit], [Total Sales], 0 )`
    * **Formatting**: `0.0%;-0.0%;0.0%`


* **Total Qty Sold**: The total count of physical units sold.
    * **Formula**: `SUM ( 'Sales Data'[Qty Sold] )`
    * **Formatting**: `#,0`



---

### **📉 Efficiency & Averages**

* **Total Transactions**: Unique checkout count representing order volume.
    * **Formula**: `DISTINCTCOUNT ( 'Sales Data'[Transaction SID] )`
    * **Formatting**: `#,0`


* **Total Selling Days**: The count of unique dates where sales occurred.
    * **Formula**: `DISTINCTCOUNT ( 'Sales Data'[Transaction Date] )`
    * **Formatting**: `0`


* **Avg Order Value**: The average monetary value of a single transaction.
    * **Formula**: `DIVIDE ( [Total Sales], [Total Transactions] )`
    * **Formatting**: `\$#,0.00;(\$#,0.00);\$#,0.00`


* **Avg Basket Size**: The average number of units per transaction.
    * **Formula**: `DIVIDE ( [Total Qty Sold], [Total Transactions] )`
    * **Formatting**: `0.00`


* **Avg Sales per Day**: Average revenue generated per active day.
    * **Formula**: `DIVIDE ( [Total Sales], [Total Selling Days] )`
    * **Formatting**: `\$#,0;(\$#,0);\$#,0`


    * **Avg Sales per Product**: Revenue spread across the unique product offerings.
    * **Formula**: `DIVIDE ( [Total Sales], DISTINCTCOUNT ( 'Product Details'[Product Name] ) )`
    * **Formatting**: `\$#,0;(\$#,0);\$#,0`


* **Avg Transactions per Day**: Daily transaction volume average.
    * **Formula**: `DIVIDE ( [Total Transactions], [Total Selling Days] )`
    * **Formatting**: `0.00`


* **Avg Staffs per Day**: Average daily headcount based on active transactions.
    * **Formula**:
    
    
    ```dax
    Avg Staffs per Day = 
    AVERAGEX (
        VALUES ( 'Sales Data'[Transaction Date] ), -- Iterates through the date grain
        CALCULATE ( DISTINCTCOUNT ( 'Sales Data'[Staff ID] ) ) -- Measures workforce presence per day
    )
    ```

    * **Formatting**: `\$#,0;(\$#,0);\$#,0`


* **Avg Transactions per Staff**: Productivity of staff in handling orders.
    * **Formula**: `DIVIDE ( [Avg Transactions per Day], [Avg Staffs per Day] )`
    * **Formatting**: `0.00`



---

### **🚀 Promotion & Product Strategy**

* **Avg Sales per Promo Day**: Average revenue on promotional days.
    * **Formula**:
    
    
    ```dax
    Avg Sales per Promo Day = 
    VAR PromoDates = 
        CALCULATETABLE ( 
            VALUES ( 'Sales Data'[Transaction Date] ), 
            'Sales Data'[promo_item_yn] = "Y" 
        ) 
    
    VAR TotalSalesOnPromoDays = 
        CALCULATE ( 
            [Total Sales], 
            TREATAS ( PromoDates, 'Sales Data'[Transaction Date] ) -- Maps the virtual date list back to the Sales table for efficient filtering
        ) 
    
    RETURN 
        DIVIDE ( TotalSalesOnPromoDays, COUNTROWS ( PromoDates ) )
    ```
    
    
    * **Formatting**: `\$#,0;(\$#,0);\$#,0`


* **Avg Sales per Non-Promo Day**: Average revenue on standard days.
    * **Formula**:
    
    
    ```dax
    Avg Sales per Non-Promo Day = 
    VAR NonPromoDates = 
        CALCULATETABLE ( 
            VALUES ( 'Sales Data'[Transaction Date] ), 
            'Sales Data'[promo_item_yn] = "N" 
        ) 
    
    VAR TotalSalesOnNonPromoDays = 
        CALCULATE ( 
            [Total Sales], 
            TREATAS ( NonPromoDates, 'Sales Data'[Transaction Date] ) 
        ) 
    
    RETURN 
        DIVIDE ( TotalSalesOnNonPromoDays, COUNTROWS ( NonPromoDates ) )
    ```
    
    
    * **Formatting**: `\$#,0;(\$#,0);\$#,0`


* **Promo Uplift**: The percentage increase in sales efficiency during promotions.
    * **Formula**:
    
    
    ```dax
    Promo Uplift = 
    VAR _PromoRatio = DIVIDE ( [Avg Sales per Promo Day], [Avg Sales per Non-Promo Day], 0 ) 
    
    RETURN 
        IF ( _PromoRatio <> 0, _PromoRatio - 1, "N/A" ) -- Normalizes the ratio into a growth/decline percentage
    ```

    * **Formatting**: `"▲ 0.00%;▼ 0.00%; --"`


* **Product Metrics (After New Launch)**: Filters sales to only show performance after a new product's first inventory entry.
    * **Formula**:
    
    
    ```dax
    Product Metrics (After New Launch) = 
    VAR NewProducts = FILTER ( 'Product Details', 'Product Details'[Product Status] = "New" )
    
    VAR MinBakedDate = 
        CALCULATE ( 
            MIN ( 'Inventory Data'[Baked Date] ), 
            TREATAS ( VALUES ( 'Product Details'[Product ID] ), 'Inventory Data'[Product ID] ) 
        ) -- Determines the earliest appearance of the product in inventory records
    
    RETURN 
        CALCULATE ( 
            [Active Measure (Product Metrics)], 
            NewProducts, 
            'Sales Data'[Transaction Date] >= MinBakedDate -- Prevents historical "zero" days from diluting new product performance
        )
    ```



---

### **👥 Customer & Staff Analysis**

* **Total Customers**: Unique customer reach.
    * **Formula**: `DISTINCTCOUNT ( 'Sales Data'[Customer ID] )`
    * **Formatting**: `#,0`


* **Monthly Customer Retention Rate (%)**: Ratio of customers from the previous month who returned.
    * **Formula**:
    
    
    ```dax
    Monthly Customer Retention Rate (%) = 
    IF (
        HASONEVALUE ( '.Calendar Table'[Month] ) && HASONEVALUE ( '.Calendar Table'[Year] ), 
    
        VAR CustomersPrevMonth = 
            CALCULATETABLE ( 
                VALUES ( 'Sales Data'[Customer ID] ), 
                PREVIOUSMONTH ( '.Calendar Table'[Date] ) 
            ) 
    
        VAR CustomersCurrentMonth = 
            CALCULATETABLE ( 
                VALUES ( 'Sales Data'[Customer ID] ), 
                '.Calendar Table' 
            ) 
    
        VAR RetainedCustomers = 
            COUNTROWS ( INTERSECT ( CustomersPrevMonth, CustomersCurrentMonth ) ) -- Set theory: returns IDs existing in both lists
    
        VAR TotalPrevMonth = COUNTROWS ( CustomersPrevMonth ) 
    
        RETURN 
            IF ( TotalPrevMonth = 0, BLANK(), DIVIDE ( RetainedCustomers, TotalPrevMonth ) ), 
        BLANK () -- Suppresses results if multiple months are selected to avoid misleading averages
    )
    ```

    * **Formatting**: `0.0%;-0.0%;0.0%`


* **Customer Lifetime Value**: Predictive estimate of total revenue per customer.
    * **Formula**:
    
    
    ```dax
    Customer Lifetime Value = 
    VAR _MonthlyCustomerChurnRate = 
        VAR PrevCust = CALCULATE ( DISTINCTCOUNT('Sales Data'[Customer ID]), PREVIOUSMONTH('.Calendar Table'[Date]) )
        VAR Churned = 
            COUNTROWS ( 
                EXCEPT ( 
                    CALCULATETABLE(VALUES('Sales Data'[Customer ID]), PREVIOUSMONTH('.Calendar Table'[Date])), 
                    CALCULATETABLE(VALUES('Sales Data'[Customer ID]), '.Calendar Table') 
                ) 
            )
        RETURN DIVIDE(Churned, PrevCust)
    
    VAR _CustomerLifespan = DIVIDE ( 1, _MonthlyCustomerChurnRate ) -- Statistical average lifespan
    VAR _PurchaseFreuqncy = DIVIDE ( [Total Transactions], [Total Customers] )
    
    RETURN [Avg Order Value] * _CustomerLifespan * _PurchaseFreuqncy
    ```

    * **Formatting**: `\$#,0;(\$#,0);\$#,0`


* **Customer Recency (Days)**: Days elapsed since last purchase per customer.
    * **Formula**:
    
    
    ```dax
    Customer Recency (Days) = 
    VAR LastPurchaseDate = 
        CALCULATE ( 
            MAX ( 'Sales Data'[Transaction Date] ), 
            FILTER ( ALL ( 'Sales Data' ), 'Sales Data'[Customer ID] = MAX ( 'Customer Details'[Customer ID] ) ) 
        )
    VAR MaxTransactionDate = CALCULATE ( MAX ( 'Sales Data'[Transaction Date] ), ALL ( 'Sales Data' ) )
    RETURN DATEDIFF ( LastPurchaseDate, MaxTransactionDate, DAY )
    ```
    
    
    * **Formatting**: `0d`


* **RFM Components (Avg Recency, Frequency, Monetary)**:
    * **Avg Recency**: `DIVIDE ( [Customer Recency (Days)], [Total Customers] )`
    * **Avg Frequency**: `DIVIDE ( [Total Transactions], [Total Customers] )`
    * **Avg Monetary**: `DIVIDE ( [Total Sales], [Total Customers] )`


* **Staff Performance**:
    * **Total Staffs**: `DISTINCTCOUNT ( 'Sales Data'[Staff ID] )`
    * **Sales per Staff**: `DIVIDE ( [Total Sales], [Total Staffs] )`
    * **Employee Tenure (Years)**:
    
    
    ```dax
    Employee Tenure (Years) = 
    VAR JoiningDate = CALCULATE ( MAX ( 'Employee Details'[Start Date] ), ALLEXCEPT ( 'Employee Details', 'Employee Details'[Staff ID] ) )
    VAR LastSellingDate = CALCULATE ( MAX ( 'Sales Data'[Transaction Date] ), ALL ( 'Sales Data' ), 'Sales Data'[Staff ID] = MAX ( 'Employee Details'[Staff ID] ) )
    RETURN DATEDIFF ( JoiningDate, LastSellingDate, YEAR )
    ```



---

### **📈 Month-over-Month (Vs Pv) Growth Metrics**

* **Vs Pv (Total Sales)**: Percentage change in sales compared to the previous period.
* **Formula**:


    ```dax
    Vs Pv (Total Sales) = 
    VAR CurrentSales = [Total Sales]
    VAR PrevMonthSales = 
        SWITCH ( TRUE (), 
            -- Logic to toggle comparison target based on slicer selection depth
            NumYears = 0 && NumMonths = 0, CALCULATE ( [Total Sales], DATEADD ( '.Calendar Table'[Date], -1, MONTH ) ),
            NumYears = 1 && NumMonths = 1, CALCULATE ( [Total Sales], DATEADD ( '.Calendar Table'[Date], -1, MONTH ) ),
            NumYears = 1 && NumMonths > 1, CALCULATE ( [Total Sales], SAMEPERIODLASTYEAR ( '.Calendar Table'[Date] ) ), 
            BLANK () 
        )
    RETURN DIVIDE ( CurrentSales - PrevMonthSales, PrevMonthSales )
    ```

    * **Formatting**: `0.0%;-0.0%;0.0%`


* **Vs Pv (Total Transactions)**: (Follows identical SWITCH logic as Sales but for Transactions).
* **Vs Pv (Total Qty Sold)**: (Follows identical SWITCH logic as Sales but for Units).

---

### **🎨 Visual, Labels & Formatting Helpers**

* **Dynamic UI & Parameters**:
    * **Active Measure (Trend Metrics)**: `SWITCH ( TRUE (), [Active Field] = "Total Sales", [Total Sales], [Active Field] = "Transactions", [Total Transactions], [Active Field] = "Customers", [Total Customers], 0 )`
    * **Product Rank**: `RANKX ( ALL ( 'Product Details'[Product Name] ), [Active Measure (Product Metrics)], , DESC, Skip )`
    * **Product Metrics (Multi Sized Products)**: Identifies sales only for SKUs with more than one size variant.


* **Labels & Text**:
    * **Active Store**: `SELECTEDVALUE ( 'Store Details'[Store Name] ) & " || "`
    * **Vs Pv Label (Non-Blank)**: `IF ( NumYears = 1 && NumMonths > 1, "Vs LY Months:", "Vs Pv Month:" )`
    * **No New Product Sold**: `IF ( ISBLANK ( [Product Metrics (After New Launch)] ), "No New Product Has Been Sold.", "" )`
    * **Heatmap Title**: `IF ( ISFILTERED ( '_ Parameter Staffs' ), "Weekly Crowd & Staff Coverage by Hour", "Weekly Crowd by Hour" )`


* **Conditional Colors**:
    * **Vs Pv Color**: `SWITCH ( TRUE (), [Vs Pv Measure] > 0, "#B4E5A2", [Vs Pv Measure] < 0, "#E68F96", "White" )`
    * **Monthly Retention Color**: `IF ( [Monthly Customer Retention Rate (%)] > 0.5, "#B4E5A2", "#E68F96" )`


* **Chart Utilities**:
    * **Annual/Monthly Markers**: Returns value only for peak/valley points for clean data labeling.
    * **Avg Staffs (Show/Hide)**:


    ```dax
    Avg Staffs (Show/Hide) = 
    SWITCH ( FALSE (), 
        ISFILTERED ( Parameter ), "", 
        ISBLANK ( [Avg Staffs per Day] ), [Avg Staffs per Day], 
        "" 
    )
    ```
    
    
    * **Zero Axis**: `0` | **Colon**: `":"` | **Tooltip**: `SELECTEDMEASURE()`



---

### **Explanation of Complex Logics**

1. **Context-Aware Time Intelligence**:
The "Vs Pv" measures use a custom `SWITCH` statement. This is strategic because standard Power BI time intelligence often fails when users select multiple months or haven't selected a year. This logic detects the "grain" of the selection and provides the most relevant comparison (MoM vs YoY).
2. **Product Birthday Logic**:
The `After New Launch` measure is designed for retail "New Product" tracking. By finding the `MinBakedDate`, it ensures that the "Average Daily Sales" for a new item isn't brought down by the months of zero sales before it was ever introduced.
3. **Labor Efficiency Heatmap**:
The `Avg Staffs (Show/Hide)` and `Heatmap Title` measures work in tandem with field parameters. They allow the user to visually overlay staffing levels on top of customer footfall (transactions) to identify hours where the store is understaffed or overstaffed.
