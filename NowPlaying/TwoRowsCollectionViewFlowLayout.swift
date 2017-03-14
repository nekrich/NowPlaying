//
//  TwoRowsCollectionViewFlowLayout.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class TwoRowsCollectionViewFlowLayout: UICollectionViewFlowLayout {
	
	override func awakeFromNib() {
		super.awakeFromNib()
		scrollDirection = .vertical
		minimumInteritemSpacing = 20
		minimumLineSpacing = minimumInteritemSpacing * 0.85
		sectionInset = UIEdgeInsets(top: 25,
		                            left: 20,
		                            bottom: 0,
		                            right: 20)
	}
	
	override var itemSize: CGSize {
		
		get {
			
			guard let collectionViewSize = collectionView?.frame.size
				else {
					return super.itemSize
			}
			
			let marginsAndInsets = sectionInset.left + sectionInset.right + minimumInteritemSpacing
			let itemWidth = (collectionViewSize.width - marginsAndInsets) / 2.0
			
			return CGSize(width: itemWidth, height: itemWidth * 1.5)
			
		}
		
		set {
			
			super.itemSize = newValue
			
		}
		
	}
	
}
