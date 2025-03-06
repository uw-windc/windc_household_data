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

census_data = load_cps_data_api(census_api_key, years)

cps_nipa = cps_vs_nipa_income_categories(census_data[:income], bea_api_key, years)

save_cps_data(census_data, cps_nipa, "data/cps", years)
```

Alternatively



## API Reference


```@autodocs
Modules = [windc_household_data]
Order   = [:type, :function]
```

