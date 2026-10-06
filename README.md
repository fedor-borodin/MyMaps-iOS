# MyMaps-iOS

An iOS pedestrian navigation prototype developed in 2017 as an internship project at HARMAN.

The project explored an alternative approach to pedestrian navigation by combining
Google Maps routing with visual, step-by-step guidance based on Google Street View.

## How it works

The application uses Google Maps APIs to:

- Geocode origin and destination addresses
- Calculate routes using Google Directions
- Display the route and its start/end points on a map
- Support walking, driving, and bicycling route modes
- Break a route into individual navigation steps
- Retrieve a Google Street View image for each route step
- Calculate the geographic heading between the start and end coordinates of each step
- Orient each Street View image in the direction of travel

For every route step, the application calculates the bearing from its start coordinate
to its end coordinate and passes that value as the `heading` parameter when requesting
the Street View image. This produces visual guidance oriented toward the direction
the user should continue walking.

## Technologies

- Swift
- UIKit
- Google Maps SDK for iOS
- Google Directions API
- Google Geocoding API
- Google Street View API
- Core Location
- URLSession

## Background

This repository contains my HARMAN internship project from 2017. The project is
preserved as originally developed and represents the code and iOS APIs used at that
time rather than my current development practices.

I successfully completed the internship and subsequently joined HARMAN as a
Software Engineer.
