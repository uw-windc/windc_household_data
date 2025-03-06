
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

    url = "https://api.census.gov/data/$year/cps/asec/mar?get=$vars&for=state:*&key=$(api_key)"

    response = HTTP.get(url);
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
        x -> transform(x,
            :state => (y -> string.(y)) =>:state_code
        ) |> 
        #x -> apply_notations(x,notations) |>
        x -> transform(x, 
            :htotval => (y -> household_labels.(y)) => :hh # add household label to each entry
        )|>
        x -> transform(x,
            modify_vars .=> (a -> a.* x[!,:marsupwt]) .=> modify_vars   # scale income levels by the household weight
        ) |>
        x -> leftjoin(
            x,
            states,
            on = :state_code => :state_fips
        ) |>
        x -> select(x, Not(:state_code))


    # Count by income breakdowns and State
    national_count = df |>
        x -> groupby(x, :hh) |>
        x -> combine(x, :hh => length => :n) |>
        x -> transform(x,
            :hh => (y -> "US") => :state
        )

    regional_count = df |>
        x -> groupby(x, [:hh,:state]) |>
        x -> combine(x, :hh => length => :n) |>
        x -> vcat(x,national_count)

    # Incomes by income breakdown and stat
    national_income = df |>
        x -> groupby(x, :hh) |>
        x -> combine(x, modify_vars .=> sum .=> modify_vars) |>
        x -> transform(x, 
            :hh => (y -> "US") => :state
        )

    income = df |>
        x -> groupby(x, [:hh,:state]) |>
        x -> combine(x, modify_vars .=> sum .=> modify_vars) |>
        x -> vcat(x,national_income) |>
        x -> stack(x, Not(:hh,:state), variable_name = :source,value_name = :value)


    shares = income |>
        x -> groupby(x, [:state,:source]) |>
        x -> combine(x, :value .=> sum) |>
        x -> leftjoin(income,x, on = [:state,:source]) |>
        x -> transform(x,
            [:value,:value_sum] => ((a,b) -> a./b) => :value
        ) |>
        x -> select(x,Not(:value_sum));

    numhh = df |>
        x -> select(x, [:hh,:state,:marsupwt]) |>
        x -> groupby(x, [:state,:hh]) |>
        x -> combine(x, :marsupwt => (y -> sum(y)*1e-6) => :numhh)


    return (income=income,shares=shares,count=regional_count,numhh=numhh)

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

    out = Dict(
        :income => DataFrame(),
        :shares => DataFrame(),
        :count => DataFrame(),
        :numhh => DataFrame()
        )

    for year in years
        println(year)

        if year+1 < 2019
            vars = pre_2019
        else
            vars = post_2019
        end

        T = clean_cps_data_year(year+1,cps_rw, vars, api_key; states = states)
        
        for e in keys(T)
            df = T[e]
            df[!,:year] .= year 

            out[e] = vcat(out[e],df)
        end
    end
    return out

end


