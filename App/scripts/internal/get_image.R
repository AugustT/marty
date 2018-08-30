get_image <- function(name){
  
  # cat(name)
  https <- occ_search(scientificName = name, return = 'data', mediaType = 'StillImage', limit = 1, fields = 'http...unknown.org.http_..rs.gbif.org.terms.1.0.Multimedia')
  if(identical(https[1], "no data found, try a different search")) return('No_Image_Available.jpg')
  x1 <- trimws(unlist(strsplit(as.character(https), split = '\n')))
  xt <- x1[grepl('http://purl.org/dc/terms/identifier', x1)]
  xf <- strsplit(xt, split = ' : ')[[1]][2]
  xf <- gsub('^[[:punct:]]+(?=[[:alpha:]])', '', xf, perl = TRUE)
  xf <- gsub('(?<=[[:alnum:]])[[:punct:]]+$', '',  xf, perl = TRUE)
  
  return(xf)
  
}
