
/*
---------------------------------------------------------------------- 
   This script visualizes the 311 data aggregated to neighborhoods 
   given a user selection of a specific neighborhood
----------------------------------------------------------------------
*/

// Function that filters the response data and displays (1) key facts,
// (2) the line graph, and (3) the choropleth map.
// @para name: name of the selected neighborhood
// @para time: the time dimension (in this version there's only one, "All time") 

function visualizeData(name, time) {  
    
    // Filter response data given neighborhood name and time dimension
    var responseFiltered = neighResponse.filter(function(d) {
	return d.neighborhood == name && d.time == time; 
    });
    
    // Display info associated with selected neighborhood
    displayNeighborhoodStats(responseFiltered);

    // Display line graph
    lineGraph(name, ["All"]);
    clearCheckList();

    // Display neighborhood map
    choroplethMap(name);
}

// Function that populates basic statistics about the selected neighborhood
// @para ndta: response data for the selected neighborhood 
function displayNeighborhoodStats(ndta) {
  
    var pcsolved = ndta[0].pcsolved,
	notsolved = ndta[0].nrequests - ndta[0].nsolved,
	rankrt = ndta[0].rankrt;
    
    // Display neighborhood name and info
    $("#neighborhood-div").empty().append("<h1 id='neighborhood-name'> </h1>"); 
    $("#content").css("opacity", 0); 
    
    // Populate neighborhood name (using typed.js) 
    $(function(){
	$("#neighborhood-name").typed({
            strings: ["Neighborhood: " + neighName],
            typeSpeed: 0,
	    showCursor: false,
	    callback: function() {
		// When function is done, remove hidden content: 
		$("#content").removeClass("hidden").css("opacity", 1);
	        $("footer").removeClass("hidden"); 
	    }
	});
    });

    // Populate quick facts
    $(".nname").text(neighName); 
    $(".nrequests").html(d3.format(",d")(ndta[0].nrequests));
    $(".pcsolved").html(pcsolved);
    $(".avgrt").html(ndta[0].avgresptime);
    $(".notsolved").html(d3.format(",d")(notsolved));
    $(".pcnotsolved").html(100 - pcsolved);
    $(".pcrankrt").html(getPercentRank(rankrt, neighN));
    $(".rankrt").html(formatRank(rankrt));
    $(".nneighborhoods").html(neighN);
    $(".today").html(getDate("All time")[0]);
    $(".daterange").html(getDate("All time")[1]);
    
}

// Format the neighborhood's rank 
function formatRank(rankrt) {

    var lastDig = rankrt % 10;
    var lastTwoDig = '00'; 
    var ndigit = (''+rankrt).length; 
    
    if(ndigit >= 2) {
	lastTwoDig = (''+rankrt)[ndigit-2] + (''+rankrt)[ndigit-1]; 
    }

    var append = "th"; 
    if(lastDig == 1 && lastTwoDig != '11') {
	append = "st"; 
    } else if(lastDig == 2 && lastTwoDig != '12') {
	append = "nd";
    } else if(lastDig == 3 && lastTwoDig != '13') {
	append = "rd"; 
    }
	
    return rankrt+append; 
    
}

// Get the neighborhood's rank as a percentage
function getPercentRank(rankrt, nneighborhoods) {

    var pcrank = d3.round(100 * rankrt / nneighborhoods, 0);
    if(pcrank > 50) {
	pcrank = 100 - pcrank; 
	return '<font color="#cb181d">Bottom '+pcrank+'%</font>'
    } else {
	return '<font color="#41ab5d">Top '+pcrank+'%</font>'
    }
      
}

// Get the start and end date for the data
// In this version, there's only one start date (Jan 1, 2004) 
function getDate(time) {

    var monthAbbreviations = [
	"Jan", "Feb", "Mar", "Apr", "May", "June",
	"July", "Aug", "Sep", "Oct", "Nov", "Dec"
    ];
   
    var today = new Date();
    var dd = today.getDate();
    var mm = today.getMonth()+1;
    var mmp = mm - 1; 
    var yyyy = today.getFullYear();
    var yyyyp = yyyy - 1;

    if(mmp==0) { mmp = 12 }

    mm = monthAbbreviations[mm-1];
    mmp = monthAbbreviations[mmp-1]; 

    var monthago = (mmp == 'Dec') ?
	mmp+' '+dd+', '+yyyyp : 
	mmp+' '+dd+', '+yyyy;

    var yearago = mm+' '+dd+', '+yyyyp;

    var date = 'Jan 1, 2004'; 
    if(time == "Within last year") {
	date = yearago; 
    } else if(time == "Within last month") {
	date = monthago; 
    }

    today = mm+' '+dd+', '+yyyy;
    
    return [today, date];
}
