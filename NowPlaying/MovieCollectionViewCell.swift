//
//  MovieCollectionViewCell.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class MovieCollectionViewCell: UICollectionViewCell {
	
}

extension MovieCollectionViewCell {
	
	static var reuseIdentifier: String {
		return String(describing: self)
	}
	
	static var nib: UINib {
		return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
	}
	
}
