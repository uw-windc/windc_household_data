# Introduction

This package contains method to download the raw CSV data used in the WiNDC.GAMS build stream. 

To add this package to your Julia environment, open the package manager and type:

```
pkg> add https://github.com/uw-windc/windc_household_data
```


Download the data is a single function call:

```julia
using windc_household_data

census_api_key = "<census_api_key>"
bea_api_key = "<bea_api_key>"

years = 2000:2023

download_save_data(
    census_api_key, 
    bea_api_key, 
    years, 
    "data/";
    acs_year = 2020
    )
```

## API Reference


```@autodocs
Modules = [windc_household_data]
Order   = [:type, :function]
```

