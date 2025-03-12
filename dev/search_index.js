var documenterSearchIndex = {"docs":
[{"location":"#Introduction","page":"Introduction","title":"Introduction","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"This package contains method to download the raw CSV data used in the WiNDC.GAMS build stream. ","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"To add this package to your Julia environment, open the package manager and type:","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"pkg> add https://github.com/uw-windc/windc_household_data","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"using windc_household_data\n\ncensus_api_key = \"<census_api_key>\"\nbea_api_key = \"<bea_api_key>\"\n\nyears = 2000:2023\n\ncensus_data = load_cps_data_api(census_api_key, years)\n\ncps_nipa = cps_vs_nipa_income_categories(census_data[:income], bea_api_key, years)\n\nsave_cps_data(census_data, cps_nipa, \"data/cps\", years)","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"Alternatively, you can download and save the data in a single operation.","category":"page"},{"location":"","page":"Introduction","title":"Introduction","text":"using windc_household_data\n\ncensus_api_key = \"<census_api_key>\"\nbea_api_key = \"<bea_api_key>\"\n\nyears = 2000:2023\n\ndownload_save_data(census_api_key, bea_api_key, years, \"data/cps\")","category":"page"},{"location":"#API-Reference","page":"Introduction","title":"API Reference","text":"","category":"section"},{"location":"","page":"Introduction","title":"Introduction","text":"Modules = [windc_household_data]\nOrder   = [:type, :function]","category":"page"},{"location":"#windc_household_data.acs_commuting-Tuple{DataFrames.DataFrame, DataFrames.DataFrame}","page":"Introduction","title":"windc_household_data.acs_commuting","text":"acs_commuting(raw_commuting::DataFrame, wages::DataFrame)\n\nCompute the commuting data from the ACS data and the wages data.\n\nArguments\n\nraw_commuting - The raw commuting data from the ACS, output from  read_commuting_data.\nwages - The wages data from the CPS data, output from cps_wages.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.clean_cps_data_year-NTuple{4, Any}","page":"Introduction","title":"windc_household_data.clean_cps_data_year","text":"clean_cps_data_year(year, cps_rw, variables, api_key; states = STATES)\n\nDownload and clean the CPS data for a given year.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.cps_count_observations-Tuple{DataFrames.DataFrame}","page":"Introduction","title":"windc_household_data.cps_count_observations","text":"cps_count_observations(cps::DataFrame)\n\nCount the number of observations in the CPS data by household and state.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.cps_income-Tuple{DataFrames.DataFrame}","page":"Introduction","title":"windc_household_data.cps_income","text":"cps_income(cps::DataFrame)\n\nCompute the income from the CPS data by variable. \n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.cps_income_shares-Tuple{DataFrames.DataFrame}","page":"Introduction","title":"windc_household_data.cps_income_shares","text":"cps_income_shares(cps::DataFrame)\n\nCompute the income share for by household.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.cps_number_households-Tuple{DataFrames.DataFrame}","page":"Introduction","title":"windc_household_data.cps_number_households","text":"cps_number_households(cps::DataFrame; unit::Real = 1e-6)\n\nCompute the number of households from the CPS data. This is the sum of the  variable marsupwt for each household and state.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.cps_vs_nipa_income_categories-Tuple{DataFrames.DataFrame, DataFrames.DataFrame}","page":"Introduction","title":"windc_household_data.cps_vs_nipa_income_categories","text":"cps_vs_nipa_income_categories(income::DataFrame, api_key::String)\n\nReturn a comparison between CPS and NIPA income categories.\n\nArguments\n\nincome - A DataFrame with the CPS income data\napi_key - Request an API key from the BEA website\n\nReturns\n\nA DataFrame with the columns year, nipa, cps, pct_diff, and category.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.cps_wages-Tuple{DataFrames.DataFrame}","page":"Introduction","title":"windc_household_data.cps_wages","text":"cps_wages(census_data::DataFrame; year = 2020)\n\nCompute the wages from the CPS data by state and year.\n\nArguments\n\ncensus_data - The CPS data from the API or a CSV file, output from  load_cps_data_api.\nyear - The year to pull the data for. Default is 2020. The commuting data   is released every 5 years, this is the most recent year or release.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.create_nipa_windc-Tuple{Any, Any}","page":"Introduction","title":"windc_household_data.create_nipa_windc","text":"create_nipa_windc(bea_data::DataFrame, type::Symbol)\n\nCreate a DataFrame comparing the WiNDC vs NIPA data. This uses two magic files, ld0_windc.csv and kd0_windc.csv to create the comparison.\n\nArguments\n\nbea_data - A DataFrame with the NIPA data\ntype - Either :labor or :capital\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.download_save_data-NTuple{4, Any}","page":"Introduction","title":"windc_household_data.download_save_data","text":"download_save_data(census_api_key, bea_api_key, years, output_directory; states = STATES)\n\nDownload and save the CPS and BEA data to the output directory.\n\nArguments\n\ncensus_api_key - The Census API key. Request an API key from the Census website\nbea_api_key - The BEA API key. Request an API key from the BEA website\nyears - The years to pull data for, as a range 2000:2023\noutput_root_directory - The directory to save the data\n\nOptional Arguments\n\nstates - A DataFrame with the state FIPS and abbreviations. Default is STATES.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.extrapolate_cms_data-Tuple{DataFrames.DataFrame, Any}","page":"Introduction","title":"windc_household_data.extrapolate_cms_data","text":"extrapolate_cms_data(cms::DataFrame, years)\n\nExtrapolate CMS data for each given year. Performs the extrapolation for each state independently.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.extrapolate_cms_data_single_state-Tuple{Any, Any}","page":"Introduction","title":"windc_household_data.extrapolate_cms_data_single_state","text":"extrapolate_cms_data_single_state(df, years)\n\nExtrapolate CMS data to years that are not in the data. This uses a linear model to extrapolate the data. Will filter years to be only years not present in data.\n\nArguments\n\ndf::DataFrame: The CMS data.\nyears::Vector{Int}: All years needed in final data\n\nReturns\n\nA DataFrame with the following columns:\n\n:state::String: The state name.\n:year::Int: The year of the data.\n:medicare::Float64: The medicare spending.\n:medicade::Float64: The medicade spending.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.fetch_commuting_data-Tuple{Any}","page":"Introduction","title":"windc_household_data.fetch_commuting_data","text":"fetch_commuting_data(output_directory; year = 2020, file_name = \"table1.xlsx\", output_name = file_name)\n\nDownload the commuting data from the Census Bureau website.\n\nArguments\n\noutput_directory - The directory to save the data.\n\nOptional Arguments\n\nyear - The year to pull the data for. Default is 2020. The commuting data   is released every 5 years, this is the most recent year or release.\nfile_name - The name of the file to download. Default is \"table1.xlsx\".\noutput_name - The name of the file to save the data as. Default is the same   as file_name.\n\nReturns\n\nThe path to the downloaded file.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.fetch_zip_data-Tuple{String, Function}","page":"Introduction","title":"windc_household_data.fetch_zip_data","text":"fetch_zip_data(\n    url::String,\n    filter_function::Function;;\n    output_path::String = joinpath(pwd(), \"data\"),\n)\n\nDownload a zip file from a given url and extract the files in the zip file that  are in the data NamedTuple.\n\nThis function will throw an error if not all files in data are extracted.\n\nRequired Arguments\n\nurl::String: The url of the zip file to download.\nfilter_function::Function;: A function that takes a string and returns a boolean.  This function is used to filter the files in the zip file, it should return true   if the file should be extracted and false otherwise.\n\nOptional Arguments\n\noutput_path::String: The path to save the extracted files. Default is the \n\ndirectory data in the current working directory. If this is not an absolute path, it will be joined with the current working directory.\n\nOutput\n\nReturns a vector of the absolute paths to the extracted files.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.get_bea_nipa_data-Tuple{String, Any}","page":"Introduction","title":"windc_household_data.get_bea_nipa_data","text":"get_bea_nipa_data(bea_key::String, years)\n\nGet NIPA data from the BEA API for the given years.\n\nArguments\n\nbea_key - Request an API key from the BEA website\nyears - The years to pull data for, as a range 2001:2024 -> These are +1 for some reason\n\nReturns\n\nA DataFrame with the NIPA data for the given years and columns year,  LineNumber, and nipa.\n\nAPI query\n\nquery = Dict(\n    \"UserID\" => bea_key,\n    \"method\" => \"GetData\",\n    \"datasetname\" => \"NIPA\",\n    \"TableName\" => \"T20100\",\n    \"Frequency\" => \"A\",\n    \"Year\" => join(years, \",\"),\n    \"ResultFormat\" => \"JSON\"\n)\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.get_census_health_data-Tuple{Any, Any}","page":"Introduction","title":"windc_household_data.get_census_health_data","text":"get_census_health_data(census_api_key, years)\n\nGet health data from the ACS for multiple years. This function will return the data for all states.\n\nRetrieves data from the following variables in the ACS 1 year survey:\n\nB27015_005\nB27015_010\nB27015_015\nB27015_020\nB27015_025\n\nNo data is available for 2020 due to low response rates. We will use the average of 2019 and 2021 data for 2020.\n\nArguments\n\ncensus_api_key::String: The Census API key.\nyears::Vector{Int}: The years to get the data, will filter to be >= 2009.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.get_census_health_data_year-Tuple{Any, Any, Any}","page":"Introduction","title":"windc_household_data.get_census_health_data_year","text":"get_census_health_data_year(census_api_key, variables, year)\n\nGet health data from the ACS for a single year. This function will return the data for all states.\n\nWe only want estimated data, not MOE data. Will only return estimates.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.get_cms_data-Tuple{Any}","page":"Introduction","title":"windc_household_data.get_cms_data","text":"get_cms_data(output;files_to_grab = (medicare = \"MEDICARE_AGGREGATE20.CSV\", medicaid = \"MEDICAID_AGGREGATE20.CSV\"))\n\nDownload and extract CMS a state health expediture by state of residence data. This downloads a ZIP file from the CMS website.\n\nArguments\n\noutput::String: The directory to save the data to.\n\nKeyword Arguments\n\nfiles_to_grab::Tuple: A tuple of file names to extract from the ZIP file. The keys are the names of the files and the values are the names of the files in the ZIP file.\n\nReturns\n\nA DataFrame with the following columns:\n\n:state::String: The state name.\n:year::Int: The year of the data.\n:medicare::Float64: The medicare spending.\n:medicade::Float64: The medicaid spending.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.get_cps_data_api-Tuple{Any, Any, Any}","page":"Introduction","title":"windc_household_data.get_cps_data_api","text":"get_cps_data_api(year, vars, api_key)\n\nPull the raw data directly from the API\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.load_cps_data_api-Tuple{Any, Any}","page":"Introduction","title":"windc_household_data.load_cps_data_api","text":"load_cps_data_api(api_key, years; states = STATES)\n\nLoad all the CPS data in the given year range. \n\nArguments\n\napi_key - Request an API key from the Census website\nyears - The years to pull data for, as a range 2000:2023\n\nKeywords\n\nstates - A DataFrame with the state FIPS codes and abbreviations (default is STATES)\n\nReturns\n\nA dictionary with the following keys:\n\nincome - A DataFrame with the income data\nshares - A DataFrame with the income shares\ncount - A DataFrame with the count of households\nnumhh - A DataFrame with the number of households\n\nAPI Call\n\nThere is a split in 2019. \n\nCommon Pre-2019 Post-2019 Description\nHWSVAL   wages and salaries\nHSEVAL   self-employment (nonfarm)\nHFRVAL   self-employment farm\nHUCVAL   unemployment compensation\nHWCVAL   workers compensation\nHSSVAL   social security\nHSSIVAL   supplemental security\nHPAWVAL   public assistance or welfare\nHVETVAL   veterans benefits\nHSURVAL   survivors income\nHDISVAL   disability\nHINTVAL   interest\nHDIVVAL   dividends\nHRNTVAL   rents\nHEDVAL   educational assistance\nHCSPVAL   child support\nHFINVAL   financial assistance\nHOIVAL   other income\nHTOTVAL   total household income\n GESTFIPS  state fips\n A_EXPRRP  expanded relationship code\n H_HHTYPE  type of household interview\n PPPOS  person identifier\n MARSUPWT  asec supplement final weight\n  HDSTVAL retirement distributions\n  HPENVAL pension income\n  HANNVAL annuities\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.magic_data_cex-Tuple{Any}","page":"Introduction","title":"windc_household_data.magic_data_cex","text":"magic_data_cex(output_directory)\n\nCopy the files from the magic_data directory to the output directory. This copies two files, national_income_elasticities_CEX_2013_2017.csv and windc_pce_map.csv.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.magic_data_cps-Tuple{Any}","page":"Introduction","title":"windc_household_data.magic_data_cps","text":"magic_data_cps(output_directory)\n\nCopy the files from the magic_data directory to the output directory. This copies two files, labor_tax_rates.csv and capital_tax_rates.csv which are created in the SAGE model.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.public_health_benefits-Tuple{DataFrames.DataFrame, DataFrames.DataFrame}","page":"Introduction","title":"windc_household_data.public_health_benefits","text":"public_health_benefits(cms::DataFrame, acs::DataFrame)\n\nCalculate the public health benefits from the CMS and ACS data. \n\nArguments\n\ncms::DataFrame: The CMS data the result of get_cms_data or extrapolate_cms_data.\nacs::DataFrame: The ACS data the result of get_census_health_data.\n\nReturns\n\nA DataFrame with the following columns:\n\n:state::String: The state name.\n:type::String: The income category.\n:year::Int: The year of the data.\n:income::String: The income category.\n:medicare::Float64: The medicare spending.\n:medicaid::Float64: The medicaid spending.\n\nMethodology\n\nGroup the ACS data by state, income category, and year to compute value shares.\nLeft join the CMS data to the ACS data.\nCalculate the medicare and medicaid spending by multiplying the value shares   by the medicare and medicaid spending and dividing by 1000.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.read_commuting_data-Tuple{Any}","page":"Introduction","title":"windc_household_data.read_commuting_data","text":"read_commuting_data(file_path; states = STATES)\n\nRead the commuting data from the given file path. Download the commuting data  with the fetch_commuting_data function.\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.save_cps_data-Tuple{Any, Any, Any}","page":"Introduction","title":"windc_household_data.save_cps_data","text":"save_cps_data(census_data, bea_data, output_directory)\n\nSave the CPS and BEA data to the output directory.\n\nArguments\n\ncensus_data - A DataFrame with the CPS data\nbea_data - A DataFrame with the BEA data\noutput_directory - The directory to save the data\n\n\n\n\n\n","category":"method"},{"location":"#windc_household_data.save_public_health_benefits_data-Tuple{DataFrames.DataFrame, Any}","page":"Introduction","title":"windc_household_data.save_public_health_benefits_data","text":"save_public_health_benefits_data(health::DataFrame, output_directory)\n\nSave the public health benefits data to the output directory.\n\n\n\n\n\n","category":"method"}]
}
