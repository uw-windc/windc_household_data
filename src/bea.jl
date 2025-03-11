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
    cps_vs_nipa_income_categories(income::DataFrame, api_key::String, years)

Return a comparison between CPS and NIPA income categories.

## Arguments

- `income` - A DataFrame with the CPS income data
- `api_key` - Request an API key from the [BEA website](https://apps.bea.gov/api/signup/)
- `years` - The years to pull data for, as a range 2000:2023

## Returns

A DataFrame with the columns `year`, `nipa`, `cps`, `pct_diff`, and `category`.
"""
function cps_vs_nipa_income_categories(income::DataFrame, bea_data::DataFrame, years)

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
        x -> innerjoin(
            x,
            line_to_source,
            on = :source => :source
        ) |>
        x -> groupby(x, [:year, :LineNumber, :category]) |>
        x -> combine(x, :value => sum => :cps) 

    output = bea_data  |>
        x -> innerjoin(
            x,
            cps_totals,
            on = [:year, :LineNumber]
        ) |>
        #x -> select(x, Not(:LineNumber)) |>
        
        x -> transform(x,
            [:nipa, :cps] => ByRow((n,c) -> 100*(c/n-1)) => :pct_diff
        ) |>
        x -> select(x, :year, :nipa, :LineNumber, :cps, :pct_diff, :category)

    return output

end

function cps_vs_nipa_income_categories(income::DataFrame, api_key::String, years)

    bea_data = get_bea_nipa_data(api_key, years)

    return cps_vs_nipa_income_categories(income::DataFrame, bea_data::DataFrame, years)

end


"""
    create_nipa_windc(bea_data::DataFrame, type::Symbol)

Create a DataFrame comparing the WiNDC vs NIPA data. This uses two magic files,
`ld0_windc.csv` and `kd0_windc.csv` to create the comparison.

## Arguments

- `bea_data` - A DataFrame with the NIPA data
- `type` - Either `:labor` or `:capital`
"""
function create_nipa_windc(bea_data, type)
    @assert type∈[:labor, :capital] "type must be either :labor or :capital"

    file_name = type==:labor ? "ld0_windc.csv" : "kd0_windc.csv"
    categories = type==:labor ? ["2"] : ["9","12","13"]

    kd0 = CSV.read(
        joinpath(@__DIR__, "magic_data", file_name),
        DataFrame,
        header = [:year, :state, :good, :windc],
        skipto = 2
    ) |>
    x -> groupby(x, [:year]) |>
    x -> combine(x, :windc => (y -> 1e9*sum(y)) => :windc) 

    windc = bea_data |>
        x -> subset(x, 
            :LineNumber => ByRow(∈(categories))
        ) |>
        x -> groupby(x, [:year]) |>
        x -> combine(x, :nipa => sum => :nipa) |>
        x -> leftjoin(
            x,
            kd0,
            on = [:year],
        ) |>    
        x -> transform(x,
            [:windc,:nipa] => ByRow((w,n) -> 100*(w/n - 1)) => :pct_diff,
            :windc => ByRow(y -> type) => :category
        )  
    
    return windc

end

