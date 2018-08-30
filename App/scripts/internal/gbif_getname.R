gbif_getname <- function(x){
  
  require(tools)
  
  all_names_list <- name_lookup(x, rank = 'species', limit = 100)$names
  all_names_list <- all_names_list[grepl(2, lapply(all_names_list, ncol))]
  
  if(is.null(all_names_list)) return(x)
  
  all_names <- do.call(rbind, all_names_list)
  
  if(nrow(all_names) == 0) return(x)
  
  eng_names <- all_names[all_names$language == 'eng',]
  name <- as.character(eng_names$vernacularName[1])
  
  if(!is.na(name)){
    return(data.frame(latin = x, english = (toTitleCase(name)), stringsAsFactors = FALSE))
  } else {
    return(data.frame(latin = x, english = x, stringsAsFactors = FALSE))
  }
  
}