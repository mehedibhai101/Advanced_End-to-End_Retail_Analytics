let
    Source = {0..86399},
    #"Converted to Table" = Table.FromList(Source, Splitter.SplitByNothing(), null, null, ExtraValues.Error),
    #"Divided Column" = Table.TransformColumns(#"Converted to Table", {{"Column1", each _ / 86400, type number}}),
    #"Changed Type" = Table.TransformColumnTypes(#"Divided Column",{{"Column1", type time}}),
    #"Renamed Columns" = Table.RenameColumns(#"Changed Type",{{"Column1", "Time"}}),
    #"Inserted Hour" = Table.AddColumn(#"Renamed Columns", "Hour", each Time.Hour([Time]), Int64.Type)
in
    #"Inserted Hour"
