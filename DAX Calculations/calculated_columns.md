# 📊 Measures & Calculations: DailyBrew Sales Analysis

This documentation provides a comprehensive overview of the **Calculated Tables**, **Calculated Columns**, and **Field Parameters** used for the DailyBrew analysis. It outlines the structural transformations and row-level logic used to drive business insights, staff optimization, and customer segmentation.

---

### Calculated Tables

* **_RFM Calculation**: Aggregates the raw sales data into a customer-centric table to serve as the foundation for Recency, Frequency, and Monetary (RFM) scoring.
    * **Formula**:
    ```dax
    _RFM Calculation = SUMMARIZE(
        'Sales Data',
        'Sales Data'[Customer ID],
        "R Value", [Customer Recency (Days)],
        "F Value", [Total Transactions],
        "M Value", [Total Sales]
    )
    ```





---

### RFM Calculation Table

* **R Score**: Categorizes customers based on recency quintiles. Higher scores indicate more recent visits.
    * **Formula**:
    ```dax
    VAR R = '_RFM Calculation'[R Value]
    VAR P20 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[R Value], 0.2)
    VAR P40 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[R Value], 0.4)
    VAR P60 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[R Value], 0.6)
    VAR P80 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[R Value], 0.8)
    RETURN
         SWITCH(
             TRUE(),
             R <= P20, 5,
             R <= P40, 4,
             R <= P60, 3,
             R <= P80, 2,
             1
         )
    ```
    
    
    * **Formatting**: `0`


* **F Score**: Scores customers based on transaction frequency quintiles.
    * **Formula**:
    ```dax
    VAR F = '_RFM Calculation'[F Value]
    VAR P20 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[F Value], 0.2)
    VAR P40 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[F Value], 0.4)
    VAR P60 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[F Value], 0.6)
    VAR P80 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[F Value], 0.8)
    RETURN
         SWITCH(
             TRUE(),
             F <= P20, 1,
             F <= P40, 2,
             F <= P60, 3,
             F <= P80, 4,
             5
         )
    ```
    
    
    * **Formatting**: `0`


* **M Score**: Scores customers based on total revenue contributions.
    * **Formula**:
    ```dax
    VAR M = '_RFM Calculation'[M Value]
    VAR P20 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[M Value], 0.2)
    VAR P40 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[M Value], 0.4)
    VAR P60 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[M Value], 0.6)
    VAR P80 = PERCENTILEX.INC('_RFM Calculation', '_RFM Calculation'[M Value], 0.8)
    RETURN
         SWITCH(
             TRUE(),
             M <= P20, 1,
             M <= P40, 2,
             M <= P60, 3,
             M <= P80, 4,
             5
         )
    ```
    
    
    * **Formatting**: `0`


* **Segment**: Assigns qualitative labels to customers based on their RFM profile to guide marketing efforts.
    * **Formula**:
    ```dax
    SWITCH(
         TRUE(),
         [R Score]>= 4 && [F Score]>= 4 && [M Score]>= 4, "Champions",
         [F Score]>= 4 && [M Score]>= 3, "Loyal Customers",
         [R Score]>= 3 && [F Score]>= 3 && [M Score]>= 3, "Potential Loyalists",
         [R Score]>= 4 && [F Score]<= 3 && [M Score]<= 3, "Recent Customers",
         [R Score]>= 3 && [F Score]<= 3 && [M Score]<= 3, "Promising",
         [R Score]<= 3 && [F Score]<= 3 && [M Score]<= 3, "Needs Attention",
         [R Score]<= 2 && [F Score]>= 3 && [M Score]>= 3, "At Risk",
         [R Score]<= 2 && [F Score]<= 2 && [M Score]<= 2, "Hibernating",
         [R Score]= 1, "Lost",
         "Other"
    )
    ```





---

### Customer Details Table

* **Age Group**: Categorizes individual customers into demographic age brackets.
    * **Formula**:
    ```dax
    SWITCH(
         TRUE(),
         'Customer Details'[Age] < 18, "<18",
         'Customer Details'[Age] >= 18 && 'Customer Details'[Age] < 25, "18-24",
         'Customer Details'[Age] >= 25 && 'Customer Details'[Age] < 35, "25-34",
         'Customer Details'[Age] >= 35 && 'Customer Details'[Age] < 45, "35-44",
         'Customer Details'[Age] >= 45 && 'Customer Details'[Age] < 55, "45-54",
         'Customer Details'[Age] >= 55 && 'Customer Details'[Age] < 65, "55-64",
         'Customer Details'[Age] >= 65, "65+",
         "Unknown"
    )
    ```




* **_CustomerSearch**: A calculated column designed to optimize the search experience in the report UI.
    * **Formula**: `'Customer Details'[Customer ID] & 'Customer Details'[Name]`



---

### Time Table

* **Hour Group**: Segments the 24-hour day into 3-hour blocks to identify peak brewing hours and optimize staffing.
    * **Formula**:
    ```dax
    SWITCH( 
        TRUE, 
        ISBLANK('.Time Table'[Hour]), "(Blank)", 
        '.Time Table'[Hour] IN {0, 1, 2}, "00-03", 
        '.Time Table'[Hour] IN {3, 4, 5}, "03-06", 
        '.Time Table'[Hour] IN {6, 7, 8}, "06-09", 
        '.Time Table'[Hour] IN {9, 10, 11}, "09-12", 
        '.Time Table'[Hour] IN {12, 13, 14}, "12-15", 
        '.Time Table'[Hour] IN {15, 16, 17}, "15-18", 
        '.Time Table'[Hour] IN {18, 19, 20}, "18-21", 
        '.Time Table'[Hour] IN {21, 22, 23}, "21-00", 
        "Other" 
    )
    ```





---

### Field Parameters

Field parameters are utilized to allow report users to toggle between different metrics dynamically within the same visual.

 * **Parameter Product Metrics**: Allows switching between Sales and Transaction counts.
 * **Logic**: `{"Total Sales", "Transactions"}`
 
 
 * **Parameter Trend Metrics**: Used for time-series analysis to switch the focus between Revenue, Volume, or Footfall.
 * **Logic**: `{"Total Sales", "Transactions", "Customers"}`



---

### Data & Column Logics:

* **Dynamic Time Segmentation**: The **Hour Group** logic allows DailyBrew to visualize peak demand periods. This is essential for a coffee business to correlate staff levels with high-traffic "Morning Rush" periods.
* **Quintile-Based RFM**: By utilizing `PERCENTILEX.INC` for scoring, the model automatically adjusts to the scale of DailyBrew's customer base, ensuring that "Champions" are always the top 20% of the currently active customers.
* **Field Parameter Efficiency**: The use of **Field Parameters** significantly reduces the number of report pages needed, as a single chart can serve multiple analytic purposes (e.g., viewing both Sales trends and Customer growth).
