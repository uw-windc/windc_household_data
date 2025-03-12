"""
    fetch_commuting_data(output_directory; year = 2020, file_name = "table1.xlsx", output_name = file_name)

Download the commuting data from the Census Bureau website.

## Arguments

- `output_directory` - The directory to save the data.

## Optional Arguments

- `year` - The year to pull the data for. Default is 2020. The commuting data
    is released every 5 years, this is the most recent year or release.
- `file_name` - The name of the file to download. Default is "table1.xlsx".
- `output_name` - The name of the file to save the data as. Default is the same
    as `file_name`.

## Returns 

The path to the downloaded file.
"""
function fetch_commuting_data(output_directory; year = 2020, file_name = "table1.xlsx", output_name = file_name)
    url = "https://www2.census.gov/programs-surveys/demo/tables/metro-micro/$year/commuting-flows-$year/$file_name"

    if !isabspath(output_directory)
        output_directory = abspath(output_directory)
    end

    if !isdir(output_directory)
        mkpath(output_directory)
    end

    output_path = joinpath(output_directory, output_name)

    Base.download(url, output_path)
end

"""
    read_commuting_data(file_path; states = STATES)

Read the commuting data from the given file path. Download the commuting data 
with the [`fetch_commuting_data`](@ref) function.
"""
function read_commuting_data(file_path; states = STATES)
    col_names = ["home_fips","home_cntyfips","home_state","home_county",
                    "work_fips","work_cntyfips","work_state","work_county",
                    "workers","error"]

    return XLSX.readxlsx(file_path) |>
        x -> x["Table 1"][:] |>
        x -> DataFrame(x[9:end-4,:], col_names) |>
        x -> groupby(x, [:home_state, :work_state]) |>
        x -> combine(x, :workers => sum => :workers) |>
        x -> innerjoin(
            x,
            states,
            on = :home_state => :state_name
        ) |>
        x -> select(x, :state_abbr => :home_state, :work_state, :workers) |>
        x -> innerjoin(
            x,
            states,
            on = :work_state => :state_name
        ) |>
        x -> select(x, :home_state, :state_abbr=>:work_state, :workers)
end

"""
    cps_wages(census_data::DataFrame; year = 2020)

Compute the wages from the CPS data by state and year.

## Arguments

- `census_data` - The CPS data from the API or a CSV file, output from 
  [`load_cps_data_api`](@ref).
- `year` - The year to pull the data for. Default is 2020. The commuting data
    is released every 5 years, this is the most recent year or release.
"""
function cps_wages(census_data::DataFrame; year = 2020)
    census_data |>
        x -> subset(x, 
            :year => ByRow(==(year)),
            :source => ByRow(==("hwsval")),
        ) |>
        x -> cps_income(x) |>
        x -> rename(x, :value => :income) |>
        x -> innerjoin(
            x,
            cps_number_households(census_data),
            on = [:hh, :state, :year]
        ) |>
        x -> groupby(x, [:year, :state]) |>
        x -> combine(x,
            [:income, :value] => ((i,v) -> sum(i)/(sum(v)*1e6)) => :value
        ) |>
        x -> select(x, :state, :value)
end

"""
    acs_commuting(raw_commuting::DataFrame, wages::DataFrame)

Compute the commuting data from the ACS data and the wages data.

## Arguments

- `raw_commuting` - The raw commuting data from the ACS, output from 
  [`read_commuting_data`](@ref).
- `wages` - The wages data from the CPS data, output from [`cps_wages`](@ref).

"""
function acs_commuting(raw_commuting::DataFrame, wages::DataFrame)
    return innerjoin(
            raw_commuting,
            wages,
            on = :home_state => :state
        ) |>
        x -> transform(x,
            [:workers, :value] => ByRow((w,v) -> w*v) => :value
        ) |>
        x -> select(x, :home_state, :work_state, :value)
end

"""
    get_acs_commuting_data(census_data; year = 2020, file_name = "table1.xlsx")

Download the ACS data and compute the commuting data.

## Arguments

- `census_data` - The CPS data from the API or a CSV file, output from 
  [`load_cps_data_api`](@ref).

## Optional Arguments

- `year` - The year to pull the data for. Default is 2020. The commuting data
    is released every 5 years, this is the most recent year or release.
- `file_name` - The name of the file to download. Default is "table1.xlsx".
"""
function get_acs_commuting_data(census_data; year = 2020, file_name = "table1.xlsx")
    file_path = fetch_commuting_data("data/commuting", year = year, file_name = file_name)
    acs =  read_commuting_data(file_path)

    rm(file_path)

    wages = cps_wages(census_data; year = year)

    return acs_commuting(acs, wages)

end