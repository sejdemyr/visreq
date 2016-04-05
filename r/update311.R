
# This scripts updates the 311 data starting at day1 and ending at day2  

# Read in current version of data 
nyc311 <- readRDS("data/processed/nyc311wjoins.rds")
dim(nyc311)
head(nyc311)

# Get latest updated date (minus two days) and today's date
day1 <- max(as.Date(nyc311$opened)) - 2
day2 <- Sys.Date()

# Get sequence of days to query 
seq.days <- seq(as.Date(day1), as.Date(day2), by = "day")

# Put in format recognized by socrata API
seq.days <- paste0(seq.days, "T00:00:00")

# Specify variables to query 
variables <- c("unique_key", "created_date", "closed_date", "complaint_type", 
               "latitude", "longitude", "resolution_action_updated_date")
variables <- paste(variables, collapse = ",")

# Each day is queried separately --> construct call for each
n <- length(seq.days) - 1

# Query based on updated day
api <- character(n)
for(i in 1:n) {
    api[i] <- paste0(
        "https://data.cityofnewyork.us/resource/erm2-nwe9.json?",                    #base API
        "$select=", variables,                                                       #select variables 
        "&$where=resolution_action_updated_date%3E=%27", seq.days[i],                #filter by date
           "%27%20AND%20resolution_action_updated_date%3C%27", seq.days[i+1], "%27", #filter by date (cont.) 
         "&$limit=50000"                                                             #set max limit
        )
}

# Get data 
newdta <- lapply(api, fromJSON)
newdta <- rbind.fill(newdta)

# Rename variables
newdta <- newdta %>%
    rename(opened = created_date, closed = closed_date, long = longitude,
           lat = latitude, key = unique_key, type = complaint_type,
           updated = resolution_action_updated_date)

# Convert to correct class
newdta <- mutate(newdta, key = as.integer(key), long = as.numeric(long), lat = as.numeric(lat))

# Clean dates
newdta <- newdta %>% 
    mutate(opened = ymd(substring(opened, 1, 10)), 
           closed = ymd(substring(closed, 1, 10)),
           openedyr = year(opened),
           closedyr = year(closed),
           updated = ymd_hms(updated)) %>%
    filter(openedyr %in% 2004:2017, closedyr %in% 2004:2017 | closedyr %in% NA) 

newdta <- filter(newdta, openedyr <= closedyr | closedyr %in% NA)

# If updated more than once, grab the latest update
grabfirst <- function(x) x[1]
newdta <- newdta %>%
    arrange(desc(updated)) %>%
    group_by(key) %>%
    summarise_each(funs(grabfirst)) %>%
    data.frame()

# Generate response time
newdta <- newdta %>%
    mutate(resptime = as.numeric(difftime(closed, opened, units = "days")),
           resptime = ifelse(resptime >=0, resptime, NA))

# Clean complaint type
cpn <- as.character(newdta$type)

cpn[cpn == "Derelict Vehicles"] <- "Derelict Vehicle"
cpn[cpn %in% c("Unleashed Dog", "Unsanitary Pigeon", "Trapping Pigeon",
               "Killing/Trapping", "Rodent", "Harboring Bees/Wasps",
               "Animal Facility - No Permit", "Animal in a Park",
               "Illegal Animal - Sold/Kept", "Dog License Survey")] <- "Animal Care"

cpn[c(grep("Street Sign", cpn), grep("Highway Sign", cpn))] <- "Defective Street/Highway Sign"

cpn[grep("Noise", cpn)] <- "Noise"

cpn[cpn %in% c("Health", "Health and Safety", "Safety")] <- "Health and Safety"

cpn[cpn %in% c("Water Conservation", "Water Quality", "Water System",
               "Bottled Water", "Drinking", "Tap Water")] <- "Water"

cpn[grep("Tree", cpn)] <- "Damaged Tree"

cpn[cpn %in% c("Asbestos", "Indoor Air Quality", "Indoor Unsanitary Condition",
               "Mold")] <- "Indoor Housing"

cpn[cpn %in% c("ELECTRIC", "Electrical")] <- "Electric"

cpn[c(grep("construction", cpn, ignore.case = TRUE),
      grep("plumbing", cpn, ignore.case = TRUE))] <- "Construction/Plumbing"

cpn[cpn %in% c("Dirty Conditions", "Sanitation Condition", "Litter Basket / Request",
               "Overflowing Litter Baskets", "Sweeping/Missed-Inadequate",
               "Missed Collection (All Materials)", "Air Quality",
               "Recycling Enforcement")] <- "Sanitation/Cleaning"

cpn[cpn %in% c("Root/Sewer/Sidewalk Condition", "Sidewalk Condition",
               "Sewer")] <- "Sidewalk/Sewer"

cpn[cpn %in% c("Hazardous Materials", "Radioactive Materials",
               "Lead")] <- "Hazardous Materials"

cpn[cpn %in% c("Food Establishment", "Food Poisoning")] <- "Food"

cpn[grep("Taxi", cpn, ignore.case = TRUE)] <- "Taxi"

cpn[cpn %in% c("Baby Formula", "Parent Leadership")] <- "Parenting"

cpn[cpn %in% c("PAINT - PLASTER", "Graffiti")] <- "Paint/Graffiti"

cpn[cpn %in% c("Highway Condition", "Street Condition", "Bridge Condition",
               "Blocked Driveway")] <- "Bridge/Highway/Street"

cpn[cpn %in% c("Homeless Encampment", "Panhandling")] <- "Homeless"

cpn[cpn %in% c("Teaching/Learning/Instruction", "School Maintenance",
               "No Child Left Behind", "Summer Camp")] <- "Schooling"

cpn[cpn %in% c("Posting Advertisement", "Vending")] <- "Illegal Commercial Activity"

cpn[cpn %in% c("Annual/ Cycle Inspection", "Municipal Parking Facility",
               "Poison Ivy", "Squeegee", "Wear & Tear", "X-Ray Machine/Equipment")] <- "Misc."

cpn[grep("Heat", cpn, ignore.case = TRUE)] <- "Heating"
cpn[cpn == "Boilers"] <- "Heating"

cpn[grep("complaint", cpn, ignore.case = TRUE)] <- "Complaint"


# (Updated coding) 
cpn <- tolower(cpn)

cpn[cpn %in% c("adopt-a-basket", "benefit card replacement", "dwd",
               "for hire vehicle report", "gas station discharge lines",
               "hazmat storage/use")] <- "misc."
cpn[cpn %in% c("animal abuse")] <- "animal care"
cpn[cpn %in% c("best/site safety")] <- "health and safety"
cpn[grep("dof ", cpn)] <- "dof request"
cpn[grep("fire ", cpn)] <- "fire alarm request"

temp <- tapply(cpn, cpn, length)
cpn[cpn %in% names(temp[temp < 100])] <- "misc."

# Also create 15 category type (including "other")
type14 <- unique(nyc311$type15)[!grepl("other", unique(nyc311$type15))]
type14 <- as.character(type14)

cpn15 <- ifelse(cpn %in% type14, cpn, "other")

# Bring back into dataset 
newdta$type <- factor(cpn)
newdta$type15 <- factor(cpn15)

# Spatially match with neighborhoods
proj <- "+proj=lcc +lat_1=40.66666666666666 +lat_2=41.03333333333333 +lat_0=40.16666666666666 +lon_0=-74 +x_0=300000 +y_0=0 +datum=NAD83 +units=us-ft +no_defs +ellps=GRS80 +towgs84=0,0,0"
nycnh <- readOGR("data/processed/neighborbound.json", "OGRGeoJSON")
nycnh <- spTransform(nycnh, CRS(proj))

# First project the 311 data 
newdta2 <- newdta %>% filter(!(long %in% NA | lat %in% NA)) #omit NAs for spatial join
newdta.sp <- project(cbind(newdta2$long, newdta2$lat), proj)
newdta.sp <- SpatialPointsDataFrame(SpatialPoints(newdta.sp), newdta2)
proj4string(newdta.sp) <- proj

newdta.sp$neighborhood <- over(newdta.sp, nycnh)$neighborhood
sum(newdta.sp$neighborhood %in% NA) #number of non-matches --> drop
newdta.sp <- newdta.sp[!newdta.sp$neighborhood %in% NA, ]

# Bring back observations without coordinates
newdta1 <- newdta %>% filter(long %in% NA | lat %in% NA)
newdta <- rbind(newdta.sp@data, cbind(newdta1, neighborhood = NA))

# Now update 311 data
#   (1) drop obs. in old data with same key as in new data
#   (2) append new data to old data

rm(newdta1, newdta2, newdta.sp, cpn, cpn15, variables)

# Number of observations that will be updated:
sum(nyc311$key %in% newdta$key)

# Number of observations that will be added:
nrow(newdta) - sum(nyc311$key %in% newdta$key)

# Final number of observations should be:
nrow(nyc311) + nrow(newdta) - sum(nyc311$key %in% newdta$key)

nyc311 <- nyc311 %>% filter(!key %in% newdta$key)
nyc311 <- rbind(nyc311, select(newdta, -updated))

# Number of observations: 
dim(nyc311)

# Previous and new max date, respectively: 
day1 + 2; max(nyc311$opened)

# Write new data 
saveRDS(nyc311, file = "data/processed/nyc311wjoins.rds")

rm(api, day1, day2, grabfirst, i, n, newdta, pkgs, seq.days, type14, temp)




