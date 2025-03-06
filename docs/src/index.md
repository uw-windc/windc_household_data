# Introduction

This package contains method to download the raw CSV data used in the WiNDC.GAMS build stream. 

To add this package to your Julia environment, open the package manager and type:

```
pkg> add https://github.com/uw-windc/windc_household_data
```


```julia
using windc_household_data

census_api_key = "<census_api_key>"
bea_api_key = "<bea_api_key>"

years = 2000:2023

df = load_cps_data_api(census_api_key, years)

cps_nipa = cps_vs_nipa_income_categories(df[:income], bea_api_key, years)
```




## API Reference


```@autodocs
Modules = [windc_household_data]
Order   = [:type, :function]
```

