# visreq

This project creates a web app (current version
[here](http://stanford.edu/~ejdemyr/data-vis/311/app/)) that allows
the user to visualize and interact with the large-scale data generated
by [NYC's 311 service request system](https://nycopendata.socrata.com/Social-Services/311-Service-Requests-from-2010-to-Present/erm2-nwe9).


### Overview 

The project has two parts:

1. A set of R scripts gathers the service request data from NYC's open
data portal, spatially matches requests with neighborhood boundaries,
and outputs aggregated summary statistics (by neighborhood, request
type, and/or a time dimension). Because NYC adds and updates the
request data daily, the scripts make it possible to automatically
query new data and add them to the existing (local) database of
service requests.
2. The web app uses the aggregated data to display summary statistics
and visualizations, given a selected neighborhood. Only the `app`
directory is needed to generate the app.


### Data 

Two data sources are used: 

1. Service request data ([2010-present](https://nycopendata.socrata.com/Social-Services/311-Service-Requests-from-2010-to-Present/erm2-nwe9) 
and [2004-2009](https://nycopendata.socrata.com/browse/embed?tags=all+service+requests&utf8=%E2%9C%93)). 
2. [Neighborhood boundaries](http://www.nyc.gov/html/dcp/html/bytes/dwn_nynta.shtml) 
from NYC's department of planning. 

Copies of these data can also be downloaded
[here](https://stanford.app.box.com/s/f21r1llsygh9o59lkop48hm0yl5dza7j).

The R scripts produce smaller and up-to-date versions of these files
(saved in `data/processed`). The scripts also produce data for the
app (saved in `app/data`).


### Software 

* R, including several packages. If you're on a mac, some of the GIS
packages may require that unix frameworks (e.g., gdal and geos) be
installed.
* [topojson](https://github.com/mbostock/topojson) is used to display
neighborhood boundaries.
* Several JavaScript libraries (please refer to `app/index.html`). 


### License 

Creative Commons Attribution-ShareAlike 4.0 International
