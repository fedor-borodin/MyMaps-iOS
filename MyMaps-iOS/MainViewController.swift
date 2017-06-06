//
//  MainViewController.swift
//  MyMaps-iOS
//
//  Created by Admin on 22/05/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import UIKit
import GoogleMaps
import GooglePlaces

enum TravelModes: Int {
    case driving
    case walking
    case bicycling
}

class MainViewController: UIViewController, GMSMapViewDelegate {
    
    // MARK: - Properties
    @IBOutlet weak var searchAddressFrom: UITextField!
    @IBOutlet weak var searchAddressTo: UITextField!
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var mapViewHalfSizeConstraint: NSLayoutConstraint!   // constraint to show map either fullscreen or halfscreen (to to show streetView image)
    @IBOutlet weak var streetViewColletion: UICollectionView!
    @IBOutlet weak var addressInputs: UIView!                           // view containing both textFields for address search
    @IBOutlet weak var goButton: UIButton!                              // get and display directions and street view images
    
    let defaultMapZoomValue: Float = 15.0                               // default map zoom: street level
    let defaultRoutePolylineWidth: CGFloat = 4.0
    
    var currentTravelMode = TravelModes.walking
    var locationManager = CLLocationManager()
    var didFindMyLocation = false
    var geocodingTasks = GeocodingTasks()
    var directionsTasks = DirectionsTasks()
    var streetViewTasks = StreetViewTasks()
    var marker: GMSMarker!
    var placeDestination: GMSPlace!
    var locationMarker: GMSMarker!
    var originMarker: GMSMarker!
    var destinationMarker: GMSMarker!
    var routePolyline: GMSPolyline!
    var markersArray: Array<GMSMarker> = []
    var waypointsArray: Array<String> = []
    var textFieldEditingNow: UITextField!
    var currentStreetViewImage: UIImage!
    var stepMarker: GMSMarker!
    var currentStepPolyline: GMSPolyline!
    var currentStepInstructions: NSAttributedString!
    
    
    // MARK: - Methods
    // when tapping on the searchTextField we present a GooglePlaces AutoComplete VC
    @IBAction func searchAddressDidBeginEditing(_ sender: UITextField) {
        textFieldEditingNow = sender
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
    }
    
    // fetch the Route and display it or Go Back to the Start
    @IBAction func goButtonPressed(_ sender: UIButton) {
        if sender.currentTitle == "Go" {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            goButton.setTitle("⬅︎", for: .normal)
            displayRoute()
        } else {
            goButton.setTitle("Go", for: .normal)
            addressInputs.isHidden = false
            searchAddressTo.text = ""
            searchAddressFrom.isHidden = true
            mapViewHalfSizeConstraint.priority = 800
            clearRoute()
            clearStepRoute()
            let camera = GMSCameraPosition.camera(withTarget: (locationManager.location?.coordinate)!, zoom: defaultMapZoomValue)
            mapView.animate(to: camera)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // make the Go button round and bring it to the front
        goButton.layer.cornerRadius = 0.5 * goButton.bounds.size.width
        goButton.superview?.bringSubview(toFront: goButton)
        
        // hide the first TextField
        searchAddressFrom.isHidden = true
        
        // Hide the StreetView UIImageView and show a fullscreen MapView
        mapViewHalfSizeConstraint.priority = 800
        //mapViewHalfSizeConstraint.isActive = false
        
        // Your Location Manager
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        mapView.addObserver(self, forKeyPath: "myLocation", options: .new, context: nil)
        
        // Collection View
        streetViewColletion.delegate = self
        streetViewColletion.dataSource = self
    }
    
    func showAlertWithMessage(_ message: String) {
        let alertController = UIAlertController(title: "ERROR", message: message, preferredStyle: .alert)
        let closeAction = UIAlertAction(title: "Close", style: .cancel) { (alertAction) -> Void in }
        alertController.addAction(closeAction)
        present(alertController, animated: true, completion: nil)
    }
    
    // MARK: - Directions logic
    func displayRoute() {
        if (routePolyline) != nil {
            clearRoute()
            waypointsArray.removeAll(keepingCapacity: false)
        }
        
        directionsTasks.getDirections(from: directionsTasks.originAddress, to: directionsTasks.destinationAddress, waypoints: nil, travelMode: currentTravelMode) { (status, success) -> Void in
            if success {
                DispatchQueue.main.async {
                    self.configureMapAndMarkersforRoute()
                    self.drawRoute()
                    self.mapViewHalfSizeConstraint?.priority = 999
                    self.mapViewHalfSizeConstraint?.isActive = true
                    self.addressInputs?.isHidden = true
                    self.streetViewColletion.reloadData()
                }
            } else {
                self.showAlertWithMessage(status)
            }
        }
    }
    
    func configureMapAndMarkersforRoute() {
        if originMarker == nil {
            originMarker = GMSMarker()
        }
        originMarker.position = directionsTasks.originCoordinate
        originMarker.map = mapView
        originMarker.icon = GMSMarker.markerImage(with: .cyan)
        originMarker.title = directionsTasks.originAddress
        
        if destinationMarker == nil {
            destinationMarker = GMSMarker()
        }
        destinationMarker.position = directionsTasks.destinationCoordinate
        destinationMarker.map = mapView
        destinationMarker.icon = GMSMarker.markerImage(with: .red)
        destinationMarker.title = directionsTasks.destinationAddress
        
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
        let route = directionsTasks.overviewPolyline["points"] as! String
        
        let path = GMSPath(fromEncodedPath: route)
        routePolyline = GMSPolyline(path: path)
        routePolyline.strokeWidth = defaultRoutePolylineWidth
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
    
    func clearStepRoute() {
        if currentStepPolyline != nil {
            currentStepPolyline.map = nil
            currentStepPolyline = nil
        }
        if stepMarker != nil {
            stepMarker.map = nil
            stepMarker = nil
        }
    }
    
    func recreateRoute() {
        if (routePolyline) != nil {
            clearRoute()
            
            directionsTasks.getDirections(from: directionsTasks.originAddress, to: directionsTasks.destinationAddress, waypoints: waypointsArray, travelMode: currentTravelMode, completionHandler: { (status, success) -> Void in
                if success {
                    self.configureMapAndMarkersforRoute()
                    self.drawRoute()
                    //self.displayRouteInfo()
                } else {
                    self.showAlertWithMessage(status)
                }
            })
        }
    }
    
    // MARK: - Steps Logic
    func getStepPolylineAndMarker(stepNo: Int) {
        clearStepRoute()
        
        let steps = (directionsTasks.selectedRoute["legs"] as! Array<[String:AnyObject]>)[0]["steps"] as! Array<[String:AnyObject]>
        currentStepInstructions = getAttributedStringFromHTML(text: steps[stepNo]["html_instructions"] as! String)
        let stepPolyline = steps[stepNo]["polyline"] as! [String:AnyObject]
        let path = GMSPath(fromEncodedPath: stepPolyline["points"] as! String)
        currentStepPolyline = GMSPolyline(path: path)
        currentStepPolyline.strokeColor = .green
        currentStepPolyline.strokeWidth = defaultRoutePolylineWidth + 2
        currentStepPolyline.geodesic = true
        currentStepPolyline.map = mapView
        
        let stepPointFrom = CLLocationCoordinate2DMake((steps[stepNo]["start_location"] as! [String:AnyObject])["lat"] as! Double, (steps[stepNo]["start_location"] as! [String:AnyObject])["lng"] as! Double)
        let stepPointTo = CLLocationCoordinate2DMake((steps[stepNo]["end_location"] as! [String:AnyObject])["lat"] as! Double, (steps[stepNo]["end_location"] as! [String:AnyObject])["lng"] as! Double)
        let currentStepBounds = GMSCoordinateBounds(coordinate: stepPointFrom, coordinate: stepPointTo)
        let mapUpdate = GMSCameraUpdate.fit(currentStepBounds, withPadding: 50.0)
        mapView.moveCamera(mapUpdate)
        
        stepMarker = GMSMarker(position: stepPointFrom)
        stepMarker.map = mapView
        stepMarker.icon = GMSMarker.markerImage(with: .green)
    }
    
    func getStreetViewImage(stepNo: Int, completionHandler: @escaping ((String, Bool) -> Void)) {
        let steps = (directionsTasks.selectedRoute["legs"] as! Array<[String:AnyObject]>)[0]["steps"] as! Array<[String:AnyObject]>
        let pointFrom = CLLocationCoordinate2DMake((steps[stepNo]["start_location"] as! [String:AnyObject])["lat"] as! Double, (steps[stepNo]["start_location"] as! [String:AnyObject])["lng"] as! Double)
        let pointTo = CLLocationCoordinate2DMake((steps[stepNo]["end_location"] as! [String:AnyObject])["lat"] as! Double, (steps[stepNo]["end_location"] as! [String:AnyObject])["lng"] as! Double)
        
        streetViewTasks.getStreetViewImage(fromPoint: pointFrom, toPoint: pointTo, size: streetViewTasks.defaultStreetViewSize) { (status, success) -> Void in
            if success {
                DispatchQueue.main.async {
                    self.currentStreetViewImage = UIImage(data: self.streetViewTasks.streetViewImageData)
                    completionHandler(status, true)
                }
            } else {
                DispatchQueue.main.async {
                    completionHandler(status, false)
                }
            }
        }
    }
    
    func getAttributedStringFromHTML(text: String) -> NSAttributedString? {
        do {
            if let data = text.data(using: .unicode, allowLossyConversion: true) {
                let str = try NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute:NSHTMLTextDocumentType], documentAttributes: nil)
                return str
            } else {
                return nil
            }
        } catch let error as NSError {
            showAlertWithMessage(error.localizedDescription)
            return nil
        }
    }
}
