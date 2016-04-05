
# This script finds summary statistics at various aggregate levels
# and prints the results to data/aggregates

test <- F

# Read data [not needed if running update311.R right before]
if(!exists("nyc311")) nyc311 <- readRDS("data/processed/nyc311wjoins.rds")
if(test) nyc311 <- readRDS("data/processed/nyc311wjoins-sample.rds")

# Check most recent date in data
max(nyc311$opened)
dim(nyc311)

# Add indicators for whether solved in 3 or 5 days
nyc311 <- nyc311 %>%
    mutate(solvedin3 = ifelse(resptime %in% NA | resptime > 3, 0, 1), 
           solvedin5 = ifelse(resptime %in% NA | resptime > 5, 0, 1))

# Add year/month variable
nyc311 <- nyc311 %>% mutate(openedyrm = paste(lubridate::year(opened), lubridate::month(opened, label = T), sep = "-"))

# Add three indicators for whether opened within last year, month, or week
nyc311 <- nyc311 %>%
    mutate(lastyear = ifelse(as.Date(opened) > Sys.Date() - years(1), 1, 0),
           lastmonth = ifelse(as.Date(opened) > Sys.Date() - months(1), 1, 0),
           lastweek = ifelse(as.Date(opened) > Sys.Date() - weeks(1), 1, 0))


#-----------------------------------------------------------------------
# Aggregate data (using 'aggregate_311' in functions.R)

# By neighborhood and 3 time periods (all time, within last month/year) 
agg.n <- rbind(
    aggregate_311(timevar = NA, spatialvar = "neighborhood"), 
    aggregate_311(timevar = NA, spatialvar = "neighborhood",
                  subsetvar = "lastyear", subsetfactor = 1),
    aggregate_311(timevar = NA, spatialvar = "neighborhood",
                  subsetvar = "lastmonth", subsetfactor = 1)
    )


# By neighborhood, year, and request type
agg.nyt <- rbind(
    aggregate_311(timevar = "openedyr", spatialvar = "neighborhood", bytype = F),
    aggregate_311(timevar = "openedyr", spatialvar = "neighborhood", bytype = T),
    aggregate_311(timevar = "openedyr", spatialvar = NA, bytype = F) %>% rename(neighborhood = geography),
    aggregate_311(timevar = "openedyr", spatialvar = NA, bytype = T) %>% rename(neighborhood = geography)
    )

# Create a numeric ID identifying neighborhoods (starting with city-wide, then alpabetic)
sortorder <- na.omit(with(nyc311, c("City-wide", levels(neighborhood)[!levels(neighborhood) %in% "City-wide"])))
agg.nyt <- agg.nyt %>%
    na.omit() %>% 
    mutate(neighborhood = factor(neighborhood, levels = sortorder)) %>%
    arrange(neighborhood) %>%
    ungroup()

agg.nyt$nid <- group_indices(agg.nyt, neighborhood) - 1


#-----------------------------------------------------------------------
# Write files
write.csv(na.omit(agg.n), "app/data/nyc311-byneightime.csv", row.names = F)
write.csv(agg.nyt, "app/data/nyc311-byneighyeartype.csv", row.names = F)


