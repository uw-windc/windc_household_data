"""
    get_cms_data(output;files_to_grab = (medicare = "MEDICARE_AGGREGATE20.CSV", medicaid = "MEDICAID_AGGREGATE20.CSV"))

Download and extract CMS a state health expediture by state of residence data. This
downloads a [ZIP file from the CMS website](https://www.cms.gov/research-statistics-data-and-systems/statistics-trends-and-reports/nationalhealthexpenddata/downloads/resident-state-estimates.zip).

## Arguments

- `output::String`: The directory to save the data to.

## Keyword Arguments

- `files_to_grab::Tuple`: A tuple of file names to extract from the ZIP file. The keys are the names of the files and the values are the names of the files in the ZIP file.

## Returns

A DataFrame with the following columns:

- `:state::String`: The state name.
- `:year::Int`: The year of the data.
- `:medicare::Float64`: The medicare spending.
- `:medicade::Float64`: The medicaid spending.
"""
function get_cms_data(
        output;
        files_to_grab = (medicare = "MEDICARE_AGGREGATE20.CSV", medicaid = "MEDICAID_AGGREGATE20.CSV"),
        states = STATES    
    )
    url = "https://www.cms.gov/research-statistics-data-and-systems/statistics-trends-and-reports/nationalhealthexpenddata/downloads/resident-state-estimates.zip"

    windc_household_data.fetch_zip_data(url, x -> x∈files_to_grab; output_path = output)

    df = DataFrame()
    for (key, path) in pairs(files_to_grab)
        df = vcat(
            df,
            CSV.read(joinpath(output, path), DataFrame) |>
                x -> subset(x,
                    :Code => ByRow(∈([1])),
                    :Group => ByRow(==("State"))
                ) |>
                x -> select(x, :State_Name => :state_name, Not(:Code, :Group, :State_Name, :Item, :Average_Annual_Percent_Growth, :Region_Number, :Region_Name)) |>
                x -> stack(x, Not(:state_name), variable_name = :year, value_name = :value) |>
                x -> transform(x, 
                    :year => ByRow(y -> parse(Int, replace(y, "Y"=> ""))) => :year,
                    :year => ByRow(y -> key) => :type
                ) 
        )
    end


    return df |> 
            x -> leftjoin(x, states, on = :state_name) |>
            x -> select(x, :state_abbr => :state, Not(:state_abbr, :state_name, :state_fips)) |>
            x -> unstack(x, :type, :value) |>
            x -> subset(x, :year => ByRow(>=(2000)))

end

"""
    extrapolate_cms_data_single_state(df, years)

Extrapolate CMS data to years that are not in the data. This uses a linear model to
extrapolate the data. Will filter `years` to be only years not present in data.

## Arguments

- `df::DataFrame`: The CMS data.
- `years::Vector{Int}`: All years needed in final data

## Returns

A DataFrame with the following columns:

- `:state::String`: The state name.
- `:year::Int`: The year of the data.
- `:medicare::Float64`: The medicare spending.
- `:medicade::Float64`: The medicade spending.
"""
function extrapolate_cms_data_single_state(df, years)
    state = df[1,:state]

    new_years = setdiff(years, df.year)
    
    X_medicaid = df |>
        x -> lm(@formula(medicaid ~ year), x)

    X_medicare = df |>
        x -> lm(@formula(medicare ~ year), x)

    df_new = DataFrame(
        state = [state for _ in new_years],
        year = new_years
    )

    df_new[!,:medicare] = predict(X_medicare, df_new)
    df_new[!,:medicaid] = predict(X_medicaid, df_new)

    return vcat(df, df_new)
end

function extrapolate_cms_data(cms::DataFrame, years)
    return groupby(cms , :state) |>
        x -> combine(x, (y -> extrapolate_cms_data_single_state(y, years)))
end

"""
    get_census_health_data_year(census_api_key, variables, year)

Get health data from the ACS for a single year. This function will return the data
for all states.

We only want estimated data, not MOE data. Will only return estimates.
"""
function get_census_health_data_year(census_api_key, variables, year; states = STATES)

    @assert year>=2009 "Data is only available from 2009 onward"

    function add_estimate_moe_to_var(var)
        return [var*"E"]
    end

    fixed_vars = Iterators.flatten(add_estimate_moe_to_var.(variables))

    var_string = "NAME,"*join(fixed_vars, ",")

    url = "https://api.census.gov/data/$year/acs/acs1"

    query = Dict(
        "get" => var_string,
        "for" => "state:*",
        "key" => census_api_key,
    )
    response = windc_household_data.HTTP.get(url, query = query)
    response_text = String(response.body)
    data = windc_household_data.JSON.parse(response_text)


    DataFrame([Tuple(row) for row in data[2:end]], data[1]) |>
        x -> stack(x, Not(:NAME, :state)) |>
        x -> transform(x,
            :variable => ByRow(y -> 
                    y[end] == 'E' ? (y[1:end-1], "estimate") : (y[1:end-1], "moe")
                ) => [:variable, :type],
            :NAME => ByRow(y -> year) => :year,
            :value => ByRow(y -> parse(Float64, y)) => :value
        ) |>
        x -> select(x, :NAME => :state_name, :variable, :type, :year, :value) |>
        x -> subset(x, :state_name => ByRow(!=("Puerto Rico"))) |>
        x -> leftjoin(x, states, on = :state_name) |>
        x -> select(x, :state_abbr => :state, Not(:state_abbr, :state_name, :state_fips)) 
    
end

"""
    get_census_health_data(census_api_key, years)

Get health data from the ACS for multiple years. This function will return the data
for all states.

Retrieves data from the following variables in the ACS 1 year survey:

    B27015_005
    B27015_010
    B27015_015
    B27015_020
    B27015_025

No data is available for 2020 due to low response rates. We will use the average of
2019 and 2021 data for 2020.

## Arguments

- `census_api_key::String`: The Census API key.
- `years::Vector{Int}`: The years to get the data, will filter to be >= 2009.
"""
function get_census_health_data(census_api_key, years; states = STATES)
    
    years = filter(x -> x>=2009, years)

    variables = [
        "B27015_005",
        "B27015_010",
        "B27015_015",
        "B27015_020",
        "B27015_025"
    ]

    df = DataFrame()
    for year in years
        if year == 2020
            continue
        end
        df = vcat(df, get_census_health_data_year(census_api_key, variables, year; states = states))
    end

    relabel = Dict(
        "B27015_005" => "<25k",
        "B27015_010" => "25-50k",
        "B27015_015" => "50-75k",
        "B27015_020" => "75-100k",
        "B27015_025" => ">100k"
    )

    # 2020 data is not available due to low response rates. We will use the 
    # average of 2019 and 2021 data.
    df = vcat(
        df,
        df |>
            x -> subset(x,
                :year => ByRow(∈([2019,2021]))
            ) |>
            x -> unstack(x, :year, :value) |>
            x -> transform(x,
                ["2019", "2021"] => ByRow((a,b) -> (a+b)/2) => :value,
                :state => ByRow(y -> 2020) => :year
            ) |>
            x -> select(x, Not("2019", "2021")) 
    ) 


    return df |>
            x -> transform(x, 
                :variable => ByRow(y -> replace(y, relabel...)) => :income
            ) |>
            x -> select(x, Not(:variable)) 

end

"""
    public_health_benefits(cms::DataFrame, acs::DataFrame)

Calculate the public health benefits from the CMS and ACS data. 

## Arguments

- `cms::DataFrame`: The CMS data the result of [`get_cms_data`](@ref) or [`extrapolate_cms_data`](@ref).
- `acs::DataFrame`: The ACS data the result of [`get_census_health_data`](@ref).

## Returns

A DataFrame with the following columns:

- `:state::String`: The state name.
- `:type::String`: The income category.
- `:year::Int`: The year of the data.
- `:income::String`: The income category.
- `:medicare::Float64`: The medicare spending.
- `:medicaid::Float64`: The medicaid spending.

## Methodology

1. Group the ACS data by state, income category, and year to compute value shares.
2. Left join the CMS data to the ACS data.
3. Calculate the medicare and medicaid spending by multiplying the value shares 
    by the medicare and medicaid spending and dividing by 1000.
"""
function public_health_benefits(cms::DataFrame, acs::DataFrame)

    return acs |>
        x -> groupby(x, [:state, :type, :year]) |>
        x -> combine(x, 
            :income => identity => :income,
            :value => (y -> y./sum(y)) => :shares
        ) |>
        x -> leftjoin(
            x,
            cms,
            on = [:state, :year]
        ) |>
        x -> transform(x,
            [:shares, :medicare] => ByRow((s,m) -> s*m*1e-3) => :medicare,
            [:shares, :medicaid] => ByRow((s,m) -> s*m*1e-3) => :medicaid
        ) |>
        x -> select(x, [:state, :year, :income, :medicare, :medicaid])
end