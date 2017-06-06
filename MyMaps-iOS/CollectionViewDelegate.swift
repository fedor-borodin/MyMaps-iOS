//
//  CollectionViewDelegate.swift
//  MyMaps-iOS
//
//  Created by Admin on 05/06/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

import UIKit

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
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "streetViewCollectionCell", for: indexPath) as! CollectionViewCell
        
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
        
        if let _ = directionsTasks.selectedRoute {
            getStepPolylineAndMarker(stepNo: indexPath.section)
            getStreetViewImage(stepNo: indexPath.section) { (status, success) -> Void in
                if success {
                    if let image = self.currentStreetViewImage {
                        cell.imageView.image = image
                        cell.stepInstructionsView.attributedText = self.currentStepInstructions
                        UIApplication.shared.isNetworkActivityIndicatorVisible = false
                    }
                } else {
                    self.showAlertWithMessage(status)
                }
            }
        }
        
        return cell
    }
}
