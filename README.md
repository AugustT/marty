# marty
Making citizen science data work for citizen scientists

![appScreenshots](https://github.com/AugustT/marty/raw/master/App/screenshots.jpg "App screenshots")


This R-shiny web app was designed for the 2018 Ebbe Neilson prize by Tom August. Copying and reuse of the code is strongly encouraged.

In simple terms that app uses the loaction of the device accessing it (i.e. a mobile phone), to query GBIF to find out what species are commonly found in that area. These are tehn displayed along side their English names and images, also source from GBIF.

# How can I use this to make a new app?

This is only the beginning. Want to make an app for French butterflies, no problem!

## Changing the taxanomic group

The taxaonomy the app is focussed is set in the internal script `getGBIFdata.r` line 8. Want to search for a different class? Look up the class key on GBIF and replace it here. Want to search a family or order instead, there are arguments for them too, just have a look at (`?occ_search`)

## Changing the radius

Easy, edit the script `createWKT.r` on line 1, the radius is set in meters, and the current value is 5000 (i.e. 5km)

## Change the language

Dont want the English names? That is easy too! Edit `gbif_getname.r` on line 14 we currently say we want 'eng' meaning English. Replace this with a differemt ISO 639-2 Code such as 'fra' for French.
