
# Run on server?
server <- TRUE

# Set working directory 
if(!server) {
    setwd("~/dropbox/311")
}

# Load packages 
pkgs <- c("stringr", "lubridate", "data.table", "ibdreg", "sp",
          "rgdal", "rgeos", "maptools", "jsonlite", "stringr",
          "R.utils", "plyr", "dplyr")
sapply(pkgs, require, character.only = TRUE)

# Load functions
source("r/functions.R")

# Run full script? If TRUE, all the data from 2004 to 2015-10-02
# will be processed. If FALSE, only new data from NYC's Open Data
# portal will be processed and added to the earlier data.
run_full <- FALSE


# Prepare data from 2004/01-2015/10---------
if(run_full) {

    # Unzip 311 request data and shape boundaries 
    s("tar -xvzf data/original/311requests.tar.gz -C data/original")
    s("unzip 'data/original/nyc-polyg-neighborhood.zip' -d data/original")
    
    # Clean and reproject neighborhood polygons 
    source("r/cleanreprojectneighborhoods.R")

    # Clean the NYC 311 data, stored in csv files for years 2004-15.
    # (The last full date in the dataset is 2015-10-02.)
    source("r/clean311data.R")

    # Spatially join neighborhoods with 311 data: output
    # processed/nyc311.rds
    source("r/spatialjoins311.R")

    # Remove unzipped files
    s("cd data/original; rm -r nynta_15c NYC_311_*.csv")
    
}


# Add data for later dates---------
# A cron script is used to update data daily 

# Grab newly added data from NYC's Open Data portal
source("r/update311.R", echo = T)
 
# Aggregate the data to different levels 
source("r/aggregate311.R", echo = T)

# Add data to neighborhood json
source("r/merge-geo-aggregate.R", echo = T)
