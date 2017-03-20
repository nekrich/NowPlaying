//
//  MoviesCollectionViewFlowLayout.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class MoviesCollectionViewFlowLayout: UICollectionViewFlowLayout {
	
	override func awakeFromNib() {
		super.awakeFromNib()
		scrollDirection = .vertical
		minimumInteritemSpacing = 20
		minimumLineSpacing = minimumInteritemSpacing * 0.85
		sectionInset = UIEdgeInsets(top: 25,
		                            left: 20,
		                            bottom: 20,
		                            right: 20)
	}
	
	override var itemSize: CGSize {
		
		get {
			
			guard let collectionViewSize = collectionView?.frame.size
				else {
					return super.itemSize
			}
			
			let currentDevice = UIDevice.current
			let isIPad = currentDevice.userInterfaceIdiom == .pad
			
			let numberOfRows: Int
			switch (isIPad, currentDevice.orientation.isLandscape) {
			case (true, true):
				numberOfRows = 5
			case (true, false):
				numberOfRows = 4
			case (false, true):
				numberOfRows = 3
			case (false, false):
				numberOfRows = 2
			}
			
			let marginsAndInsets = sectionInset.left
				+ sectionInset.right
				+ minimumInteritemSpacing * CGFloat(numberOfRows - 1)
			
			let itemWidth = (collectionViewSize.width - marginsAndInsets) / CGFloat(numberOfRows)
			
			return CGSize(width: itemWidth, height: itemWidth * 1.5)
			
		}
		
		set {
			
			super.itemSize = newValue
			
		}
		
	}
	
	override func invalidationContext(forBoundsChange newBounds: CGRect)
		-> UICollectionViewLayoutInvalidationContext
	{
		let context = super.invalidationContext(forBoundsChange: newBounds)
		if let context = context as? UICollectionViewFlowLayoutInvalidationContext {
			context.invalidateFlowLayoutDelegateMetrics =
				newBounds.size != (collectionView?.bounds.size ?? newBounds.size)
		}
		
		return context
	}
	
}
