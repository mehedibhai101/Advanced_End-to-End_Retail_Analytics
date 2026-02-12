let
    // 1. Setup: Define the date range based on your existing fact table
    // Ensure "Clean_Ingredients_List" matches your sales query's final step
    Start_Date = Number.From(List.Min(#"table_name"[date_column])),
    End_Date = Number.From(List.Max(#"table_name"[date_column])),
    
    // 2. Generate: Create a continuous list and convert to table
    Date_List = {Start_Date..End_Date},
    Table_From_List = Table.FromList(Date_List, Splitter.SplitByNothing(), {"Date"}, null, ExtraValues.Error),
    Date_Type_Fixed = Table.TransformColumnTypes(Table_From_List, {{"Date", type date}}),

    // 3. Enrichment: Add calendar attributes
    Add_Year = Table.AddColumn(Date_Type_Fixed, "Year", each Date.Year([Date]), Int64.Type),
    Add_Quarter = Table.AddColumn(Add_Year, "Quarter", each "Q" & Text.From(Date.QuarterOfYear([Date])), type text),
    Add_Month_No = Table.AddColumn(Add_Quarter, "Month_No", each Date.Month([Date]), Int64.Type),
    Add_Month_Name = Table.AddColumn(Add_Month_No, "Month_Name", each Date.ToText([Date], "MMM"), type text),
    Add_Month_Year = Table.AddColumn(Add_Month_Name, "Month_Year", each Date.ToText([Date], "MMM-yyyy"), type text),

    // 5. Day Metrics: Extract day names and numbers
    Add_Day_No = Table.AddColumn(Add_Month_Year, "Day", each Date.Day([Date]), Int64.Type),
    Add_Week_Day_No = Table.AddColumn(Add_Day_No, "Week_Day_No", each Date.DayOfWeek([Date]), Int64.Type),
    Add_Day_Name = Table.AddColumn(Add_Week_Day_No, "Day_Name", each Date.ToText([Date], "ddd"), type text),

    // 6. Logic: Categorize Weekdays vs Weekends
    Add_Day_Type = Table.AddColumn(Add_Day_Name, "Day_Type", each 
        if List.Contains({0, 6}, [Week_Day_No]) then "Weekend" else "Weekday", type text)
in
    Add_Day_Type
