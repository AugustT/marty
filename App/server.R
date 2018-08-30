# This is the server logic for a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#
rm(list = ls())
library(shiny)
library(shinyjs)
library(sp)
library(RCurl)
library(RJSONIO)
library(plyr)
library(rgbif)

print(Sys.time())

source_scripts <- list.files('scripts/internal/', full.names = TRUE)
for(i in source_scripts) source(i)

species_names <- read.csv('data/species_names.csv', stringsAsFactors = FALSE)

images <- read.csv('data/image_urls.csv', stringsAsFactors = FALSE)

shinyServer(function(input, output, session) {

  observe({
    if(!is.null(input$lat)){
      cat(paste('lat:', input$lat))
      cat(paste('\nlong:', input$long))
    }
  })
  
  # read in the google location when the button is pressed
  location_man <- eventReactive(input$submit, {

    return(input$location_man)
  })
  
  GCode <- reactive ({
    textLocation <- location_man()
    cat('\n', textLocation, '\n')
    str(textLocation)
    GCode <- geoCode(paste0(as.character(textLocation)))
    return(GCode)
  })
  
  output$googlelocation <- renderText({
    cat('\n', GCode()[4], '\n')
    if(is.na(GCode()[4])){
      return('Location unknown')
    } else {
      shinyjs::hide(id = 'about_display', anim = TRUE,
                    animType = 'fade', time = 0.2)
      shinyjs::hide(id = 'settings_display', anim = TRUE,
                    animType = 'fade', time = 0.2)
      shinyjs::hide(id = 'settings_exit',  anim = TRUE,
                    animType = 'fade', time = 0.2)
      shinyjs::hide(id = 'about_exit',  anim = TRUE,
                    animType = 'fade', time = 0.2)
      shinyjs::show(id = 'about_button', anim = TRUE,
                    animType = 'fade', time = 0.2)
      shinyjs::show(id = 'setting_button', anim = TRUE,
                    animType = 'fade', time = 0.2)
      return(GCode()[4])
    }
  })

  # Select lat_long to use
  lat_long <- reactive({
    if(input$skip_load > 0 & input$submit == 0){
      return('skip')
    } else if(!is.null(input$lat) & input$submit == 0){
      c(input$lat, input$long)
    } else if(location_man() != ''){
      
      GCode_progress <- shiny::Progress$new()
      # Make sure it closes when we exit this reactive, even if there's an error
      on.exit(GCode_progress$close())
      
      GCode_progress$set(message = "Resolving location", value = 0.2)
      
      GCode <- GCode()
      
      if(any(is.na(GCode[1:2]))){ # error message like no data
        
        return(NULL)
        
      }
      
      lat <- as.numeric(GCode[1])
      long <- as.numeric(GCode[2])
      
      cat(lat,long) # without this cat the next line fails
      # I HAVE NO IDEA WHY!
      
      GCode_progress$set(message = "Resolving location", value = 1)
      
      return(c(lat, long))
      
      # input$hectad_man
    } else {
      return(NULL)
    }
  })
  
  # If geolocation is not give this is displayed
  # and the loading text is hidden
  observe({
    if(!is.null(input$geolocation) & is.null(input$lat)){
      cat(paste('Geo:', input$geolocation))
      if(!input$geolocation & input$submit == 0){
        shinyjs::hide('loading', anim = FALSE)
        shinyjs::show(id = 'geolocation_denied', anim = TRUE, animType = 'fade')
      } else if(!input$geolocation & location_man() != ''){
        shinyjs::hide(id = 'geolocation_denied', anim = TRUE, animType = 'fade')
      }
    } 
  })
  
  # dayMonth <- reactive({
  #   if(!input$use_date){
  #     format(Sys.time(), '%d-%b')
  #   } else if(input$use_date){
  #     paste(input$day_man,
  #           input$month_man,
  #           sep = '-')
  #   }
  # })
  # 
  # jDay <- reactive({
  #   as.POSIXlt(as.Date(dayMonth(), '%d-%b'))$yday
  # })
  
  # Gather the data
  speciesData_raw <- reactive({
    if(input$skip_load > 0 & input$submit == 0){
      cat(paste('\nHectad:', 'skip', '\n'))
      return('skip')
    } else if(!is.null(lat_long())){
      
      cat(paste('\nLocation:', paste(lat_long(), collapse = ', '), '\n'))
      
      GetData_progress <- shiny::Progress$new()
      # Make sure it closes when we exit this reactive, even if there's an error
      on.exit(GetData_progress$close())

      GetData_progress$set(message = "Gathering data", value = 0.01)

      lat_long <- lat_long()
      WKT <- createWKT(latitude = lat_long[1],
                       longitude = lat_long[2])
      
      # Get data from within this buffer
      # recData <- list()
      # for(i in 10){
        # y <- as.character(2007+i)
        recData <- try(getGBIFdata(WKT = WKT, year = paste0(2012, ', ', 2018), progress = GetData_progress, max = 200), silent = TRUE)  
        # recData <- c(recData, recTemp)
        # GetData_progress$set(message = "Gathering data", value = i/10)
      # }
      
      GetData_progress$close()
      on.exit()
      
      # recData <- do.call(rbind, recData)  
      cat(str(recData))
      if(class(recData) == 'try-error'){
        return('error')
      } else if(identical(recData, NA)){
        return(NA)
      } else if(nrow(recData) == 0){
        return(NULL)
      } else {

        # Add the english names
        recData$english <- species_names$english[match(recData$latin, species_names$latin)]
        
        if(any(is.na(recData$english))){
          
          names_needed <- recData$latin[is.na(recData$english)]
          
          Getnames_progress <- shiny::Progress$new()
          # Make sure it closes when we exit this reactive, even if there's an error
          on.exit(Getnames_progress$close())
          
          Getnames_progress$set(message = "Gathering names", value = 0.001)
          
          for(n in 1:length(names_needed)){
          
            if(n == 1){ 
              names_to_add <- gbif_getname(names_needed[n])
            } else {
              names_temp <- gbif_getname(names_needed[n])
              names_to_add <- rbind(names_to_add, names_temp)
            }
            # cat(names_needed[n])
            Getnames_progress$set(message = "Gathering names", value = n/length(names_needed))
          }
          
          species_names <- rbind(species_names, names_to_add)
          write.csv(species_names, file = 'data/species_names.csv', row.names = FALSE)
          
          recData$english <- species_names$english[match(recData$latin, species_names$latin)]
          Getnames_progress$close()
        }
        
        # Add the images
        recData$image <- images$image[match(recData$latin, images$latin)]
        
        if(any(is.na(recData$image))){
          
          images_needed <- as.character(recData$latin[is.na(recData$image)])
          
          GetImages <- shiny::Progress$new()
          # Make sure it closes when we exit this reactive, even if there's an error
          on.exit(GetImages$close())
          
          GetImages$set(message = "Finding images", value = 0.001)
          
          for(n in 1:length(images_needed)){
            
            if(n == 1){ 
              images_to_add <- data.frame(latin = images_needed[n],
                                          image = get_image(images_needed[n]))
            } else {
              images_temp <- data.frame(latin = images_needed[n],
                                        image = get_image(images_needed[n]))
              images_to_add <- rbind(images_to_add, images_temp)
            }
            # cat(images_needed[n])
            GetImages$set(message = "Finding images", value = n/length(images_needed))
          }
          
          species_names <- rbind(images, images_to_add)
          write.csv(species_names, file = 'data/image_urls.csv', row.names = FALSE)
          
          recData$image <- as.character(species_names$image[match(recData$latin, species_names$latin)])
          
        }
        return(recData)
      }
    }
  }) 
  
  # Sort the data
  speciesData <- reactive({
    
    if(any(identical(speciesData_raw(), 'notuk'),
           identical(speciesData_raw(), 'skip'),
           identical(speciesData_raw(), NA),
           identical(speciesData_raw(), 'error'),
           is.null(speciesData_raw()))){
      return(speciesData_raw())
    }
    
    if(nrow(speciesData_raw()) != 0){
      speciesData_raw <- speciesData_raw()
      cat(str(speciesData_raw))
      if(input$sortBy == 'records'){
        return(speciesData_raw[order(speciesData_raw$freq, decreasing = TRUE), ])
      } else if(input$sortBy == 'english'){
        return(speciesData_raw[order(speciesData_raw$english, decreasing = TRUE), ])
      } else if(input$sortBy == 'latin'){
        return(speciesData_raw[order(speciesData_raw$latin), ])
      }
    } else {
      return(speciesData_raw)
    }
  })
  
  # how many species to show
  n_to_show <- reactive({
    
    if(input$NtoShow == 'All'){
      return(nrow(speciesData()))
    } else if(input$NtoShow == 'Top 10'){
      return(min(nrow(speciesData()), 10))
    } else if(input$NtoShow == 'Top 25'){
      return(min(nrow(speciesData()), 25))
    } else if(input$NtoShow == 'Top 50'){
      return(min(nrow(speciesData()), 50))
    } else if(input$NtoShow == 'Top 100'){
      return(min(nrow(speciesData()), 100))
    }
    
  })

  # Build species divs
  divList <- reactive({
    
    if(!is.null(lat_long())){
      
      html <- list()
      
      speciesData <- speciesData()
      
      cat(str(speciesData))
 
      if(identical(speciesData, 'skip')){
        temp_html <- tags$div(id = 'nodata',
                              align = 'center',
                              tags$span('Please choose a location in the settings menu')
                              )
        
        html <- list(temp_html)
        
      } else {
      
      
          Report_progress <- shiny::Progress$new()
        # Make sure it closes when we exit this reactive, even if there's an error
        on.exit(Report_progress$close())
        
        Report_progress$set(message = "Building report", value = 0.1)        
        
        # If data are present build the species panels
        if(!is.null(speciesData)){
          
          # Add location div at the top
          hec_div <- tags$div(id = 'tet_top',
                              align = 'center',
                              tags$div(span('Showing local birds')
                              )
          )
          
          html <- append(html, list(hec_div))
          
          for(i in 1:n_to_show()){
            
            # big_phenology <- speciesData[i, 'phenobig']
            # small_phenology <- speciesData[i, 'phenosmall']
            # 
            # # Create species gallery links
            galleryLinks <- list()
            # 
            # sp_name <- gsub('.', '', gsub('/', '', gsub(' ', '_', speciesData[i, 'NAME'])), fixed = TRUE)
            # images_dir <- 'www/images/species'
            # species_dir <- file.path(images_dir, sp_name)
            # thumb_dir <- file.path(images_dir, sp_name, 'thumbnail')
            # 
            # if(dir.exists(species_dir)){ 
            #   # there is a folder for this species
            #   if(dir.exists(thumb_dir)){
            #     # thumbnail dir exists
            #     # add thumbnail
            #     thumb_images <- list.files(thumb_dir, pattern = 'jpg$')
            #     thumb_small <- thumb_images[grep('^thumbnail_', thumb_images)][1]
            #     thumb_big <- thumb_images[grep('^thumbnail_', thumb_images, invert = TRUE)][1]
            #     thumb_credit <- image_information$CONTRIBUTOR[image_information$FILENAME == thumb_big]
            #     
            #     gal_temp <-  tags$a(href = gsub('^www/', '', file.path(thumb_dir, thumb_big)),
            #                         'data-lightbox' = speciesData[i,'new_binomial'],
            #                         'data-title' = paste(speciesData[i,'new_englishname'],
            #                                              speciesData[i,'new_binomial'],
            #                                              paste('Credit: ', thumb_credit[1]),
            #                                              sep = ' - '),
            #                         style = 'width: 100%',
            #                         div(style = paste("background: url('",
            #                                           gsub('^www/', '', file.path(thumb_dir, thumb_small)),
            #                                           "') no-repeat center center; width: 100%; height: 124px;", sep = ''))
            #                         )
            #     
            #     galleryLinks <- append(galleryLinks, list(gal_temp))
            #     
            #     # Then add the rest of the gallery
            #     if(length(list.files(species_dir, pattern = 'jpg$')) > 0 ){
            #       # If there are gallery images
            #       for(j in list.files(species_dir, pattern = 'jpg$')){
            #         
            #         im_credit <- image_information$CONTRIBUTOR[image_information$FILENAME == j]
            #         
            #         gal_temp <- tags$a(href = gsub('^www/', '', file.path(species_dir, j)),
            #                            'data-lightbox' = speciesData[i, 'new_binomial'],
            #                            'data-title' = paste(speciesData[i, 'new_englishname'],
            #                                                 speciesData[i, 'new_binomial'],
            #                                                 paste('Credit: ', im_credit[1]),
            #                                                 sep = ' - '))
            #         galleryLinks <- append(galleryLinks, list(gal_temp))
            #         
            #       }
            #     }
            #   } else {
            #     # If no thumbnail exists
            #     # use 'no image'
            #     thumb_small <- 'images/no_image_thumb.gif'
            #     thumb_big <- 'images/no_image.gif'
            #     
            #     gal_temp <-  tags$a(href = thumb_big,
            #                         'data-lightbox' = speciesData[i, 'new_binomial'],
            #                         'data-title' = paste(speciesData[i,'new_englishname'],
            #                                              speciesData[i,'new_binomial'],
            #                                              'No image available', sep = ' - '),
            #                         img(src = thumb_small,
            #                             tabindex = 1,
            #                             align = 'middle',
            #                             height = '100%',
            #                             alt = 'No species'))
            #     galleryLinks <- append(galleryLinks, list(gal_temp))
            #     
            #   }
            #   
            # } else {
              # there is no image folder for this species
              # use 'no image'
              # thumb_small <- 'images/no_image_thumb.gif'
              # thumb_big <- 'images/no_image.gif'
              imageURL <- as.character(speciesData[i,'image'])
              cat(imageURL)
              
              gal_temp <-  tags$a(href = imageURL,
                                  'data-lightbox' = speciesData[i, 'latin'],
                                  'data-title' = paste(speciesData[i,'english'],
                                                       speciesData[i,'latin'],
                                                       ' - No image available'),
                                  img(src = imageURL,
                                      tabindex = 1,
                                      align = 'middle',
                                      height = '100%',
                                      alt = 'No species'))
              galleryLinks <- append(galleryLinks, list(gal_temp))
            # }

            gallery <- tagList(galleryLinks)

            # Create the species div
            temp_html <- tags$div(id = 'species',
                                  align = 'center',

                                 ## left image
                                 tags$div(id = 'image',
                                          HTML(as.character(htmltools::renderTags(gallery)$html))
                                 ),

                                 ## Right text
                                 tags$div(id = 'speciestext',
                                      p(strong(speciesData[i,'english']),
                                        em(paste0('(', speciesData[i,'latin'], ')')),
                                        style = 'margin: 0px 0 0px;'),
                                      tags$span(paste(speciesData[i,'freq'],
                                                      ifelse(speciesData[i,'freq'] > 1, 'records', 'record'))
                                                ),
                                      br()#,
                                      ## Phenology plot
                                      # a(href = big_phenology,
                                      #   'data-lightbox' = big_phenology,
                                      #   'data-title' = paste('Phenology:',
                                      #                        speciesData[i,'new_englishname'],
                                      #                        speciesData[i,'new_binomial'],
                                      #                        sep = ' - '),
                                      #   img(src = small_phenology,
                                      #       align = 'middle',
                                      #       tabindex = 1,
                                      #       width = '100%',
                                      #       alt = paste('Phenology:',
                                      #                   speciesData[i,'new_englishname'],
                                      #                   speciesData[i,'new_binomial'],
                                      #                   sep = ' - ')))
                             )
            )

            html <- append(html, list(temp_html))

            # If this the last species say what show length we are working with
            if(i == n_to_show()){
              
              # Create the species div
              show_n_html <- tags$div(id = 'show_n',
                                    align = 'center',
                                    
                                    ## left image
                                    tags$div(id = 'show_length',
                                             paste('Showing', input$NtoShow, '- this can be changed in settings')
                                    ))
              
              html <- append(html, list(show_n_html))
              
            }
            
            Report_progress$inc(0.9/n_to_show())        
            
          } # end of species loop
        } else { # No data available
          
          if(is.null(lat_long())){
            temp_html <- tags$div(id = 'nodata',
                                  align = 'center',
                                  tags$span('Unknown location: please choose a new location in the settings menu')
            )
          } else if(is.null(speciesData())){
            temp_html <- tags$div(id = 'nodata',
                                  align = 'center',
                                  tags$span('There are no records of moths in this area at this time of year')
                                  )
          } else if(speciesData() == 'error'){
            temp_html <- tags$div(id = 'nodata',
                                  align = 'center',
                                  tags$span('Whoops... looks like the GBIF servers are having some problems. Try again later.')
            )
          }
          
          
          html <- list(temp_html)
          
        }
      }

      tagList(html)
    } 
  })

  # output species divs
  output$UI <- renderUI({
    
    divList()
    
  })
  
  # output species divs
  output$day_selector <- renderUI({
    # tagList(
      selectInput('day_man',
                  label = NULL,
                  selected = as.numeric(format(Sys.Date(), '%d')),
                  1:monthsdays(input$month_man),
                  selectize = TRUE,
                  multiple = FALSE, width = '60px')    
    # )
  })
  
  # Loading div
  observe({
    if(!is.null(divList())){
      hide('loading', anim = FALSE)
    }
  })
  

  ###############################
  ## Settings and About boxes ###
  ###############################
  
  outputOptions(output, 'day_selector', suspendWhenHidden=FALSE)
  
  # Settings button
  observeEvent(input$setting_button,
                {
                  shinyjs::show(id = 'settings_display', anim = TRUE,
                                animType = 'fade', time = 0.2)
                  shinyjs::show(id = 'settings_exit',  anim = TRUE,
                                animType = 'fade', time = 0.2)
                  shinyjs::hide(id = 'about_button', anim = TRUE,
                                animType = 'fade', time = 0.2)
                  shinyjs::hide(id = 'about_display', anim = TRUE,
                                animType = 'fade', time = 0.2)
                })
  
  # Settings close button
  observeEvent(input$settings_exit,
                {
                  shinyjs::hide(id = 'about_display', anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::hide(id = 'settings_display', anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::hide(id = 'settings_exit',  anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::hide(id = 'about_exit',  anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::show(id = 'about_button', anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::show(id = 'setting_button', anim = TRUE,
                       animType = 'fade', time = 0.2)
                })
  
  # About button
  observeEvent(input$about_button,
                {
                  shinyjs::hide(id = 'settings_display', anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::show(id = 'about_exit',  anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::show(id = 'about_display',  anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::hide(id = 'setting_button', anim = TRUE,
                       animType = 'fade', time = 0.2)
                })
  
  # # About close button
  observeEvent(input$about_exit,
                {
                  shinyjs::hide(id = 'about_display', anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::hide(id = 'settings_display', anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::hide(id = 'settings_exit',  anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::hide(id = 'about_exit',  anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::show(id = 'about_button', anim = TRUE,
                       animType = 'fade', time = 0.2)
                  shinyjs::show(id = 'setting_button', anim = TRUE,
                       animType = 'fade', time = 0.2)
                })

})
