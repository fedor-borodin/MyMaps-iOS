//
//  StreetViewTasks.swift
//  MyMaps-iOS
//
//  Created by Admin on 25/05/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import Foundation
import CoreLocation.CLLocation

class StreetViewTasks: NSObject {
    
    // constants
    let baseURLStreetview = "https://maps.googleapis.com/maps/api/streetview?"          // URL to request streetview image from
    let defaultStreetViewFov = 120
    let defaultStreetViewPitch = 0
    let defaultStreetViewSize = "640x480"
    
    // variables
    var streetViewImagesDataArray: Array<Data> = []
    var streetViewImageData: Data!
    var headingAngle: Int = 0
    
    
    override init() {
        super.init()
    }
    
    
    func getDirectionsImages(route: [String:AnyObject]!, completionHandler: @escaping (String, Bool) -> Void) {
        let steps = (route["legs"] as! Array<[String:AnyObject]>)[0]["steps"] as! Array<[String:AnyObject]>
        
        var count = 0
        
        for step in steps {
            let pointFrom = CLLocationCoordinate2DMake((step["start_location"] as! [String:AnyObject])["lat"] as! Double, (step["start_location"] as! [String:AnyObject])["lng"] as! Double)
            let pointTo = CLLocationCoordinate2DMake((step["end_location"] as! [String:AnyObject])["lat"] as! Double, (step["end_location"] as! [String:AnyObject])["lng"] as! Double)
            
            getStreetViewImage(fromPoint: pointFrom, toPoint: pointTo, size: defaultStreetViewSize) { (status, success) -> Void in
                if success {
                    self.streetViewImagesDataArray.append(self.streetViewImageData)
                    count += 1
                    
                    if count == steps.count {
                        DispatchQueue.main.async {
                            completionHandler("OK", true)
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        completionHandler("Error loading image", false)
                    }
                }
            }
        }
    }
    
    func getStreetViewImage(fromPoint: CLLocationCoordinate2D, toPoint: CLLocationCoordinate2D, size: String, completionHandler: @escaping ((String, Bool) -> Void)) {
        calculateStreetViewHeading(fromPoint: fromPoint, toPoint: toPoint)
        
        let streetViewURLString = baseURLStreetview + "size=\(size)&location=\(fromPoint.latitude),\(fromPoint.longitude)&heading=\(self.headingAngle)&pitch=\(defaultStreetViewPitch)&fov=\(defaultStreetViewFov)"//&key=\(key)"
        
        guard let streetViewURL = URL(string: streetViewURLString) else {
            completionHandler("Error fetching Street View Image", false)
            return
        }
        
        let request = URLRequest(url: streetViewURL)
        
        let task = URLSession.shared.dataTask(with: request) {
            (data, response, error) in
            if error == nil, let imageData = data {
                self.streetViewImageData = imageData
                DispatchQueue.main.async {
                    completionHandler("OK", true)
                }
            } else {
                //print(error!)
                DispatchQueue.main.async {
                    completionHandler(error as! String, false)
                }
            }
        }
        task.resume()
    }
    
    func calculateStreetViewHeading(fromPoint: CLLocationCoordinate2D, toPoint: CLLocationCoordinate2D) {
        var angle = 0.0
        
        let y1 = fromPoint.latitude * Double.pi / 180
        let x1 = fromPoint.longitude * Double.pi / 180
        
        let y2 = toPoint.latitude * Double.pi / 180
        let x2 = toPoint.longitude * Double.pi / 180
        
        let a = sin(x1 - x2) * cos(y2)
        let b = cos(y1) * sin(y2) - sin(y1) * cos(y2) * cos(x1 - x2)
        
        angle = -(atan2(a, b))
        
        if angle < 0.0 {
            angle += Double.pi * 2
        }
        
        headingAngle = Int(round(angle * 180 / Double.pi))
    }
}
