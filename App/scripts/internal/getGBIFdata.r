getGBIFdata <- function(WKT, year, progress, max = 10000){
  
  mon <- as.POSIXlt(as.Date(Sys.time()))$mon
  
  occ_meta <- occ_search(hasCoordinate = TRUE,
                   geometry = WKT,
                   year = year,
                   classKey = 212,
                   return = 'meta')
  
  N <- ifelse(occ_meta$count > max, yes = max, no = occ_meta$count)
  
  occ_data <- NULL
  
  if(N!=0){
    for(i in 1:(floor(N/200))){
      for(mon_i in c(mon -1, mon, mon + 1)){
        occ_temp <- occ_search(hasCoordinate = TRUE,
                               geometry = WKT,
                               year = year,
                               month =  mon_i,
                               classKey = 212,
                               fields = c('name',
                                          'taxonRank',
                                          'month'),
                               return = 'data',
                               start = (i*200)-200,
                               limit = 200)
        if(i==0 & mon_i == mon - 1){
          occ_data <- occ_temp
        } else {
          occ_data <- rbind(occ_temp, occ_data)
        }
      }
      progress$set(message = "Gathering data", value = i/(floor(N/200)-1))
    }  
  }
  
  cat(print(table(occ_data$month)))
  
  if(N==0) return(NULL)
  if(is.null(nrow(occ_data))){
    return(NULL)
  } else {
    occ_data <- occ_data[occ_data$taxonRank == 'SPECIES',]
    if(nrow(occ_data) == 0){
      return(NULL)
    } else {
      otab <- as.data.frame(table(occ_data$name))
      names(otab) <- c('latin', 'freq')
      return(otab)  
    }    
  }
}