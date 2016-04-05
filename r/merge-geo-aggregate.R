

# Read in neighborhood polygons
n <- readOGR("data/processed/neighborbound.json", "OGRGeoJSON")

# Read in aggregated data
agg <- read.csv("app/data/nyc311-byneightime.csv")

# Include data from within the last year and drop many variables 
agg <- agg %>%
    filter(time == "All time", requesttype == "All") %>%
    select(neighborhood, nrequests, avgresptime, rankrt)

# Merge
n@data <- plyr::join(n@data, agg, by = "neighborhood")


# Write these new data and convert to topojson 
writeOGR(
    n,
    dsn = "neighborbound",
    layer = "neigborhoods",
    driver = "GeoJSON"
    )

s("mv neighborbound neighborbound.json;
  topojson -o \
  app/data/neighborbound.topo.json \
  neighborbound.json \
  -p neighborhood,nrequests,avgresptime,rankrt;
  rm neighborbound.json")


