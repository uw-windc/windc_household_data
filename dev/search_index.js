var documenterSearchIndex = {"docs":
[{"location":"#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"This package contains method to download the raw CSV data used in the WiNDC.GAMS build stream. ","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"To add this package to your Julia environment, open the package manager and type:","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"pkg> add https://github.com/uw-windc/windc_household_data","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"using windc_household_data\n\ncensus_api_key = \"<census_api_key>\"\nbea_api_key = \"<bea_api_key>\"\n\nyears = 2000:2023\n\ncensus_data = load_cps_data_api(census_api_key, years)\n\ncps_nipa = cps_vs_nipa_income_categories(census_data[:income], bea_api_key, years)\n\nsave_cps_data(census_data, cps_nipa, \"data/cps\", years)","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"Alternatively, you can download and save the data in a single operation.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"using windc_household_data\n\ncensus_api_key = \"<census_api_key>\"\nbea_api_key = \"<bea_api_key>\"\n\nyears = 2000:2023\n\ndownload_save_data(census_api_key, bea_api_key, years, \"data/cps\")","category":"page"},{"location":"#API-Reference","page":"Introduction","title":"API Reference","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Modules = [windc_household_data]\nOrder   = [:type, :function]","category":"page"},{"location":"#windc_household_data.clean_cps_data_year-NTuple{4, Any}","page":"Introduction","title":"windc_household_data.clean_cps_data_year","text":"clean_cps_data_year(year, cps_rw, variables, api_key; states = STATES)\n\nDownload and clean the CPS data for a given year.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.cps_vs_nipa_income_categories-Tuple{DataFrames.DataFrame, Any, Any}","page":"Introduction","title":"windc_household_data.cps_vs_nipa_income_categories","text":"cps_vs_nipa_income_categories(income::DataFrame, api_key, years)\n\nReturn a comparison between CPS and NIPA income categories.\n\nArguments\n\nincome - A DataFrame with the CPS income data\napi_key - Request an API key from the BEA website\nyears - The years to pull data for, as a range 2000:2023\n\nReturns\n\nA DataFrame with the columns year, nipa, cps, pct_diff, and category.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.download_save_data-NTuple{4, Any}","page":"Introduction","title":"windc_household_data.download_save_data","text":"download_save_data(census_api_key, bea_api_key, years, output_directory; states = STATES)\n\nDownload and save the CPS and BEA data to the output directory.\n\nArguments\n\ncensus_api_key - The Census API key. Request an API key from the Census website\nbea_api_key - The BEA API key. Request an API key from the BEA website\nyears - The years to pull data for, as a range 2000:2023\noutput_directory - The directory to save the data\n\nOptional Arguments\n\nstates - A DataFrame with the state FIPS and abbreviations. Default is STATES.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.get_bea_nipa_data-Tuple{String, Any}","page":"Introduction","title":"windc_household_data.get_bea_nipa_data","text":"get_bea_nipa_data(bea_key::String, years)\n\nGet NIPA data from the BEA API for the given years.\n\nArguments\n\nbea_key - Request an API key from the BEA website\nyears - The years to pull data for, as a range 2001:2024 -> These are +1 for some reason\n\nReturns\n\nA DataFrame with the NIPA data for the given years and columns year,  LineNumber, and nipa.\n\nAPI query\n\nquery = Dict(\n    \"UserID\" => bea_key,\n    \"method\" => \"GetData\",\n    \"datasetname\" => \"NIPA\",\n    \"TableName\" => \"T20100\",\n    \"Frequency\" => \"A\",\n    \"Year\" => join(years, \",\"),\n    \"ResultFormat\" => \"JSON\"\n)\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.get_cps_data_api-Tuple{Any, Any, Any}","page":"Introduction","title":"windc_household_data.get_cps_data_api","text":"get_cps_data_api(year, vars, api_key)\n\nPull the raw data directly from the API\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.load_cps_data_api-Tuple{Any, Any}","page":"Introduction","title":"windc_household_data.load_cps_data_api","text":"load_cps_data_api(api_key, years; states = STATES)\n\nLoad all the CPS data in the given year range. \n\nArguments\n\napi_key - Request an API key from the Census website\nyears - The years to pull data for, as a range 2000:2023\n\nKeywords\n\nstates - A DataFrame with the state FIPS codes and abbreviations (default is STATES)\n\nReturns\n\nA dictionary with the following keys:\n\nincome - A DataFrame with the income data\nshares - A DataFrame with the income shares\ncount - A DataFrame with the count of households\nnumhh - A DataFrame with the number of households\n\nAPI Call\n\nThere is a split in 2019. \n\nCommon Pre-2019 Post-2019 Description\nHWSVAL   wages and salaries\nHSEVAL   self-employment (nonfarm)\nHFRVAL   self-employment farm\nHUCVAL   unemployment compensation\nHWCVAL   workers compensation\nHSSVAL   social security\nHSSIVAL   supplemental security\nHPAWVAL   public assistance or welfare\nHVETVAL   veterans benefits\nHSURVAL   survivors income\nHDISVAL   disability\nHINTVAL   interest\nHDIVVAL   dividends\nHRNTVAL   rents\nHEDVAL   educational assistance\nHCSPVAL   child support\nHFINVAL   financial assistance\nHOIVAL   other income\nHTOTVAL   total household income\n GESTFIPS  state fips\n A_EXPRRP  expanded relationship code\n H_HHTYPE  type of household interview\n PPPOS  person identifier\n MARSUPWT  asec supplement final weight\n  HDSTVAL retirement distributions\n  HPENVAL pension income\n  HANNVAL annuities\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.save_cps_data-NTuple{4, Any}","page":"Introduction","title":"windc_household_data.save_cps_data","text":"save_cps_data(census_data, bea_data, output_directory)\n\nSave the CPS and BEA data to the output directory.\n\nArguments\n\ncensus_data - A DataFrame with the CPS data\nbea_data - A DataFrame with the BEA data\noutput_directory - The directory to save the data\n\n\n\n\n\n","category":"method"}]
}
