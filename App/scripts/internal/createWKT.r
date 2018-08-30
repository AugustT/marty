createWKT <- function(latitude, longitude, radius = 5000) {
  
  library(sp)
  library(rgdal)
  library(rgeos)
  
  p <- SpatialPointsDataFrame(coords = data.frame(lon = longitude, lat = latitude),
                              data.frame(ID = 1),
                              proj4string = CRS("+proj=longlat +ellps=WGS84 +datum=WGS84"))
  stopifnot(length(p) == 1)
  cust <- sprintf("+proj=tmerc +lat_0=%s +lon_0=%s +k=1 +x_0=0 +y_0=0 +ellps=WGS84 +towgs84=0,0,0,0,0,0,0 +units=m +no_defs", 
                  p@coords[[2]], p@coords[[1]])
  projected <- spTransform(p, CRS(cust))
  buffered <- gBuffer(projected, width = radius, byid = TRUE)
  bufferedOrg <- spTransform(buffered, p@proj4string)
  writeWKT(bufferedOrg)

}