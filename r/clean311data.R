
# This file cleans the NYC 311 data, stored in csv files for years 2004-15.
# (The last full date in the dataset is 2015-10-02.) 

# Relative path to csv files with 311 data
path_311 <- "data/original"

# Grab 311 csv files in data directory 
csv_files <- dir(path_311)[grepl("(?=.*311)(?=.*NYC)(?=.*csv)", dir(path_311), perl = T)]
csv_files <- file.path(path_311, csv_files)


#--------------------------------------------------------------------
# Combining All Years:
nyc <- lapply(csv_files, Read_NYC) # Read_NYC function defined in functions.R
nyc <- rbind.fill(nyc)

#--------------------------------------------------------------------
# Clean this data set

# Clean location
nyc <- filter(nyc, location != "")
nyc$long <- as.numeric(gsub("\\(.*?, |\\)", "\\1", nyc$location)) #omit 1st no in loc.
nyc$lat <- as.numeric(gsub(" .*$|\\(|\\,", "\\1", nyc$location))  #omit 2nd no in loc. 
nyc <- select(nyc, -location)

# Clean dates
nyc <- nyc %>% 
    mutate(opened = mdy(substring(opened, 1, 10)), 
           closed = mdy(substring(closed, 1, 10)),
           openedyr = year(opened),
           closedyr = year(closed)) %>%
    filter(openedyr %in% 2004:2015, closedyr %in% 2004:2015 | closedyr %in% NA) 

# Generate response time
nyc <- nyc %>%
    mutate(resptime = as.numeric(difftime(closed, opened, units = "days")),
           resptime = ifelse(resptime >=0, resptime, NA))

# Clean complaint type
cpn <- as.character(nyc$type)

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
commoncat <- data.frame(type = row.names(temp), n = as.numeric(temp), row.names = 1:length(temp)) %>%
    arrange(desc(n))
commoncat <- as.character(commoncat$type)[1:14] #14 most common request types

cpn15 <- ifelse(cpn %in% commoncat, cpn, "other")

# Bring back into dataset 
nyc$type <- factor(cpn)
nyc$type15 <- factor(cpn15)

#--------------------------------------------------------------------
# Write file (temporarily)
saveRDS(nyc, file = "data/processed/nyc311-temp.rds")


# Reassign nyc to nyc311 for clarity in next scripts
nyc311 <- nyc

rm(commoncat, cpn, cpn15, csv_files, nyc, temp)



