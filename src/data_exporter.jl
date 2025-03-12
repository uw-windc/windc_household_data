"""
    magic_data(output_directory)

Copy the files from the `magic_data` directory to the output directory. This copies
two files, `labor_tax_rates.csv` and `capital_tax_rates.csv` which are created
in the `SAGE` model.
"""
function magic_data(output_directory)
    if !isabspath(output_directory)
        output_directory = abspath(output_directory)
    end

    if !isdir(output_directory)
        mkpath(output_directory)
    end

    cp(joinpath(@__DIR__, "magic_data","labor_tax_rates.csv"), joinpath(output_directory, "labor_tax_rates.csv"); force=true)
    cp(joinpath(@__DIR__, "magic_data","capital_tax_rates.csv"), joinpath(output_directory, "capital_tax_rates.csv"); force=true)

end



"""
    download_save_data(census_api_key, bea_api_key, years, output_directory; states = STATES)

Download and save the CPS and BEA data to the output directory.

## Arguments

- `census_api_key` - The Census API key. Request an API key from the [Census website](https://api.census.gov/data/key_signup.html)
- `bea_api_key` - The BEA API key. Request an API key from the [BEA website](https://apps.bea.gov/api/signup/)
- `years` - The years to pull data for, as a range 2000:2023
- `output_root_directory` - The directory to save the data

## Optional Arguments

- `states` - A DataFrame with the state FIPS and abbreviations. Default is `STATES`.
"""
function download_save_data(
        census_api_key, 
        bea_api_key, 
        years,
        output_root_directory; 
        states = STATES
    )

    
    ## CPS
    census_data = load_cps_data_api(census_api_key, years; states = states)
    bea_data = get_bea_nipa_data(bea_api_key, years)
    

    cps_path = joinpath(output_root_directory, "cps")
    save_cps_data(census_data, bea_data, cps_path)
    magic_data(cps_path)
    

    ## Health Care
    health_tmp_dir = joinpath(output_root_directory, "health_care", "tmp")
    cms = get_cms_data(health_tmp_dir; states = states)
    rm(health_tmp_dir, recursive=true)
    cms = extrapolate_cms_data(cms, years)

    acs = get_census_health_data(census_api_key, years)

    public_health = public_health_benefits(cms, acs)


    health_path = joinpath(output_root_directory, "health_care")
    save_public_health_benefits_data(public_health, health_path)

    ## ACS Commuting Data
    #income = cps_income(census_data)
    #numhh = cps_number_households(census_data)
    
end

"""
    save_cps_data(census_data, bea_data, output_directory)

Save the CPS and BEA data to the output directory.

## Arguments

- `census_data` - A DataFrame with the CPS data
- `bea_data` - A DataFrame with the BEA data
- `output_directory` - The directory to save the data
"""
function save_cps_data(census_data, bea_data, output_directory)
    if !isabspath(output_directory)
        output_directory = abspath(output_directory)
    end

    if !isdir(output_directory)
        mkpath(output_directory)
    end

    income = cps_income(census_data)
    numhh = cps_number_households(census_data)
    shares = cps_income_shares(census_data)
    count = cps_count_observations(census_data)

    nipa_data = cps_vs_nipa_income_categories(income, bea_data)

    create_nipa_windc(bea_data, :capital) |>
        x -> transform(x,
            [:nipa, :windc] => ByRow((n,w) -> n/w) => :domestic_share
        ) |>
        x -> select(x, [:year, :nipa, :windc, :domestic_share]) |>
        x -> CSV.write(
            joinpath(output_directory,"windc_vs_nipa_domestic_capital.csv"), 
            x
        )
    

    CSV.write(joinpath(output_directory,"cps_asec_income_totals.csv"), income)
    CSV.write(joinpath(output_directory,"cps_asec_income_shares.csv"), shares)
    CSV.write(joinpath(output_directory,"cps_asec_income_counts.csv"), count)
    CSV.write(joinpath(output_directory,"cps_asec_numberhh.csv"), numhh)
    CSV.write(joinpath(output_directory,"cps_vs_nipa_income_categories.csv"), nipa_data)
end

"""
    save_public_health_benefits_data(health::DataFrame, output_directory)

Save the public health benefits data to the output directory.
"""
function save_public_health_benefits_data(health::DataFrame, output_directory)
    if !isabspath(output_directory)
        output_directory = abspath(output_directory)
    end

    if !isdir(output_directory)
        mkpath(output_directory)
    end

    CSV.write(joinpath(output_directory,"public_health_benefits.csv"), health)

end