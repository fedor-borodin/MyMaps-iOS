//
//  LocationManagerDelegate.swift
//  MyMaps-iOS
//
//  Created by Admin on 05/06/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import CoreLocation
import GoogleMaps

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
