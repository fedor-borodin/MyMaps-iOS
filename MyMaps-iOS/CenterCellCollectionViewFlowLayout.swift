//
//  CenterCellCollectionViewFlowLayout.swift
//  MyMaps-iOS
//
//  Created by Admin on 28/05/2017.
//  Copyright © 2017 fborodin. All rights reserved.
//

// MARK: - THIS IS OBSOLETE. Probably won't need this class again

import UIKit

class CenterCellCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    var mostRecentOffset: CGPoint = CGPoint()
    
    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint, withScrollingVelocity velocity: CGPoint) -> CGPoint {
        if velocity.x == 0 {
            return mostRecentOffset
        }
        
        if let cv = collectionView {
            let cvBounds = cv.bounds
            let halfWidth = cvBounds.size.width * 0.5
            
            if let attributesForVisibleCells = layoutAttributesForElements(in: cvBounds) {
                var candidateAttributes: UICollectionViewLayoutAttributes?
                for attributes in attributesForVisibleCells {
                    if attributes.representedElementCategory != UICollectionElementCategory.cell {
                        continue
                    }
                    
                    if attributes.center.x == 0 || (attributes.center.x > (cv.contentOffset.x + halfWidth) && velocity.x < 0) {
                        continue
                    }
                    
                    candidateAttributes = attributes
                }
                
                if proposedContentOffset.x == -cv.contentInset.left {
                    return proposedContentOffset
                }
                
                guard let _ = candidateAttributes else {
                    return mostRecentOffset
                }
                
                mostRecentOffset = CGPoint(x: floor(candidateAttributes!.center.x - halfWidth), y: proposedContentOffset.y)
                return mostRecentOffset
            }
        }
        
        mostRecentOffset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset)
        return mostRecentOffset
    }
}
