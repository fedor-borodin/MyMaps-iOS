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
    
    
    // MARK: - Methods
    // when tapping on the searchTextField we present a GooglePlaces AutoComplete VC
    @IBAction func searchAddressDidBeginEditing(_ sender: UITextField) {
        textFieldEditingNow = sender
        let acController = GMSAutocompleteViewController()
        acController.delegate = self
        present(acController, animated: true, completion: nil)
    }
    
    // fetch the Route and display it
    @IBAction func goButtonPressed(_ sender: UIButton) {
        displayRoute()
        //getFirstStreetViewImage()
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
                //self.configureMapAndMarkersforRoute()
                //self.drawRoute()
                //self.displayRouteInfo()
                //self.displayStreetViewImage(step: 0)
                
                DispatchQueue.main.async {
                    self.configureMapAndMarkersforRoute()
                    self.drawRoute()
                    self.mapViewHalfSizeConstraint?.priority = 999
                    self.mapViewHalfSizeConstraint?.isActive = true
                    self.addressInputs?.isHidden = true
                    self.streetViewColletion.reloadData()
                }
                //self.getStreetViewImage(stepNo: 0)
            } else {
                self.showAlertWithMessage(status)
            }
        }
    }
    
    func configureMapAndMarkersforRoute() {
        //mapView.camera = GMSCameraPosition.camera(withTarget: directionsTasks.originCoordinate, zoom: defaultMapZoomValue)
        
        // zoom on the whole route using bounds from JSON
        //let mapUpdate = GMSCameraUpdate.fit(self.directionsTasks.selectedRouteBounds, withPadding: 50.0)
        //mapView.moveCamera(mapUpdate)
        
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
    
    // MARK: - Street View Logic
    func getStepPolylineAndMarker(stepNo: Int) {
        if currentStepPolyline != nil {
            currentStepPolyline.map = nil
            currentStepPolyline = nil
        }
        if stepMarker != nil {
            stepMarker.map = nil
            stepMarker = nil
        }
        
        let steps = (directionsTasks.selectedRoute["legs"] as! Array<[String:AnyObject]>)[0]["steps"] as! Array<[String:AnyObject]>
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
                self.currentStreetViewImage = UIImage(data: self.streetViewTasks.streetViewImageData)
                //self.streetViewColletion.reloadData()
                completionHandler(status, true)
            } else {
                completionHandler(status, false)
                //self.showAlertWithMessage(status)
            }
        }
    }
}

// MARK: - Location Manager Delegate
extension MainViewController: CLLocationManagerDelegate {
    
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
}

// MARK: - Google Places Autocomplete Delegate
extension MainViewController: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        //print("Place name: \(place.name)\naddress: \(place.formattedAddress ?? "NONE")\nattributions: \(place.attributions ?? NSAttributedString(string: "NONE", attributes: nil))")
        dismiss(animated: true) { () -> Void in
            self.userDidEnterNewAddress(place)
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        //print("Error: \(error)")
        dismiss(animated: true, completion: nil)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
        //print("Autocomplete cancelled by user")
        dismiss(animated: true, completion: nil)
    }
    
    func userDidEnterNewAddress(_ place: GMSPlace) {
        if textFieldEditingNow == searchAddressFrom {
            searchAddressFrom.text = place.name
            directionsTasks.originAddress = place.formattedAddress
        } else {
            let camera = GMSCameraPosition.camera(withTarget: place.coordinate, zoom: defaultMapZoomValue)
            mapView.camera = camera
            marker = GMSMarker()
            marker!.title = place.name
            marker!.position = place.coordinate
            marker!.map = mapView
            searchAddressTo.text = place.name
            directionsTasks.destinationAddress = place.formattedAddress
            
            if didFindMyLocation && searchAddressFrom.isHidden {
                let myCoordinates = "\(locationManager.location?.coordinate.latitude ?? 0),\(locationManager.location?.coordinate.longitude ?? 0)"
                geocodingTasks.geocodeAddress(address: myCoordinates, usingCoordinates: true) { (status, success) -> Void in
                    if success {
                        self.directionsTasks.originAddress = self.geocodingTasks.fetchedFormattedAddress
                        self.searchAddressFrom.text = "My Location"
                        self.searchAddressFrom.isHidden = false
                        self.goButton.isHidden = false
                    } else {
                        self.showAlertWithMessage(status)
                    }
                }
            }
        }
        
        if searchAddressTo.text != "" && searchAddressFrom.text != "" {
            goButton.isHidden = false
        }
    }
}

// MARK: - Collection View Delegate
extension MainViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 1
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if let route = directionsTasks.selectedRoute {
            let legs = route["legs"] as! Array<[String:AnyObject]>
            let steps = legs[0]["steps"] as! Array<[String:AnyObject]>
            
            return steps.count
        } else {
            return 0
        }
        //return 1
        //        if let legs = directionsTasks.selectedRoute["legs"] as! Array<[String:AnyObject]> {
        //            let steps = legs[0]["steps"] as! Array<[String:AnyObject]>
        //            return steps.count
        //        } else {
        //            return 0
        //        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "streetViewCollectionCell", for: indexPath) as! CollectionViewCell
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let _ = directionsTasks.selectedRoute {
            let myCell = cell as! CollectionViewCell
            getStepPolylineAndMarker(stepNo: indexPath.section)
            getStreetViewImage(stepNo: indexPath.section) { (status, success) -> Void in
                if success {
                    if let image = self.currentStreetViewImage {
                        myCell.imageView.image = image
                    }
                } else {
                    self.showAlertWithMessage(status)
                }
            }
        }
    }
    
    //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
    //        return CGSize(width: 200, height: 200)
    //    }
}
