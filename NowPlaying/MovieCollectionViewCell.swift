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
	@IBOutlet private weak var movieTitle: UILabel!
	
	var indexPath: IndexPath?
	
	var movie: Movie? {
		didSet {
			
			movieTitle.isHidden = false
			
			if movie == nil {
				
				posterImageView.sd_setImage(with: .none)
				posterImageView.image = #imageLiteral(resourceName: "noMovie")
				movieTitle.text = .none
				
			} else {
				
				posterImageView.sd_setShowActivityIndicatorView(true)
				
				movieTitle.text = movie?.title
				
				posterImageView.sd_setImage(with: movie?.posterURL(width: self.frame.width),
				                            placeholderImage: .none,
				                            options: [],
				                            completed: { [weak self] (image, _, _, _) in
																			let hasPoster = image != nil
																			self?.movieTitle.isHidden = hasPoster
																			if !hasPoster {
																				self?.posterImageView.image = #imageLiteral(resourceName: "noPoster")
																			}
				})
				configureActivityIndicator()
			}
		}
	}
	
	private func configureActivityIndicator() {
		if
			let activityIndicator = posterImageView.subviews
			.first(where: { $0 is UIActivityIndicatorView }) as? UIActivityIndicatorView
		{
			activityIndicator.color = .collectionViewCellActivityIndicatorColor
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		backgroundColor = .collectionViewCellBackground
		posterImageView.image = #imageLiteral(resourceName: "noMovie")
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(newMovieDetails(_:)),
		                                       name: .NewMovieDetails,
		                                       object: .none)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func newMovieDetails(_ notification: Notification) {
		if notification.object as? IndexPath == indexPath {
			self.movie = notification.userInfo?["movie"] as? Movie
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
