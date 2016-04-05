
# This script cleans and reproject the neighborhood polygons downloaded
# from http://www.nyc.gov/html/dcp/html/bytes/dwn_nynta.shtml (dept of
# city planning in NYC) 

# Read in shape
neigh <- readOGR(dsn = "data/original/nynta_15c", layer = "nynta")

# Reproject to projection that can easily be overlaid on google maps
neigh <- spTransform(neigh, CRS("+proj=longlat +datum=WGS84 +no_defs +ellps=WGS84 +towgs84=0,0,0"))

# Some neighborhoods consist of several polygons; split into separate IDs
# Create a list of new spdf objects 
j <- 0
newspdf <- list()
for(i in 1:nrow(neigh)) {
    n <- neigh[i, ]@polygons[[1]]@Polygons
    m <- length(n)
    if(m > 1) {       
        # If multi-polygon, split into separate polygons
        nsp <- lapply(n, convertSP, dta = neigh[i, ]@data) #convertSP defined in functions.R

        # Convert from list 
        multisp <- spRbind(nsp[[1]], nsp[[2]])
        if(m > 2) {
            for(k in 3:m) multisp <- spRbind(multisp, nsp[[k]])
        }

        # Store in list of new spdf objects
        j <- j + 1
        newspdf[[j]] <- multisp    
    }
}

# Combine new polygons 
newn <- spRbind(newspdf[[1]], newspdf[[2]])
for(i in 3:length(newspdf)) newn <- spRbind(newn, newspdf[[i]])
proj4string(newn) <- proj4string(neigh)

# Remove new polygons from full spdf
neigh <- neigh[!neigh$NTAName %in% newn$NTAName, ]

# Create new full set of neighborhoods
neigh <- spRbind(neigh, newn)
neigh@data <- neigh@data %>% select(borough = BoroName, neighborhood = NTAName)

# And remove special neighborhoods
neigh <- neigh[!grepl("park-cemetery-etc", neigh$neighborhood), ]

# Create new id 
neigh <- spChFIDs(neigh, as.character(1:nrow(neigh)))

# Change neighborhood names slightly
neigh$neighborhood <- gsub("-", "/", neigh$neighborhood)
neigh$neighborhood[neigh$neighborhood == "Co/op City"] <- "Co-op City"

# Grab the largest if multiple of same neighborhood
neigh$area <- sW(gArea(neigh, byid = T))

temp <- neigh@data %>%
    group_by(neighborhood) %>% 
    mutate(maxarea = area == max(area))

neigh2 <- neigh[temp$maxarea, ]
  
# Write to geojson
writeOGR(
    neigh2,
    dsn = "data/processed/neighborbound",
    layer = "neigborhoods",
    driver = "GeoJSON"
    )

# Add .json 
s("cd data/processed; mv neighborbound neighborbound.json")
