//
//  DirectionsTasks.swift
//  MyMaps-iOS
//
//  Created by Admin on 25/05/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import Foundation
import CoreLocation.CLLocation
import GoogleMaps

class DirectionsTasks: NSObject {
    
    // constants
    let baseURLDirections = "https://maps.googleapis.com/maps/api/directions/json?"     // URL to request directions from
    
    // variables
    var selectedRoute: [String:AnyObject]!                                              // Dictionary storage for route data received
    var overviewPolyline: [String:AnyObject]!                                           // Dictionary storage with polyline points to draw
    var originCoordinate: CLLocationCoordinate2D!
    var destinationCoordinate: CLLocationCoordinate2D!
    var originAddress: String!
    var destinationAddress: String!
    var totalDistanceInMeters: UInt = 0
    var totalDistance: String!
    var totalDurationInSeconds: UInt = 0
    var totalDuration: String!
    var selectedRouteBounds: GMSCoordinateBounds!
    
    override init() {
        super.init()
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
                    case TravelModes.driving.rawValue:
                        travelModeString = "driving"
                    case TravelModes.bicycling.rawValue:
                        travelModeString = "bicycling"
                    default:
                        travelModeString = "walking"
                    }
                    
                    directionsURLString += ("&mode=" + travelModeString)//.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                }
                
                guard let directionsURL = URL(string: directionsURLString) else {
                    DispatchQueue.main.async {
                        completionHandler("Error while fetching directions", false)
                    }
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
                                
                                let bounds = self.selectedRoute["bounds"] as! [String:AnyObject]
                                let northeastBoundsCoordinate = bounds["northeast"] as! [String:AnyObject]
                                let southwestBoundsCoordinate = bounds["southwest"] as! [String:AnyObject]
                                let boundsCoordinatesNortheast = CLLocationCoordinate2DMake(northeastBoundsCoordinate["lat"] as! Double, northeastBoundsCoordinate["lng"] as! Double)
                                let boundsCoordinatesSouthwest = CLLocationCoordinate2DMake(southwestBoundsCoordinate["lat"] as! Double, southwestBoundsCoordinate["lng"] as! Double)
                                self.selectedRouteBounds = GMSCoordinateBounds(coordinate: boundsCoordinatesNortheast, coordinate: boundsCoordinatesSouthwest)
                                
                                let legs = self.selectedRoute["legs"] as! Array<[String:AnyObject]>
                                let startLocationDictionary = legs[0]["start_location"] as! [String:AnyObject]
                                self.originCoordinate = CLLocationCoordinate2DMake(startLocationDictionary["lat"] as! Double, startLocationDictionary["lng"] as! Double)
                                
                                let endLocationDictionary = legs[legs.count - 1]["end_location"] as! [String:AnyObject]
                                self.destinationCoordinate = CLLocationCoordinate2DMake(endLocationDictionary["lat"] as! Double, endLocationDictionary["lng"] as! Double)
                                
                                self.originAddress = legs[0]["start_address"] as! String
                                self.destinationAddress = legs[legs.count - 1]["end_address"] as! String
                                
                                //self.calculateTotalDistanceAndDuration()
                                
                                completionHandler(status, true)
                            } else {
                                // status in JSON data was not OK
                                DispatchQueue.main.async {
                                    completionHandler(status, false)
                                }
                            }
                        } catch {
                            //could not parse JSON
                            DispatchQueue.main.async {
                                completionHandler("Error parsing JSON", false)
                            }
                        }
                    } else {
                        // error in URLRequest
                        DispatchQueue.main.async {
                            completionHandler(error! as! String, false)
                        }
                    }
                }
                task.resume()
            } else {
                DispatchQueue.main.async {
                    completionHandler("Destination is nil.", false)
                }
            }
        } else {
            DispatchQueue.main.async {
                completionHandler("Origin is nil.", false)
            }
        }
    }
    
    func calculateTotalDistanceAndDuration() {
        let legs = selectedRoute["legs"] as! Array<[String:AnyObject]>
        
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
    
}
