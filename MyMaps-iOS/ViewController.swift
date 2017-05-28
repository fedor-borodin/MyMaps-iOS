//
//  ViewController.swift
//  MyMaps-iOS
//
//  Created by Admin on 08/05/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import UIKit
import GoogleMaps

//enum TravelModes: Int {
//    case driving
//    case walking
//    case bicycling
//}

//struct StreetViewAttributes {
//    var coordinates: CLLocationCoordinate2D?
//    var heading = 0.0
//    var pitch = 0.0
//    var fov = 90.0
//}
//
//var streetViewTarget: StreetViewAttributes?
var originRoute: String?
var destinationRoute: String?
//var travelMode = TravelModes.walking

class ViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate {

    @IBOutlet weak var mapView: GMSMapView!
    
    let defaultMapZoomValue: Float = 15.0
    
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    var mapTasks = MapTasks()
    //var locationMarker: GMSMarker!
    //var originMarker: GMSMarker!
    //var destinationMarker: GMSMarker!
    //var routePolyline: GMSPolyline!
    //var markersArray: Array<GMSMarker> = []
    //var waypointsArray: Array<String> = []
   
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        mapView.addObserver(self, forKeyPath: "myLocation", options: .new, context: nil)
    }

    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            mapView.isMyLocationEnabled = true
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if !didFindMyLocation {
            let myLocation: CLLocation = change![NSKeyValueChangeKey.newKey] as! CLLocation
            mapView.camera = GMSCameraPosition.camera(withTarget: myLocation.coordinate, zoom: defaultMapZoomValue)
            mapView.settings.myLocationButton = true
            
            didFindMyLocation = true
        }
    }
    
    @IBAction func changeMapType(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Map Types", message: "Select map type:", preferredStyle: .actionSheet)
        
        let normalMapTypeAction = UIAlertAction(title: "Normal", style: .default) { (alertAction) -> Void in
            self.mapView.mapType = .normal }
        let terrainMapTypeAction = UIAlertAction(title: "Terrain", style: .default) { (alertAction) -> Void in
            self.mapView.mapType = .terrain }
        let hybridMapTypeAction = UIAlertAction(title: "Hybrid", style: .default) { (alertAction) -> Void in
            self.mapView.mapType = .hybrid }
        let satelliteMapTypeAction = UIAlertAction(title: "Satellite", style: .default) { (alertAction) -> Void in
            self.mapView.mapType = .satellite }
        let cancelAction = UIAlertAction(title: "Close", style: .cancel)
        
        actionSheet.addAction(normalMapTypeAction)
        actionSheet.addAction(terrainMapTypeAction)
        actionSheet.addAction(hybridMapTypeAction)
        actionSheet.addAction(satelliteMapTypeAction)
        actionSheet.addAction(cancelAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }

    @IBAction func changeTravelMode(_ sender: UIBarButtonItem) {
        let actionSheet = UIAlertController(title: "Travel Modes", message: "Select travel mode:", preferredStyle: .actionSheet)
        
        let drivingModeAction = UIAlertAction(title: "Driving", style: .default) { (alertAction) -> Void in
            //travelMode = TravelModes.driving
        }
        
        let walkingModeAction = UIAlertAction(title: "Walking", style: .default) { (alertAction) -> Void in
            //travelMode = TravelModes.walking
        }
        
        let bicyclingModeAction = UIAlertAction(title: "Bicycling", style: .default) { (alertAction) -> Void in
            //travelMode = TravelModes.bicycling
        }
        
        let closeAction = UIAlertAction(title: "Close", style: .cancel) { (alertAction) -> Void in
            
        }
        
        actionSheet.addAction(drivingModeAction)
        actionSheet.addAction(walkingModeAction)
        actionSheet.addAction(bicyclingModeAction)
        actionSheet.addAction(closeAction)
        
        self.present(actionSheet, animated: true, completion: nil)
    }
    
    @IBAction func findRoute(_ sender: UIBarButtonItem) {
        let addressAlert = UIAlertController(title: "Find Route", message: "Connect locations with a route.", preferredStyle: .alert)
        
        addressAlert.addTextField() { (textField) -> Void in
            //textField.placeholder = "Origin?"
            textField.text = "н новгород республиканская 37"
        }
        addressAlert.addTextField() { (textField) -> Void in
            //textField.placeholder = "Destination?"
            textField.text = "н новгород белинского 122а"
        }
        
        let createRouteAction = UIAlertAction(title: "Create Route", style: .default) { (alertAction) -> Void in
            
            originRoute = (addressAlert.textFields![0] as UITextField).text!
            destinationRoute = (addressAlert.textFields![1] as UITextField).text!
            
            self.performSegue(withIdentifier: "showRouteSegue", sender: self)
        }
        
        let closeAction = UIAlertAction(title: "Close", style: .cancel) { (alertAction) -> Void in
            
        }
        
        addressAlert.addAction(createRouteAction)
        addressAlert.addAction(closeAction)
        
        self.present(addressAlert, animated: true, completion: nil)
    }
}

