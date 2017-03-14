//
//  MovieCollectionViewCell.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit
import SDWebImage

class MovieCollectionViewCell: UICollectionViewCell {
	
	@IBOutlet private weak var activityIndicator: UIActivityIndicatorView!
	@IBOutlet private weak var posterImageView: UIImageView!
	
	var movie: Movie? {
		didSet {
			if movie == nil {
				activityIndicator.startAnimating()
				posterImageView.sd_setImage(with: .none)
			} else {
				posterImageView.sd_setImage(with: movie?.posterURL(width: self.frame.width),
				                            placeholderImage: .none,
				                            options: [],
				                            completed: { [weak self] (image, _, _, _) in
					if image != nil {
						self?.activityIndicator.stopAnimating()
					}
				})
				
			}
		}
	}
	
}

extension MovieCollectionViewCell {
	
	static var reuseIdentifier: String {
		return String(describing: self)
	}
	
	static var nib: UINib {
		return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
	}
	
}
