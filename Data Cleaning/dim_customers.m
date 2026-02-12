let
    // Extracted the data from the Dataset folder.
    Source = Folder.Files("your_folder_path"),

    // Loaded the Customer Lookup CSV file.
    #"Customer CSV" = Source{
        [#"Folder Path"="your_folder_path", Name="Customer Lookup.csv"]
    }[Content],

    // Imported the CSV file and defined its structure.
    #"Imported CSV" = Csv.Document(
        #"Customer CSV",
        [Delimiter = ",", Columns = 9, Encoding = 1252, QuoteStyle = QuoteStyle.None]
    ),

    // Promoted the first row to headers for proper column identification.
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),

    // Trimmed extra spaces from text fields to ensure data consistency.
    #"Trimmed Text" = Table.TransformColumns(
        #"Promoted Headers",
        {
            {"customer_id", Text.Trim, type text},
            {"home_store", Text.Trim, type text},
            {"customer_first-name", Text.Trim, type text},
            {"customer_email", Text.Trim, type text},
            {"customer_since", Text.Trim, type text},
            {"loyalty_card_number", Text.Trim, type text},
            {"birthdate", Text.Trim, type text},
            {"gender", Text.Trim, type text},
            {"birth_year", Text.Trim, type text}
        }
    ),

    // Changed data types of all columns for accurate data modeling.
    #"Changed Type" = Table.TransformColumnTypes(
        #"Trimmed Text",
        {
            {"customer_id", Int64.Type},
            {"home_store", Int64.Type},
            {"customer_first-name", type text},
            {"customer_email", type text},
            {"customer_since", type date},
            {"loyalty_card_number", type text},
            {"birthdate", type date},
            {"gender", type text}
        }
    ),
    #"Replaced Value" = Table.ReplaceValue(#"Changed Type","Not Specified","N/A",Replacer.ReplaceText,{"gender"}),

    // Added a new column to calculate age based on birthdate and customer start date.
    #"Calculated Age" = Table.AddColumn(
        #"Replaced Value",
        "Age",
        each Duration.Days([customer_since] - [birthdate]) / 365,
        type number
    ),
    // Rounded off each customer's age
    #"Rounded Off" = Table.TransformColumns(#"Calculated Age",{{"Age", each Number.Round(_, 0), type number}}),

    // Kept only relevant columns for analysis.
    #"Selected Columns" = Table.SelectColumns(
        #"Rounded Off",
        {"customer_id", "home_store", "customer_first-name", "customer_email", "customer_since", "loyalty_card_number", "gender", "Age"}
    ),

    // Renamed columns for better readability.
    #"Renamed Columns" = Table.RenameColumns(
        #"Selected Columns",
        {
            {"customer_id", "Customer ID"},
            {"home_store", "Home Store"},
            {"customer_first-name", "Name"},
            {"customer_email", "E-mail"},
            {"customer_since", "Customer Since"},
            {"loyalty_card_number", "Loyalty Card Number"},
            {"gender", "Gender"}
        }
    ),

    // Converted all email addresses to lowercase for uniformity.
    #"Lowercased Text" = Table.TransformColumns(
        #"Renamed Columns",
        {{"E-mail", Text.Lower, type text}}
    ),

    // Excluded the row for Customer ID 5937 due to the absence of any sales records.
    #"Removed Row" = Table.SelectRows(#"Lowercased Text", each [Customer ID] <> 5937)
    
in
    #"Removed Row"
