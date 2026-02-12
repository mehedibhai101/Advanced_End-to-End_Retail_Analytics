let
    // Extracted the data from the Dataset folder.
    Source = Folder.Files("your_folder_path"),

    // Loaded the Employee Lookup CSV file.
    #"Employee CSV" = Source{
        [#"Folder Path"="your_folder_path", Name="Employee Lookup.csv"]
    }[Content],

    // Imported the CSV file and defined its structure.
    #"Imported CSV" = Csv.Document(
        #"Employee CSV",
        [Delimiter = ",", Columns = 6, Encoding = 1252, QuoteStyle = QuoteStyle.None]
    ),

    // Promoted the first row to headers for proper column identification.
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),

    // Trimmed extra spaces from all text fields to ensure data consistency.
    #"Trimmed Text" = Table.TransformColumns(
        #"Promoted Headers",
        {
            {"staff_id", Text.Trim, type text},
            {"first_name", Text.Trim, type text},
            {"last_name", Text.Trim, type text},
            {"position", Text.Trim, type text},
            {"start_date", Text.Trim, type text},
            {"location", Text.Trim, type text}
        }
    ),
    #"Capitalized Each Word" = Table.TransformColumns(#"Trimmed Text",{{"last_name", Text.Proper, type text}, {"first_name", Text.Proper, type text}}),

    // Changed the data types of all columns for accurate data modeling.
    #"Changed Type" = Table.TransformColumnTypes(
        #"Capitalized Each Word",
        {
            {"staff_id", Int64.Type},
            {"first_name", type text},
            {"last_name", type text},
            {"position", type text},
            {"start_date", type date},
            {"location", type text}
        }
    ),

    // Combined the "last_name" and "first_name" columns into a single "Name" column.
    #"Merged Columns" = Table.CombineColumns(
        #"Changed Type",
        {"first_name", "last_name"},
        Combiner.CombineTextByDelimiter(" ", QuoteStyle.None),
        "Name"
    ),

    // Renamed columns to more user-friendly names.
    #"Renamed Columns" = Table.RenameColumns(
        #"Merged Columns",
        {
            {"staff_id", "Staff ID"},
            {"position", "Position"},
            {"start_date", "Start Date"},
            {"location", "Location"}
        }
    )
in
    #"Renamed Columns"
