"""
    get_bea_nipa_data(bea_key::String, years)

Get NIPA data from the BEA API for the given years.

## Arguments

- `bea_key` - Request an API key from the [BEA website](https://apps.bea.gov/api/signup/)
- `years` - The years to pull data for, as a range 2001:2024 -> These are +1 for some reason

# Returns

A DataFrame with the NIPA data for the given years and columns `year`, 
`LineNumber`, and `nipa`.

## API query

    query = Dict(
        "UserID" => bea_key,
        "method" => "GetData",
        "datasetname" => "NIPA",
        "TableName" => "T20100",
        "Frequency" => "A",
        "Year" => join(years, ","),
        "ResultFormat" => "JSON"
    )
"""
function get_bea_nipa_data(bea_key::String, years)

    url = "http://apps.bea.gov/api/data/"

    query = Dict(
        "UserID" => bea_key,
        "method" => "GetData",
        "datasetname" => "NIPA",
        "TableName" => "T20100",
        "Frequency" => "A",
        "Year" => join(years, ","),
        "ResultFormat" => "JSON"
    )

    result = HTTP.get(url, query = query)

    response_text = String(result.body)
    data = JSON.parse(response_text);

    return DataFrame(data["BEAAPI"]["Results"]["Data"]) |>
                x -> rename(x, :TimePeriod => :year, :DataValue => :value) |>
                x -> transform(x,
                    :year => ByRow(y -> parse(Int, y)) => :year,
                    :value => ByRow(y -> 1e6*parse(Float64, replace(y, "," => "") )) => :nipa
                ) |>
                x -> select(x, :year, :LineNumber, :nipa)
end


"""
    cps_vs_nipa_income_categories(income::DataFrame, api_key, years)

Return a comparison between CPS and NIPA income categories.

## Arguments

- `income` - A DataFrame with the CPS income data
- `api_key` - Request an API key from the [BEA website](https://apps.bea.gov/api/signup/)
- `years` - The years to pull data for, as a range 2000:2023

## Returns

A DataFrame with the columns `year`, `nipa`, `cps`, `pct_diff`, and `category`.
"""
function cps_vs_nipa_income_categories(income::DataFrame, api_key, years)

    line_to_source = DataFrame(
        [
            ("1", "htotval", "total income"),
            ("3", "hwsval", "wages and salaries"),
            ("10", "hfrval", "proprietor's income: farm"),
            ("11", "hseval", "proprietor's income: non-farm"),
            ("12", "hrntval", "rental income"),
            ("14", "hintval", "personal interest income"),
            ("15", "hdivval", "personal dividend income"),
            ("18", "hssval", "government benefits: social security"),
            ("18", "hssival", "government benefits: social security"),
            ("18", "hdisval", "government benefits: social security"),
            ("21", "hucval", "government benefits: unemployment insurance"),
            ("22", "hvetval", "government benefits: veterans benefits"),
            ("23", "hwcval", "government benefits: other"),
            ("23", "hpawval", "government benefits: other"),
            ("23", "hsurval", "government benefits: other"),
            ("23", "hedval", "government benefits: other"),
            ("24", "hcspval", "non-government transfer income"),
            ("24", "hfinval", "non-government transfer income"),
            ("24", "hoival", "non-government transfer income")
        ],
        [:LineNumber, :source, :category]
    )


    cps_totals = income |>
        x -> groupby(x, [:year, :source]) |>
        x -> combine(x, :value => sum => :cps) |>
        x -> innerjoin(
            x,
            line_to_source,
            on = :source => :source
        ) |>
        x -> groupby(x, [:year, :LineNumber, :category]) |>
        x -> combine(x, :cps => sum => :cps) 

    bea_data = get_bea_nipa_data(api_key, years)  |>
        x -> innerjoin(
            x,
            cps_totals,
            on = [:year, :LineNumber]
        ) |>
        x -> select(x, Not(:LineNumber)) |>
        
        x -> transform(x,
            [:nipa, :cps] => ByRow((n,c) -> 100*(c/n-1)) => :pct_diff
        ) |>
        x -> select(x, :year, :nipa, :cps, :pct_diff, :category)

    return bea_data

end