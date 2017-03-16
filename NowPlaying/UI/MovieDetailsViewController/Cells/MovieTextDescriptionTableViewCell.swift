//
//  MovieTextDescriptionTableViewCell.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/15/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class MovieTextDescriptionTableViewCell: UITableViewCell, NibReusable {
	
	@IBOutlet private weak var movieTextDescriptionLabel: UILabel!
	var movie: Movie? {
		didSet {
			configure()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		contentView.backgroundColor = .clear
	}
	
	private func configure() {
		movieTextDescriptionLabel.text = movie?.movieDescription
	}
	
}
