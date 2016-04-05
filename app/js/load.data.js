
/*
---------------------------------------------------------------------- 
   This script defines a few globals and loads three datasets
----------------------------------------------------------------------
*/


// Define globals
var neighborhoods,             // neighborhood boundaries 
    neighN,                    // number of neighborhoods 
    neighPoly = [],            // to construct google maps polygons 
    neighResponse,             // service response data by neighborhood
    nhbytype,                  // service response data by type, neighborhood, year
    requesttypes = [],         // unique request types
    neighName = "Astoria",     // currently selected neighborhood (start with random)
    uniqueNeighborhoods = [];  // list of neighborhoods


// Load neighborhood polygon data 
d3.json("data/neighborbound.topo.json", function(error, dta) {
    if (error) return console.warn(error);

    neighborhoods = topojson.feature(dta, dta.objects.neighborbound); 
    console.log(neighborhoods); 

    if (typeof google !== "undefined") {
	initAutocomplete();
    }

    // Draw choropleth (hidden initially) 
    choroplethMap(neighName); 
    
}); 

// Load service request data (neighborhood level, three time periods) 
d3.csv("data/nyc311-byneightime.csv", function(error, dta) {
    if (error) return console.warn(error);

    neighResponse = dta.map(function(d) {
	return {
	    neighborhood: d.neighborhood,
	    time: d.time, 
	    rankrt: +d.rankrt,
	    pcsolved: d3.round(+d.pcsolved, 0), 
	    pcsolvedin5: d3.round(+d.pcsolvedin5, 0), 
	    avgresptime: d3.round(+d.avgresptime, 0),
	    nrequests: +d.nrequests,
	    nsolved: +d.nsolved	   
	};	
    });

    // Number of neighborhoods 
    neighN = neighResponse.filter(function(d) { return d.time == "All time"; }).length;
    
});

// Load service request data (neighborhood level and city level, by year and type)
d3.csv("data/nyc311-byneighyeartype.csv", function(error, dta) {
    if (error) return console.warn(error);

    nhbytype = dta.map(function(d) {
	return {
	    neighborhood: d.neighborhood,
	    nid: +d.nid, 
	    year: +d.year, 
	    requesttype: d.requesttype, 
	    rankrt: +d.rankrt,
	    pcsolvedin5: d3.round(+d.pcsolvedin5, 0),	  	   
	    avgresptime: d3.round(+d.avgresptime, 0)	   
	};
    });

    // Get unique request types
    nhbytype.filter(function(d) {
	return d.year == 2004 && d.neighborhood == "City-wide"; 
    }).forEach(function(d) {	
	requesttypes.push(d.requesttype);
    }); 

    // Get unique neighborhoods
    nhbytype.filter(function(d) {
	return d.year == 2015 && d.requesttype == "All"; 
    }).forEach(function(d) {	
	uniqueNeighborhoods.push(d.neighborhood);
    }); 
    
    // Draw line graph and add check-boxes 
    lineGraph(neighName, ["All"]);
    checkboxes(); 

}); 
