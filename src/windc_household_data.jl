module windc_household_data

using DataFrames, HTTP, CSV, JSON, ZipFile, Downloads

using GLM, XLSX, Dates

const STATES = DataFrame(
    state_fips = ["1","2","4","5","6","8","9","10","11","12","13","15","16","17","18",
      "19","20","21","22","23","24","25","26","27","28","29","30","31","32","33",
      "34","35","36","37","38","39","40","41","42","44","45","46","47","48","49",
      "50","51","53","54","55","56"],
    state_abbr = ["AL","AK","AZ","AR","CA","CO","CT","DE","DC","FL","GA","HI","ID","IL","IN",
      "IA","KS","KY","LA","ME","MD","MA","MI","MN","MS","MO","MT","NE","NV","NH",
      "NJ","NM","NY","NC","ND","OH","OK","OR","PA","RI","SC","SD","TN","TX","UT",
      "VT","VA","WA","WV","WI","WY"],
    state_name = ["Alabama","Alaska","Arizona","Arkansas","California","Colorado","Connecticut",
      "Delaware","District of Columbia","Florida","Georgia","Hawaii","Idaho","Illinois",
      "Indiana","Iowa","Kansas","Kentucky","Louisiana","Maine","Maryland","Massachusetts",
      "Michigan","Minnesota","Mississippi","Missouri","Montana","Nebraska","Nevada",
      "New Hampshire","New Jersey","New Mexico","New York","North Carolina","North Dakota",
      "Ohio","Oklahoma","Oregon","Pennsylvania","Rhode Island","South Carolina",
      "South Dakota","Tennessee","Texas","Utah","Vermont","Virginia","Washington",
      "West Virginia","Wisconsin","Wyoming"]
  )

include("download.jl")


include("cps.jl")

export load_cps_data_api


include("bea.jl")

export cps_vs_nipa_income_categories

include("health_care.jl")

include("commuting.jl")

include("soi.jl")

include("data_exporter.jl")

export download_save_data, save_cps_data

end # module windc_household_data
