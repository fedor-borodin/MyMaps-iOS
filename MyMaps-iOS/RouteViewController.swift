//
//  RouteViewController.swift
//  MyMaps-iOS
//
//  Created by Admin on 15/05/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import UIKit
import GoogleMaps

//struct StreetViewAttributes {
//    var coordinates: CLLocationCoordinate2D?
//    var heading = 0.0
//    var pitch = 0.0
//    var fov = 90.0
//}

class RouteViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {

    @IBOutlet weak var streetViewImage: UIImageView!
    
    @IBOutlet weak var mapView: GMSMapView!
    
    let defaultMapZoomValue: Float = 15.0
    
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    var mapTasks = MapTasks()
    var locationMarker: GMSMarker!
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var markersArray: Array<GMSMarker> = []
    var waypointsArray: Array<String> = []

    //var streetViewTarget: StreetViewAttributes?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.displayRoute()
        
        self.displayStreetView(from: CLLocationCoordinate2DMake(56.3123523, 44.0273087), to: CLLocationCoordinate2DMake(56.3126599, 44.0283495))
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func displayRoute() {
        if (self.routePolyline) != nil {
            self.clearRoute()
            self.waypointsArray.removeAll(keepingCapacity: false)
        }
        
        let origin = originRoute
        let destination = destinationRoute
        
        self.mapTasks.getDirections(from: origin, to: destination, waypoints: nil, travelMode: travelMode) { (status, success) -> Void in
            if success {
                self.configureMapAndMarkersforRoute()
                self.drawRoute()
                self.displayRouteInfo()
            } else {
                self.showAlertWithMessage(status)
            }
        }
    }
    
    func displayStreetView(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) {
        self.mapTasks.getStreetViewImage(fromPoint: from, toPoint: to, size: "320x240") { (status, success) -> Void in
            if success {
                if let imageData = self.mapTasks.streetViewImageData {
                    self.streetViewImage.image = UIImage(data: imageData)
                    self.streetViewImage.contentMode = .scaleAspectFit
                }
            }
        }

    }
    
    func showAlertWithMessage(_ message: String) {
        let alertController = UIAlertController(title: "ERROR", message: message, preferredStyle: .alert)
        
        let closeAction = UIAlertAction(title: "Close", style: .cancel) { (alertAction) -> Void in
            
        }
        
        alertController.addAction(closeAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func configureMapAndMarkersforRoute() {
        mapView.camera = GMSCameraPosition.camera(withTarget: mapTasks.originCoordinate, zoom: defaultMapZoomValue)
        
        if originMarker == nil {
            originMarker = GMSMarker()
        }
        originMarker.position = self.mapTasks.originCoordinate
        originMarker.map = self.mapView
        originMarker.icon = GMSMarker.markerImage(with: .green)
        originMarker.title = self.mapTasks.originAddress
        
        if destinationMarker == nil {
            destinationMarker = GMSMarker()
        }
        destinationMarker.position = self.mapTasks.destinationCoordinate
        destinationMarker.map = self.mapView
        destinationMarker.icon = GMSMarker.markerImage(with: .red)
        destinationMarker.title = self.mapTasks.destinationAddress
        
        if waypointsArray.count > 0 {
            for waypoint in waypointsArray {
                let lat: Double = (waypoint.components(separatedBy: ",")[0] as NSString).doubleValue
                let lng: Double = (waypoint.components(separatedBy: ",")[1] as NSString).doubleValue
                
                let marker = GMSMarker(position: CLLocationCoordinate2DMake(lat, lng))
                marker.map = mapView
                marker.icon = GMSMarker.markerImage(with: .purple)
                
                markersArray.append(marker)
            }
        }
    }
    
    func drawRoute() {
        let route = mapTasks.overviewPolyline["points"] as! String
        
        let path = GMSPath(fromEncodedPath: route)
        routePolyline = GMSPolyline(path: path)
        routePolyline.map = mapView
    }
    
    func displayRouteInfo() {
        
    }
    
    func clearRoute() {
        originMarker.map = nil
        destinationMarker.map = nil
        routePolyline.map = nil
        
        originMarker = nil
        destinationMarker = nil
        routePolyline = nil
        
        if markersArray.count > 0 {
            for marker in markersArray {
                marker.map = nil
            }
        }
        markersArray.removeAll(keepingCapacity: false)
    }
    
    func recreateRoute() {
        if (routePolyline) != nil {
            clearRoute()
            
            mapTasks.getDirections(from: mapTasks.originAddress, to: mapTasks.destinationAddress, waypoints: waypointsArray, travelMode: travelMode, completionHandler: { (status, success) -> Void in
                if success {
                    self.configureMapAndMarkersforRoute()
                    self.drawRoute()
                    self.displayRouteInfo()
                } else {
                    self.showAlertWithMessage(status)
                }
            })
        }
    }

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
