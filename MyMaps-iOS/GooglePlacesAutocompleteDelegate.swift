//
//  GooglePlacesAutocompleteDelegate.swift
//  MyMaps-iOS
//
//  Created by Admin on 05/06/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import GoogleMaps
import GooglePlaces

extension MainViewController: GMSAutocompleteViewControllerDelegate {
    
    func viewController(_ viewController: GMSAutocompleteViewController, didAutocompleteWith place: GMSPlace) {
        dismiss(animated: true) { () -> Void in
            self.userDidEnterNewAddress(place)
        }
    }
    
    func viewController(_ viewController: GMSAutocompleteViewController, didFailAutocompleteWithError error: Error) {
        dismiss(animated: true, completion: nil)
    }
    
    func wasCancelled(_ viewController: GMSAutocompleteViewController) {
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
            DispatchQueue.main.async {
                self.goButton.isHidden = false
            }
        }
    }
}
