
nyc311 <- readRDS("data/processed/nyc311-temp.rds")

test <- F
sample.size <- 10^5  #for testing, draw sample of 100k

# Projection to use
proj <- "+proj=lcc +lat_1=40.66666666666666 +lat_2=41.03333333333333 +lat_0=40.16666666666666 +lon_0=-74 +x_0=300000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs +ellps=GRS80 +towgs84=0,0,0"

# Read and reproject neighborhood data
nycnh <- readOGR("data/processed/neighborbound.json", "OGRGeoJSON")
nycnh <- spTransform(nycnh, CRS(proj))

# Project 311 data 
nyc.sp <- project(cbind(nyc311$long, nyc311$lat), proj)
nyc.sp <- SpatialPointsDataFrame(SpatialPoints(nyc.sp), nyc311)
proj4string(nyc.sp) <- proj

# Spatial joins
if(test) nyc.sp <- nyc.sp[sample(1:nrow(nyc.sp), size = sample.size), ]

nyc.sp$neighborhood <- over(nyc.sp, nycnh)$neighborhood
sum(nyc.sp$neighborhood %in% NA) #number of non-matches --> drop
nyc.sp <- nyc.sp[!nyc.sp$neighborhood %in% NA, ]


# Write file that has 311 data with spatial join info 
if(test) {
    saveRDS(nyc.sp@data, file = "data/processed/nyc311wjoins-sample.rds")
} else {
    saveRDS(nyc.sp@data, file = "data/processed/nyc311wjoins.rds")
}


