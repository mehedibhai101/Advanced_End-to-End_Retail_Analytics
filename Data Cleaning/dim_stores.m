let
    // Extracted the data from the Dataset folder.
    Source = Folder.Files("your_folder_path"),

    // Loaded the Store Lookup CSV file.
    #"Store CSV" = Source{
        [#"Folder Path"="your_folder_path", Name="Store Lookup.csv"]
    }[Content],

    // Imported the CSV file and defined its structure.
    #"Imported CSV" = Csv.Document(
        #"Store CSV",
        [Delimiter = ",", Columns = 11, Encoding = 1252, QuoteStyle = QuoteStyle.None]
    ),

    // Promoted the first row to headers for proper column identification.
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),

    // Trimmed extra spaces from all text fields to ensure data consistency.
    #"Trimmed Text" = Table.TransformColumns(
        #"Promoted Headers",
        {
            {"store_id", Text.Trim, type text},
            {"store_type", Text.Trim, type text},
            {"store_square_feet", Text.Trim, type text},
            {"store_address", Text.Trim, type text},
            {"store_city", Text.Trim, type text},
            {"store_state_province", Text.Trim, type text},
            {"store_postal_code", Text.Trim, type text},
            {"store_longitude", Text.Trim, type text},
            {"store_latitude", Text.Trim, type text},
            {"manager", Text.Trim, type text},
            {"Neighorhood", Text.Trim, type text}
        }
    ),

    // Changed the data types of all columns for accurate data modeling.
    #"Changed Type" = Table.TransformColumnTypes(
        #"Trimmed Text",
        {
            {"store_id", Int64.Type},
            {"store_type", type text},
            {"store_square_feet", Int64.Type},
            {"store_address", type text},
            {"store_city", type text},
            {"store_state_province", type text},
            {"store_postal_code", Int64.Type},
            {"store_longitude", type number},
            {"store_latitude", type number},
            {"manager", Int64.Type},
            {"Neighorhood", type text}
        }
    ),

    // Selected only the relevant columns required for analysis.
    #"Selected Columns" = Table.SelectColumns(#"Changed Type",{"store_id", "store_type", "store_square_feet", "store_address", "store_city", "store_longitude", "store_latitude", "manager"}),

    // Capitalized the first letter of each word in the store type.
    #"Capitalized Text" = Table.TransformColumns(
        #"Selected Columns",
        {{"store_type", Text.Proper, type text}}
    ),
    #"Merged Columns" = Table.CombineColumns(#"Capitalized Text",{"store_address", "store_city"},Combiner.CombineTextByDelimiter(", ", QuoteStyle.None),"Location"),

    // Renamed columns to more user-friendly names.
    #"Renamed Columns" = Table.RenameColumns(
        #"Merged Columns",
        {
            {"store_id", "Store ID"},
            {"store_type", "Store Type"},
            {"store_square_feet", "Area(SqFt)"},
            {"store_longitude", "Longitude"},
            {"store_latitude", "Latitude"},
            {"manager", "Manager"}
        }
    ),

// Added a custom column to create a descriptive store name using the Store ID.
#"Added a New Column" = 
    Table.AddColumn(
        #"Renamed Columns", 
        "Store Name", 
        each Text.Combine({"Store ", Text.From([Store ID], "en-US")}), 
        type text
    ),

// Reordered columns to follow a logical sequence.
#"Reordered Columns" = 
    Table.ReorderColumns(
        #"Added a New Column",
        {"Store ID", "Store Name", "Store Type", "Area(SqFt)", "Location", "Longitude", "Latitude", "Manager"}
    )

in
    #"Reordered Columns"
