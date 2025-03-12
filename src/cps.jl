
function my_parse(val)
    if contains(val,'.')
        return parse.(Float64,val)
    end
    return parse.(Int,val)
end

function household_labels(val)
    bounds = [25000, 50000, 75000, 150000]
    for (i,bound) in enumerate(bounds)
        if val<=bound
            return "hh$i"
        end
    end
    return "hh5"
end

###############
## API Load ###
###############

"""
    get_cps_data_api(year, vars, api_key)

Pull the raw data directly from the API
"""
function get_cps_data_api(year, vars, api_key)

    url = "https://api.census.gov/data/$year/cps/asec/mar"

    query = Dict(
        "get" => vars,
        "for" => "state:*",
        "key" => api_key
    )

    response = HTTP.get(url; query=query);
    response_text = String(response.body)
    data = JSON.parse(response_text);

    return (data[1],[Tuple(my_parse.(row)) for row in data[2:end]])
end

"""
    clean_cps_data_year(year, cps_rw, variables, api_key; states = STATES)

Download and clean the CPS data for a given year.
"""
function clean_cps_data_year(year, cps_rw, variables, api_key; states = STATES)

    vars = join(vcat(cps_rw,variables), ',')

    given_vars,d = get_cps_data_api(year, vars, api_key)

    vars = Symbol.(lowercase.(given_vars))
    modify_vars = Symbol.(lowercase.(variables))

    df = DataFrame(d, vars) |>
        x -> subset(x,
            :a_exprrp => ByRow(∈([1,2])), # extract the household file with representative persons
            :h_hhtype => ByRow(==(1)), # extract the household file with representative persons
            :pppos => ByRow(==(41)) 
        ) |>
        x -> select(x, Not(:a_exprrp, :h_hhtype, :pppos)) |>
        x -> transform(x,
            :state => (y -> string.(y)) =>:state_code,
            :htotval => (y -> household_labels.(y)) => :hh, # add household label to each entry
            modify_vars .=> (a -> a.* x[!,:marsupwt]) .=> modify_vars   # scale income levels by the household weight
        ) |>
        x -> select(x, Not(:state,:gestfips)) |>
        x -> leftjoin(
            x,
            states,
            on = :state_code => :state_fips
        ) |>
        x -> select(x, :state_abbr => :state, Not(:state_code, :state_abbr, :state_name)) |>
        x -> stack(x, Not(:state, :hh), variable_name = :source, value_name = :value)

    return df

end

"""
    load_cps_data_api(api_key, years; states = STATES)

Load all the CPS data in the given year range. 

## Arguments

- `api_key` - Request an API key from the [Census website](https://api.census.gov/data/key_signup.html)
- `years` - The years to pull data for, as a range 2000:2023

## Keywords

- `states` - A DataFrame with the state FIPS codes and abbreviations (default is `STATES`)

## Returns

A dictionary with the following keys:

- `income` - A DataFrame with the income data
- `shares` - A DataFrame with the income shares
- `count` - A DataFrame with the count of households
- `numhh` - A DataFrame with the number of households

## API Call

There is a split in 2019. 

| Common | Pre-2019 | Post-2019 | Description |
|--------|----------|-----------|-------------|
| HWSVAL | | | wages and salaries |
| HSEVAL | | | self-employment (nonfarm) |
| HFRVAL | | | self-employment farm |
| HUCVAL | | | unemployment compensation |
| HWCVAL | | | workers compensation |
| HSSVAL | | | social security |
| HSSIVAL | | | supplemental security |
| HPAWVAL | | | public assistance or welfare |
| HVETVAL | | | veterans benefits |
| HSURVAL | | | survivors income |
| HDISVAL | | | disability |
| HINTVAL | | | interest |
| HDIVVAL | | | dividends |
| HRNTVAL | | | rents |
| HEDVAL | | | educational assistance |
| HCSPVAL | | | child support |
| HFINVAL | | | financial assistance |
| HOIVAL | | | other income |
| HTOTVAL | | | total household income |
| | GESTFIPS | | state fips |
| | A_EXPRRP | | expanded relationship code |
| | H_HHTYPE | | type of household interview |
| | PPPOS | | person identifier |
| | MARSUPWT | | asec supplement final weight |
| | | HDSTVAL  | retirement distributions |
| | | HPENVAL  | pension income |
| | | HANNVAL  | annuities |
"""
function load_cps_data_api(api_key, years; states = STATES)

    cps_vars = uppercase.([
        "hwsval", # "wages and salaries"
        "hseval", # "self-employment (nonfarm)"
        "hfrval", # "self-employment farm"
        "hucval", # "unemployment compensation"
        "hwcval", # "workers compensation"
        "hssval", # "social security"
        "hssival",# "supplemental security"
        "hpawval",# "public assistance or welfare"
        "hvetval",# "veterans benefits"
        "hsurval",# "survivors income"
        "hdisval",# "disability"
        "hintval",# "interest"
        "hdivval",# "dividends"
        "hrntval",# "rents"
        "hedval", # "educational assistance"
        "hcspval",# "child support"
        "hfinval",# "financial assistance"
        "hoival", # "other income"
        "htotval" # "total household income
        ])
        
        
    cps_rw = uppercase.([
        "gestfips", # state fips
        "a_exprrp", # expanded relationship code
        "h_hhtype", # type of household interview
        "pppos",    # person identifier
        "marsupwt"  # asec supplement final weight
        ]) 

    cps_post2019 = uppercase.([
            "hdstval", # "retirement distributions"
            "hpenval", # "pension income"
            "hannval"  # "annuities"
            ])


    cps_pre2019 = uppercase.(["hretval"]) # "retirement income"


    post_2019 = vcat(cps_vars,cps_post2019)
    pre_2019 = vcat(cps_vars,cps_pre2019)

    df = DataFrame()
    for year in years
        println(year)

        if year+1 < 2019
            vars = pre_2019
        else
            vars = post_2019
        end

        new_df = clean_cps_data_year(year+1,cps_rw, vars, api_key; states = states)
        new_df[!,:year] .= year

        df = vcat(df,new_df)
    end

    return df
end
    
"""
    cps_income(cps::DataFrame)

Compute the income from the CPS data by variable. 
"""
function cps_income(cps::DataFrame)
   return cps |> 
        x -> subset(x, 
            :source => ByRow(!=("marsupwt"))
        ) |>
        x -> groupby(x, [:state, :source, :hh,:year]) |>
        x -> combine(x,
            :value => sum => :value
        ) |>
        x -> select(x, :year, :state, :hh, :source, :value)
end

"""
    cps_number_households(cps::DataFrame; unit::Real = 1e-6)

Compute the number of households from the CPS data. This is the sum of the 
variable `marsupwt` for each household and state.
"""
function cps_number_households(cps::DataFrame; unit::Real = 1e-6)
    return cps |>
        x -> subset(x,
            :source => ByRow(==("marsupwt"))
        ) |>
        x -> groupby(x, [:state, :hh, :year]) |>
        x -> combine(x, :value => (y -> unit*sum(y)) => :value) |>
        x -> select(x, :year, :state, :hh, :value)
end

"""
    cps_income_shares(cps::DataFrame)

Compute the income share for by household.
"""
function cps_income_shares(cps::DataFrame)
    return cps_income(cps) |>
        x -> groupby(x, [:year,:state, :source]) |>
        x -> combine(x, 
            :hh => identity => :hh,
            :value => (y -> y./sum(y)) => :value
        ) |>
        x -> select(x, :year, :state, :hh, :source, :value)
end

"""
    cps_count_observations(cps::DataFrame)

Count the number of observations in the CPS data by household and state.
"""
function cps_count_observations(cps::DataFrame)
    cps |>
        x -> subset(x, :source => ByRow(==("marsupwt"))) |>
        x -> groupby(x, [:state, :year, :hh]) |>
        x -> combine(x,
            :value => length => :value
        ) |>
        x -> select(x, :year, :state, :hh, :value)
end