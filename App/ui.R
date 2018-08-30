
# This is the user-interface definition of a Shiny web application.
# You can find out more about building applications with Shiny here:
#
# http://shiny.rstudio.com
#

library(shiny)
library(shinyjs)

shinyUI(fluidPage(
  
  useShinyjs(),
  
  tags$head(
    
    HTML(paste0('<meta name="viewport" content="width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=no"/>
          <meta name="mobile-web-app-capable" content="yes">
          <meta name="apple-mobile-web-app-capable" content="yes">
          <meta name="apple-mobile-web-app-title" content="marty">
          <meta name="application-name" content="marty">
          <link rel="icon" href="favicon.ico" type="image/x-icon" >
          <link rel="apple-touch-icon" sizes="57x57" href="apple-touch-icon-57x57.png" >
          <link rel="apple-touch-icon" sizes="72x72" href="apple-touch-icon-72x72.png" >
          <link rel="apple-touch-icon" sizes="76x76" href="apple-touch-icon-76x76.png" >
          <link rel="apple-touch-icon" sizes="114x114" href="apple-touch-icon-114x114.png" >
          <link rel="apple-touch-icon" sizes="120x120" href="apple-touch-icon-120x120.png" >
          <link rel="apple-touch-icon" sizes="144x144" href="apple-touch-icon-144x144.png" >
          <link rel="apple-touch-icon" sizes="152x152" href="apple-touch-icon-152x152.png" >
          <link rel="apple-touch-icon" sizes="180x180" href="apple-touch-icon-180x180.png" >')),
    # Include our custom CSS
    includeCSS("styles.css"),
    includeCSS("lightbox.css"),
    includeCSS('addtohomescreen.css'),
    # includeScript("google_analytics.js"),
    includeScript("jquery-2.1.4.js"),
    includeScript(path = 'www/location.js'),
    includeScript(path = 'www/addtohomescreen.js'),
    tags$script('addToHomescreen({
                                  icon: false
                             });')
  ),

  # Loading text
  div(id = 'loading',
      img(src = 'marty.png', alt = 'marty logo',  style = 'width: 65%; height: 60px'),
      p("Using your location and today's date to build your custom report"),
      img(src = 'images/startup.gif', alt = 'loading', style = 'margin-top: 20px; background: #ffffff85;'),
      br(),
      actionButton("skip_load", "Skip")),
  # No gelocation text
  hidden(h5(id = 'geolocation_denied',
            align = 'center',
            paste("You have denied access to your location.",
                  "To allow access clear your cache for this page", 
                  "and then select 'allow' when prompted"))
  ),
  div(id = 'settings_display',
        tags$b(id = 'location_title', 'Set location manually'),
        br(),
        # checkboxInput('use_man',
        #               'Use different location?',
        #               FALSE),
        # selectInput('hectad_man',
        #             label = NULL,
        #             sort(gsub('.rdata$',
        #                       '',
        #                       list.files('data/hectad_counts/',
        #                                  pattern = '.rdata$'))),
        #             selectize = TRUE,
        #             multiple = FALSE, width = '100px'),
        div(class = 'row',
            div(class = 'span4',
                div(id = 'month_man_div',
                    textInput(inputId = 'location_man',
                              label = NULL, value = '',
                              placeholder = 'e.g. Selbourne, Hampshire',
                              width = '100%')),
                actionButton("submit", "Go", width = '44px')
            )
        ),
        textOutput('googlelocation'),

      
        radioButtons('sortBy',
                     label = 'Sort by',
                     choices = list('Number of records' = 'records',
                                    'Common name' = 'english',
                                    'Scientific name' = 'latin')),
        tags$b(id = 'date_title', 'Show...'),
        br(),
        selectInput('NtoShow',
                    label = NULL,
                    c('All', 'Top 10', 'Top 25', 'Top 50', 'Top 100'),
                    selectize = FALSE,
                    multiple = FALSE,
                    selected = 'Top 50',
                    width = '100px')
  ),
  # hidden(h5(id = 'hectad_unknown',
  #           align = 'center',
  #           paste("The location selected is unknown.",
  #                 "Try selecting a new manual location",
  #                 "in the settings menu"))
  # ),
  htmlOutput('UI'),
  div(id = 'bottom-box'),
  actionButton('setting_button', 'Settings'),
  actionButton('about_button', 'About'),
  hidden(actionButton('about_exit', 'X')),
  hidden(actionButton('settings_exit', 'X')),
  # if odd ie clicked on
  div(id = 'about_display',
      a(href = 'https://www.gbif.org/',
        target = '_blank',
        img(src = 'GBIF-2015-full.png', style = 'width: 93%; max-width: 300px; background-color: white; display: block; margin-top: 8px; margin-left: auto; margin-right: auto; border: 10px; border-style: solid; border-color: white;')),
      p(HTML(paste("marty uses data from the Global Biodiversity Information Facility (GBIF) to show information from birds recorded between 2008-2018.",
              "The list shows the bird species previously recorded in this area (a circle with a radus of 5km) and the number of sightings of each.")),
              style = 'width: 98%; max-width: 300px; font-size: small; text-align: center; color: white; display: block; background-color: dimgray; margin-top: 5px; margin-bottom: 5px; margin-left: auto; margin-right: auto; padding: 1px 1px 1px 1px;'),
      p(HTML(paste0("This app was built by Tom August for the 2018 Ebbe Nielsen competition")),
        style = 'width: 98%; max-width: 300px; font-size: small; text-align: center; color: white; display: block; background-color: dimgray; margin-top: 5px; margin-bottom: 5px; margin-left: auto; margin-right: auto; padding: 1px 1px 1px 1px;')),
  
  includeScript("lightbox.js")
  
))
