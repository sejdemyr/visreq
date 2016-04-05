
#-----------------------------------------------------------------------
# Smaller functions
#-----------------------------------------------------------------------

# Supress warnings 
sW <- suppressWarnings

# Multi-line batch scripts in R
s <- function(cmd) system(strwrap(cmd, simplify=T, width=10000))

#-----------------------------------------------------------------------
# Function for converting single polygon to sp polygon
#-----------------------------------------------------------------------

convertSP <- function(spp, dta) {
    sp <- SpatialPolygons(list(Polygons(list(spp), ID = rnorm(1))))
    row.names(dta) <- sW(getSpPPolygonsIDSlots(sp))
    SpatialPolygonsDataFrame(sp, dta)
}


#-----------------------------------------------------------------------
# Function for reading in each csv file with 311 data
#-----------------------------------------------------------------------

Read_NYC <- function(file) {

    df <- fread(file, header = T, sep = ',',
                select = c("Unique Key", "Location", "Created Date",
                           "Closed Date", "Complaint Type")) %>%
          as.data.frame() 

    names(df) <- sub(" ", ".", tolower(names(df)))

    df <- df %>%
        rename(key = unique.key,
               opened = created.date,
               closed = closed.date,
               type = complaint.type)

    return(df) 
}


#-----------------------------------------------------------------------
# Function for aggregating data by spatial and/or time dimension. 
# 'timevar' and 'spatialvar' are character strings specifying
# dimensions along which to aggregate data (specify as NA if given
# dimension is not needed). If bytype = T, type15 is used to aggregate
# data by type of request. If subsetvar is not NA, subsetfactor is
# used to subset the data before finding aggregates.
#-----------------------------------------------------------------------

aggregate_311 <- function(dta = nyc311, timevar, spatialvar, bytype = F,
                          subsetvar = NA, subsetfactor = NA) {

    # Subset data (if applicable)
    if(!subsetvar %in% NA) {
        dta <- plyr::rename(dta, replace = setNames("subvar", subsetvar))
        dta <- dta %>% filter(subvar == subsetfactor)
    }
    
    # Find grouping variables
    aggvars <- c(timevar, spatialvar)
    aggvars <- aggvars[!aggvars %in% NA]
    if(bytype) aggvars <- c(aggvars, "type15")

    if(all(is.na(aggvars))) stop("All grouping variables are missing")

    # Find summary statistics using grouping variables
    aggdta <- dta %>%
        group_by_(.dots = aggvars) %>%
        summarise(nrequests = n(),
                  nsolved = length(key[!closed %in% NA]),
                  pcsolved = (nsolved / nrequests) * 100, 
                  avgresptime = mean(resptime, na.rm = T),
                  pcsolvedin3 = mean(solvedin3) * 100,
                  pcsolvedin5 = mean(solvedin5) * 100)

    # Find ranks
    aggdta <- aggdta %>% 
        mutate(
            rankrt = frankv(avgresptime, ties.method = "min", na.last = "keep"),
            rankpcs3 = frankv(-pcsolvedin3, ties.method = "min", na.last = "keep"), 
            rankpcs5 = frankv(-pcsolvedin5, ties.method = "min", na.last = "keep")
            )

    # Add variable to identify spatial dimension 
    if(spatialvar %in% NA) {
        aggdta <- aggdta %>% mutate(geography = "City-wide") 
    } else if(spatialvar == "ccdistrict") {
        aggdta <- aggdta %>% ungroup() %>%
            mutate(ccdistrict = paste("City Council", ccdistrict))
    }

    # Add variable to identify request type dimension
    if(!bytype) {
        aggdta <- aggdta %>% mutate(requesttype = "All")
    } else {
        aggdta <- aggdta %>% rename(requesttype = type15)
    }

    # Add variable to identify time dimension (not included if not specified)    
    if(timevar %in% NA) {
        aggdta <- aggdta %>% mutate(time = "All time")
    } else if(timevar == "openedyr") {
        aggdta <- aggdta %>% rename(year = openedyr)
    } else if(timevar == "openedyrm") {
        aggdta <- aggdta %>% rename(yrmonth = openedyrm)
    }

    # Add variable to identify subset (if applicable)
    if(!subsetvar %in% NA & subsetvar == "lastyear") {
        aggdta <- aggdta %>% mutate(time = "Within last year")
    } else if(!subsetvar %in% NA & subsetvar == "lastmonth") {
        aggdta <- aggdta %>% mutate(time = "Within last month")
    } else if(!subsetvar %in% NA & subsetvar == "lastweek") {
        aggdta <- aggdta %>% mutate(time = "Last week")
    }

    # Move key-variables first 
    if("time" %in% names(aggdta)) {
        aggdta <- aggdta %>% select(time, requesttype, everything())
    } else {
        aggdta <- aggdta %>% select(requesttype, everything())
    }
    
    return(aggdta)
}


#-----------------------------------------------------------------------
# Function for creating new variable with shorter neighborhood names
#-----------------------------------------------------------------------

rename_neighborhoods <- function(dta, oldvar, newvar) {

    dta[, newvar] <- gsub("-", "/", dta[, oldvar])
    dta[, newvar] <- revalue(dta[, newvar], c(
        "Co/op City" = "Co-op City", 
        "Breezy Point/Belle Harbor/Rockaway Park/Broad Channel" = "Breezy Point/Belle Harbor",
        "West New Brighton/New Brighton/St. George" = "New Brighton/St. George",
        "Central Harlem North/Polo Grounds" = "Central Harlem North", 
        #"Queensbridge/Ravenswood/Long Island City" = "Long Island City"
        ))

}


