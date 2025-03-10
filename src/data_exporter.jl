
function magic_data(output_directory)
    if !isabspath(output_directory)
        output_directory = abspath(output_directory)
    end

    if !isdir(output_directory)
        mkpath(output_directory)
    end

    cp(joinpath(@__DIR__, "magic_data","labor_tax_rates.csv"), joinpath(output_directory, "labor_tax_rates.csv"))
    cp(joinpath(@__DIR__, "magic_data","capital_tax_rates.csv"), joinpath(output_directory, "capital_tax_rates.csv"))

end



"""
    download_save_data(census_api_key, bea_api_key, years, output_directory; states = STATES)

Download and save the CPS and BEA data to the output directory.

## Arguments

- `census_api_key` - The Census API key. Request an API key from the [Census website](https://api.census.gov/data/key_signup.html)
- `bea_api_key` - The BEA API key. Request an API key from the [BEA website](https://apps.bea.gov/api/signup/)
- `years` - The years to pull data for, as a range 2000:2023
- `output_directory` - The directory to save the data

## Optional Arguments

- `states` - A DataFrame with the state FIPS and abbreviations. Default is `STATES`.
"""
function download_save_data(
        census_api_key, 
        bea_api_key, 
        years,
        output_directory; 
        states = STATES
    )

    census_data = load_cps_data_api(census_api_key, years; states = states)

    bea_data = cps_vs_nipa_income_categories(census_data[:income], bea_api_key, years)

    save_cps_data(census_data, bea_data, output_directory, years)
    magic_data(output_directory)
end

"""
    save_cps_data(census_data, bea_data, output_directory)

Save the CPS and BEA data to the output directory.

## Arguments

- `census_data` - A DataFrame with the CPS data
- `bea_data` - A DataFrame with the BEA data
- `output_directory` - The directory to save the data
"""
function save_cps_data(census_data, bea_data, output_directory, years)
    if !isabspath(output_directory)
        output_directory = abspath(output_directory)
    end

    if !isdir(output_directory)
        mkpath(output_directory)
    end

    year_range = "$(minimum(years))_$(maximum(years))"

    CSV.write(joinpath(output_directory,"cps_asec_income_totals_$year_range.csv"), census_data[:income])
    CSV.write(joinpath(output_directory,"cps_asec_income_shares_$year_range.csv"), census_data[:shares])
    CSV.write(joinpath(output_directory,"cps_asec_income_counts_$year_range.csv"), census_data[:count])
    CSV.write(joinpath(output_directory,"cps_asec_numberhh_$year_range.csv"), census_data[:numhh])
    CSV.write(joinpath(output_directory,"cps_vs_nipa_income_categories_$year_range.csv"), bea_data)
end