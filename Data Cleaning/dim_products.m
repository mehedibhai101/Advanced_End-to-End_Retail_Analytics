let
    // Extracted the data from Dataset folder.
    Source = Folder.Files("your_folder_path"),

    // Loaded the Product Lookup CSV file.
    #"C:\Users\perennial\OneDrive\PBI Final Assessment\Dataset\_Product Lookup csv" = 
        Source{[#"Folder Path"="your_folder_path", Name="Product Lookup.csv"]}[Content],

    // Imported the CSV file and defined its structure.
    #"Imported CSV" = Csv.Document(#"C:\Users\perennial\OneDrive\PBI Final Assessment\Dataset\_Product Lookup csv",
        [Delimiter = ",", Columns = 14, Encoding = 1252, QuoteStyle = QuoteStyle.None]),

    // Promoted first row to headers for proper column identification.
    #"Promoted Headers" = Table.PromoteHeaders(#"Imported CSV", [PromoteAllScalars = true]),

    // Trimmed extra spaces from text fields to ensure data consistency.
    #"Trimmed Text" = Table.TransformColumns(#"Promoted Headers", {
        {"product_id", Text.Trim, type text}, 
        {"product_group", Text.Trim, type text}, 
        {"product_category", Text.Trim, type text}, 
        {"product_type", Text.Trim, type text}, 
        {"product", Text.Trim, type text}, 
        {"product_description", Text.Trim, type text}, 
        {"unit_of_measure", Text.Trim, type text}, 
        {"current_cost", Text.Trim, type text}, 
        {"current_wholesale_price", Text.Trim, type text}, 
        {"current_retail_price", Text.Trim, type text}, 
        {"tax_exempt_yn", Text.Trim, type text}, 
        {"promo_yn", Text.Trim, type text}, 
        {"new_product_yn", Text.Trim, type text}, 
        {"", Text.Trim, type text}
    }),

    // Capitalized each word in relevant columns to maintain proper naming format.
    #"Capitalized Each Word" = Table.TransformColumns(#"Trimmed Text", {
        {"product_group", Text.Proper, type text}, 
        {"product_category", Text.Proper, type text}, 
        {"product_type", Text.Proper, type text}, 
        {"product", Text.Proper, type text}
    }),

    // Changed data types of all columns for accurate data modeling.
    #"Changed Type" = Table.TransformColumnTypes(#"Capitalized Each Word", {
        {"product_id", Int64.Type}, 
        {"product_group", type text}, 
        {"product_category", type text}, 
        {"product_type", type text}, 
        {"product", type text}, 
        {"product_description", type text}, 
        {"unit_of_measure", type text}, 
        {"current_cost", type number}, 
        {"current_wholesale_price", type number}, 
        {"current_retail_price", type number}, 
        {"tax_exempt_yn", type text}, 
        {"promo_yn", type text}, 
        {"new_product_yn", type text}, 
        {"", Int64.Type}
    }),

    // Added a new column to standardize product name with default 'Rg' where not specified.
    #"Added Custom Column" = Table.AddColumn(#"Changed Type", "product new name", 
        each if Text.EndsWith([product], "Lg") 
            or Text.EndsWith([product], "Sm") 
            or Text.EndsWith([product], "Rg")
        then [product]
        else [product] & " Rg",
        type text
    ),

    // Split product new name column into name and size.
    #"Split Column by Delimiter" = Table.SplitColumn(#"Added Custom Column", 
        "product new name", 
        Splitter.SplitTextByEachDelimiter({" "}, QuoteStyle.Csv, true), 
        {"product new name.1", "product new name.2"}
    ),

    // Added a new column to update product names by appending the category name when missing, preventing potential misidentification.
    #"Updated Product Name" = 
    Table.AddColumn(
        #"Split Column by Delimiter", 
        "Updated Product Name", 
        each 
            let
                _ProductValue = [product new name.1],
                _CategoryValue = [product_category],
                _CategoryList = {"Loose Tea", "Coffee Beans", "Packaged Chocolate", "Coffee", "Tea", "Drinking Chocolate"},
                _ProductHasCategory = List.AnyTrue(List.Transform(_CategoryList, each Text.Contains(_ProductValue, _)))
            in
                if List.Contains(_CategoryList, _CategoryValue) and not _ProductHasCategory then
                    _ProductValue & " " & _CategoryValue
                else
                    _ProductValue
    ),

    // Replaced text values to make columns more descriptive.
    #"Replaced Values1" = Table.TransformColumns(#"Updated Product Name", {
        {"promo_yn", each if _ = "Y" then "Promo" else if _ = "N" then "Regular" else _, type text},
        {"tax_exempt_yn", each if _ = "Y" then "Tax Exempt" else if _ = "N" then "Taxable" else _, type text},
        {"new_product_yn", each if _ = "Y" then "New" else if _ = "N" then "Existing" else _, type text},
        {"product new name.2", each if _ = "Rg" then "Regular" else if _ = "Lg" then "Large" else if _ = "Sm" then "Small" else _, type text}
    }),

    // Corrected inconsistent or misspelled product names.
    #"Replaced Values2" =
    Table.TransformColumns(#"Replaced Values1", {
        {"Updated Product Name", 
        each if _ = "Jamacian Coffee River" then "Jamaican Coffee River" 
        else if _ = "Ouro Brasileiro Shot Promo Coffee" then "Ouro Brasileiro Shot Coffee" 
        else if _ = "Dark Chocolate Packaged Chocolate" then "Dark Packaged Chocolate" 
        else if _ = "Dark Chocolate Drinking Chocolate" then "Dark Drinking Chocolate" 
        else if _ = "Snow Day Hot Chocolate Drinking Chocolate" then "Snow Day Hot Drinking Chocolate" 
        else if _ = "Happy Holidays Hot Chocolate Drinking Chocolate" then "Happy Holidays Hot Drinking Chocolate" 
        else _, type text}
    }),

    // Kept only relevant columns for analysis.
    #"Removed Other Columns" = Table.SelectColumns(#"Replaced Values2",{"product_id", "product_group", "product_category", "product_type", "current_cost", "current_retail_price", "tax_exempt_yn", "new_product_yn", "product new name.2", "Updated Product Name"}),
    // Renamed columns for better readability.
    #"Renamed Columns" = Table.RenameColumns(#"Removed Other Columns", {
        {"product_id", "Product ID"}, 
        {"product_group", "Product Group"}, 
        {"product_category", "Category"}, 
        {"product_type", "Type"}, 
        {"current_cost", "Cost"}, 
        {"current_retail_price", "Price"}, 
        {"tax_exempt_yn", "Tax Status"}, 
        {"new_product_yn", "Product Status"}, 
        {"Updated Product Name", "Product Name"}, 
        {"product new name.2", "Size"}
    }),

    // Trimmed spaces from product name to ensure consistency.
    #"Trimmed Product Name" = Table.TransformColumns(#"Renamed Columns", {{"Product Name", Text.Trim, type text}}),

    // Reordered columns to maintain a logical sequence.
    #"Reordered Columns" = Table.ReorderColumns(#"Trimmed Product Name",
        {"Product ID", "Product Group", "Category", "Type", "Product Name", 
        "Size", "Cost", "Price", "Tax Status", "Product Status"}
    )
in
    #"Reordered Columns"
