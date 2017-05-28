//
//  GeocodingTasks.swift
//  MyMaps-iOS
//
//  Created by Admin on 23/05/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import Foundation

class GeocodingTasks: NSObject {
    
    // constants
    let baseURLGeocode = "https://maps.googleapis.com/maps/api/geocode/json?"           // URL to request geocoding from
    
    // variables
    var lookupAddressResults: [String:AnyObject]!                                       // Array Dictionary storage for address and coordinates data received
    var fetchedFormattedAddress: String!
    var fetchedAddressLongtitude: Double!
    var fetchedAddressLatitude: Double!
    
    
    override init() {
        super.init()
    }
    
    // Main Geocoding method
    func geocodeAddress(address: String!, usingCoordinates: Bool, completionHandler: @escaping ((String, Bool) -> Void)) {
        if let lookupAddress = address {
            let geocodeURLString = baseURLGeocode + (usingCoordinates ? "latlng=" + lookupAddress : "address=" + lookupAddress.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!)
            //            print(geocodeURLString)               // logging URL-request
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
                            //                            var iteratorResults = 0
                            //                            for result in allResults {
                            //                                self.lookupAddressResults[iteratorResults] = result
                            //                                self.fetchedFormattedAddress[iteratorResults] = self.lookupAddressResults[iteratorResults]?["formatted_address"] as! String
                            //                                let geometry = self.lookupAddressResults[iteratorResults]?["geometry"] as! [String:AnyObject]
                            //                                self.fetchedAddressLongtitude[iteratorResults] = ((geometry["location"] as! [String:AnyObject])["lng"] as! NSNumber).doubleValue
                            //                                self.fetchedAddressLatitude[iteratorResults] = ((geometry["location"] as! [String:AnyObject])["lat"] as! NSNumber).doubleValue
                            //                                iteratorResults += 1
                            //                            }
                            DispatchQueue.main.async {
                                completionHandler(status, true)
                            }
                        } else {
                            DispatchQueue.main.async {
                                completionHandler(status, false)
                            }
                        }
                    } catch {
                        DispatchQueue.main.async {
                            completionHandler("Error parsing JSON", false)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completionHandler(error as! String, false)
                    }
                }
            }
            task.resume()
        }
    }
}
