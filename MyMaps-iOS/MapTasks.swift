//
//  MapTasks.swift
//  MyMaps-iOS
//
//  Created by Admin on 15/05/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import Foundation
import CoreLocation.CLLocation

class MapTasks: NSObject {
    
    // Geocoding properties
    let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"           // URL to request geocoding from
    var lookupAddressResults: [String:AnyObject]!                                       // Dictionary storage for address and coordinates data received
    var fetchedFormattedAddress: String!
    var fetchedAddressLongtitude: Double!
    var fetchedAddressLatitude: Double!
    
    // Directions properties
    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json?"     // URL to request directions from
    var selectedRoute: [String:AnyObject]!                                              // Dictionaryt storage for route data received
    var overviewPolyline: [String:AnyObject]!                                           // Dictionary storage with polyline points to draw
    var originCoordinate: CLLocationCoordinate2D!
    var destinationCoordinate: CLLocationCoordinate2D!
    var originAddress: String!
    var destinationAddress: String!
    var totalDistanceInMeters: UInt = 0
    var totalDistance: String!
    var totalDurationInSeconds: UInt = 0
    var totalDuration: String!
    
    // Streetview properties
    let baseURLStreetview = "https://maps.googleapis.com/maps/api/streetview?"          // URL to request streetview image from
    var streetViewImageData: Data!
    var headingAngle: Int = 0
    var defaultStreetViewFov = 90
    var defaultStreetViewPitch = 0
    
    override init() {
        super.init()
    }
    
    // Main Geocoding method
    func geocodeAddress(address: String!, withCompletionHandler completionHandler: @escaping ((String, Bool) -> Void)) {
        if let lookupAddress = address {
            let geocodeURLString = baseURLGeocode + "address=" + lookupAddress.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
            
            guard let geocodeURL = URL(string: geocodeURLString) else { return }
            let request = URLRequest(url: geocodeURL)
            let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                if error == nil, let usableData = data {
                    do {
                        let dictionary = try JSONSerialization.jsonObject(with: usableData, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:AnyObject]
                        
                        let status = dictionary["status"] as! String
                        
                        if status == "OK" {
                            let allResults = dictionary["results"] as! Array<[String:AnyObject]>
                            self.lookupAddressResults = allResults[0]
                            
                            self.fetchedFormattedAddress = self.lookupAddressResults["formatted_address"] as! String
                            let geometry = self.lookupAddressResults["geometry"] as! [String:AnyObject]
                            self.fetchedAddressLongtitude = ((geometry["location"] as! [String:AnyObject])["lng"] as! NSNumber).doubleValue
                            self.fetchedAddressLatitude = ((geometry["location"] as! [String:AnyObject])["lat"] as! NSNumber).doubleValue
                            
                            completionHandler(status, true)
                        } else {
                            completionHandler(status, false)
                        }
                    } catch {
                        //print("Error parsing JSON")
                        completionHandler("Error parsing JSON", false)
                    }
                } else {
                    //print(error!)
                    completionHandler(error as! String, false)
                }
            }
            task.resume()
        }
    }
    
    // Main Directions method
    func getDirections(from origin: String!, to destination: String!, waypoints: Array<String>!, travelMode: TravelModes!, completionHandler: @escaping ((String, Bool) -> Void)) {
        if let originLocation = origin {
            if let destinationLocation = destination {
                var directionsURLString = baseURLDirections + "origin=" + originLocation.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)! + "&destination=" + destinationLocation.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                
                if let routeWaypoints = waypoints {
                    if routeWaypoints.count > 0 {
                        directionsURLString += "&waypoints=optimize:true"//.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                    }
                    
                    for waypoint in routeWaypoints {
                        directionsURLString += ("|" + waypoint)//.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                    }
                }
                
                if (travelMode) != nil {
                    var travelModeString = ""
                    
                    switch travelMode.rawValue {
                    case TravelModes.walking.rawValue:
                        travelModeString = "WALKING"
                    case TravelModes.bicycling.rawValue:
                        travelModeString = "BICYCLING"
                    default:
                        travelModeString = "DRIVING"
                    }
                    
                    directionsURLString += ("&mode=" + travelModeString)//.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                }
                
                guard let directionsURL = URL(string: directionsURLString) else {
                    //print("Error while fetching  directions")
                    completionHandler("Error while fetching directions", false)
                    return
                }
                let request = URLRequest(url: directionsURL)
                let task = URLSession.shared.dataTask(with: request) { (data, response, error) in
                    if error == nil, let usableData = data {
                        do {
                            let dictionary = try JSONSerialization.jsonObject(with: usableData, options: JSONSerialization.ReadingOptions.mutableContainers) as! [String:AnyObject]
                            
                            let status = dictionary["status"] as! String
                            
                            if status == "OK" {
                                self.selectedRoute = (dictionary["routes"] as! Array<[String:AnyObject]>)[0]
                                self.overviewPolyline = self.selectedRoute["overview_polyline"] as! [String:AnyObject]
                                
                                let legs = self.selectedRoute["legs"] as! Array<[String:AnyObject]>
                                
                                let startLocationDictionary = legs[0]["start_location"] as! [String:AnyObject]
                                self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! Double, startLocationDictionary["lng"] as! Double)
                                
                                let endLocationDictionary = legs[legs.count - 1]["end_location"] as! [String:AnyObject]
                                self.destinationCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! Double, endLocationDictionary["lng"] as! Double)
                                
                                self.originAddress = legs[0]["start_address"] as! String
                                self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
                                
                                self.calculateTotalDistanceAndDuration()
                                
                                completionHandler(status, true)
                            } else {
                                // status in JSON data was not OK
                                completionHandler(status, false)
                            }
                        } catch {
                            //could not parse JSON
                            completionHandler("Error parsing JSON", false)
                        }
                    } else {
                        // error in URLRequest
                        completionHandler(error! as! String, false)
                    }
                }
                task.resume()
            } else {
                completionHandler("Destination is nil.", false)
            }
        } else {
            completionHandler("Origin is nil.", false)
        }
    }
    
    func calculateTotalDistanceAndDuration() {
        let legs = self.selectedRoute["legs"] as! Array<[String:AnyObject]>
        
        totalDistanceInMeters = 0
        totalDurationInSeconds = 0
        
        for leg in legs {
            totalDistanceInMeters += (leg["distance"] as! [String:AnyObject])["value"] as! UInt
            totalDurationInSeconds += (leg["duration"] as! [String:AnyObject])["value"] as! UInt
        }
        
        let distanceInKilometers: Double = Double(totalDistanceInMeters / 1000)
        totalDistance = "Total Distance: \(distanceInKilometers) Km"
        
        let remainingSecs = totalDurationInSeconds % 60
        let mins = totalDurationInSeconds / 60
        let remainingMins = mins % 60
        let hours = mins / 60
        let remainingHours = hours % 24
        let days = hours / 24
        totalDuration = "Total Duration: \(days) d, \(remainingHours) h, \(remainingMins) m, \(remainingSecs) s"
    }
    
    func getStreetViewImage(fromPoint: CLLocationCoordinate2D, toPoint: CLLocationCoordinate2D, size: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        calculateStreetViewHeading(fromPoint: fromPoint, toPoint: toPoint)
        
        let streetViewURLString = baseURLStreetview + "size=320x240&location=\(fromPoint.latitude),\(fromPoint.longitude)&heading=\(self.headingAngle)&pitch=\(defaultStreetViewPitch)&fov=\(defaultStreetViewFov)"//&key=\(key)"
        
        guard let streetViewURL = URL(string: streetViewURLString) else {
            completionHandler("Error fetching Street View Image", false)
            return
        }
        
        let request = URLRequest(url: streetViewURL)
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error == nil, let imageData = data {
                self.streetViewImageData = imageData
                
                completionHandler("OK", true)
            } else {
                //print(error!)
                completionHandler(error as! String, false)
            }
        }
        task.resume()
    }
    
    func calculateStreetViewHeading(fromPoint: CLLocationCoordinate2D, toPoint: CLLocationCoordinate2D) {
        var angle = 0.0
        
//        let startLocationDictionary = legs[fromLeg]["start_location"] as! [String:AnyObject]
        let y1 = fromPoint.latitude * Double.pi / 180
        let x1 = fromPoint.longitude * Double.pi / 180
        
//        let endLocationDictionary = legs[toLeg]["end_location"] as! [String:AnyObject]
        let y2 = toPoint.latitude * Double.pi / 180
        let x2 = toPoint.longitude * Double.pi / 180

        let a = sin(x1 - x2) * cos(y2)
        let b = cos(y1) * sin(y2) - sin(y1) * cos(y2) * cos(x1 - x2)
        
        angle = -(atan2(a, b))
        
        if angle < 0.0 {
            angle += Double.pi * 2
        }
        
        self.headingAngle = Int(round(angle * 180 / Double.pi))
    }
}
