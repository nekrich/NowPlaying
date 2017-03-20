//
//  SpinnerCollectionViewCell.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/20/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class SpinnerCollectionViewCell: UICollectionViewCell, NibReusable {
	
	override func awakeFromNib() {
		super.awakeFromNib()
		backgroundColor = .collectionViewCellBackground
		layer.cornerRadius = .defaultCornerRadius
	}
	
}
