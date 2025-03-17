"""
    fetch_soi_data(output_directory::String, year::Int)

Fetch the SOI data for the given year and save it to the output directory. Only
years 2014 to 2017 are available.
"""
function fetch_soi_data(output_directory::String, year::Int)

    @assert year∈2014:2017 "SOI data only available from 2014 to 2017"


    if !isabspath(output_directory)
        output_directory = abspath(output_directory)
    end

    if !isdir(output_directory)
        mkpath(output_directory)
    end

    truncate_year = year - 2000

    url = "https://www.irs.gov/pub/irs-soi/$(truncate_year)in54cmcsv.csv"

    output_path = joinpath(output_directory, "$(truncate_year)in54cmcsv.csv")

    Base.download(url, output_path)
end

"""
    clean_soi_data(directory, year)

Load and clean the SOI data for the given year. The data is cleaned by stacking
the columns and removing commas from the values.
"""
function clean_soi_data(directory, year)
    truncate_year = year - 2000

    df_year = CSV.read(joinpath(directory,"$(truncate_year)in54cmcsv.csv"), DataFrame) |>
        x -> stack(x, Not(:STATE, :AGI_STUB), variable_name = :soicat, value_name = :value) |>
        x -> transform(x,
            :STATE => ByRow(y -> year) => :year,
            :value => ByRow(y -> parse(Int, replace(y, "," => ""))) => :value
        ) |>
        x -> select(x, :year, :STATE => :r, :AGI_STUB => :h, :soicat, :value) 

    return df_year
end

"""
    load_soi_data(directory, years)

Load the SOI data for the given years and return a DataFrame.
"""
function load_soi_data(directory, years)

    df = DataFrame()
    for year in years
        df_year = clean_soi_data(directory, year)
        df = vcat(df, df_year)
    end

    return df

end

"""
    soi_data(output_directory; years = 2014:2017, file_name = "soi_income_totals.csv")

Fetch and load the SOI data for the given years and save it to a CSV file.

This is the main function to call to get the SOI data. It will fetch the data
for the given years, clean it, and save it to a CSV file.
"""
function soi_data(output_directory; years = 2014:2017, file_name = "soi_income_totals.csv")

    tmp_dir = mktempdir()
    for year in years
        fetch_soi_data(tmp_dir, year)
    end

    df = load_soi_data(tmp_dir, years)


    if !isabspath(output_directory)
        output_directory = abspath(output_directory)
    end

    if !isdir(output_directory)
        mkpath(output_directory)
    end

    output_path = joinpath(output_directory, file_name)

    CSV.write(output_path, df)


end