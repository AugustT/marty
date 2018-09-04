# marty
Making citizen science data work for citizen scientists

![appScreenshots](https://github.com/AugustT/marty/raw/master/App/screenshots.jpg "App screenshots")


This R-shiny web app was designed for the 2018 Ebbe Neilson prize by Tom August. Copying and reuse of the code is strongly encouraged.

[Watch a video introduction here](https://youtu.be/-MPH-ETD-aM)

## What does the app do?

“Whats that bird?”, you ask yourself. You open up your guide book. Being new to birding, you hardly know where to start.
Marty is here to point you in the right direction.

Marty is a location-aware smartphone app that shows citizen scientists what birds are likely to be seen in their location, at this time of year. It query’s data collected by thousands of citizen scientists, hosted on GBIF, to produce a ranked list of likely species. This helps narrow down that list of possible species when you’re looking through your guide book.

Marty uses the GBIF APIs to gather data on species present at your location and their numbers as well as their common English names and photographs. The app works anywhere in the world and compiles data from many different sources going back ten years to get the most reliable information for the user.

All the code used to build Marty is open. Want to build an app for French butterflies instead? Edit 2 lines of code and you can publish your own app. Starting a new citizen science project on German spiders? In 30 minutes you could create a bespoke app just for your citizen scientists. 

Marty is just the beginning.


## How does it work?

In simple terms that app uses the loaction of the device accessing it (i.e. a mobile phone), to query GBIF to find out what species are commonly found in that area. These are then displayed along side their English names and images, also sourced from GBIF.

1) GPS is aquired from the the users device. If the user denies access they can still select a location manually
2) GPS is used to create a Well Know Text string (WKT) that describes a 5km buffer around their location (you could change this size)
3) The decimal month of the year (i.e. Janurary = 1) is identified and the bounding moths are also identified (e.g. for Januaray this would be [12,1,2]
4) Taxanomic group, WKT and months are combined to search GBIF for data. Paging is used to update progress bars
5) Species not seen before by the app are looked up on GBIFs taxanomic API to get their English names (you could change language). Progress bar reports progress.
6) Species not seen before by the app are looked up on GBIF to get URLs to images. Progress bar reports progress. 
7) Names and image URLs are cached on the server in the files in the folder `data`, not present in this repository. If you wanted to use your own names or your own images you could add your own tables here.
8) The page is built using the data collected and displayed to the user. Custom CSS is used for the look and feel (`style.css`) for the gallery (`lightbox.css`) and adding the app to the homescreen (`addtohomescreen.css`). There are also three javascript files which control the gallery (`lightbox.js`), the retrieval of GPS data from the device (`www/location.js`), and adding a homescreen link (`www/addtohomescreen.js`).
9) The user can search for a new location in the settings area. This queries the Google Geocode API to get the latitude and longitude and then repeats the same steps. The name of the location used is displayed under the search box once the search is complete.
10) The user can sort the data by Common name or Latin name, again this is in the settings page.

Other info:

- There are various images in the www, these are used to create icons on the homescreen of users devices and to show logos on the about page.


## How to adapt the app for your own needs

### Changing the taxanomic group

The taxaonomy the app is focussed on is set in the internal script `getGBIFdata.r` line 8. Want to search for a different class? Look up the class key on GBIF and replace it here. Want to search a family or order instead, there are arguments for them too, just have a look at `?occ_search` in the R console (its a function from `rgbif`).


### Changing the radius

Easy, edit the script `createWKT.r` on line 1, the radius is set in meters, and the current value is 5000 (i.e. 5km)


### Change the language

Dont want the English names? That is easy too! Edit `gbif_getname.r` on line 14 we currently say we want `'eng'` meaning English. Replace this with a differemt ISO 639-2 Code such as `'fra'` for French.
