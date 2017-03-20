//
//  MovieMainInfoTableViewCell.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/15/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class MovieMainInfoTableViewCell: UITableViewCell, NibReusable {
	
	@IBOutlet private weak var moviePosterImageView: UIImageView!
	
	@IBOutlet private weak var scoreTextLabel: UILabel!
	@IBOutlet private weak var scoreValueLabel: UILabel!
	
	@IBOutlet private weak var raitingTextLabel: UILabel!
	@IBOutlet private weak var raitingValueLabel: UILabel!
	
	@IBOutlet private weak var releaseDateTextLabel: UILabel!
	@IBOutlet private weak var releaseDateValueLabel: UILabel!
	
	@IBOutlet private weak var movieTitleLabel: UILabel!
	
	var movie: Movie? {
		didSet {
			configure()
		}
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		contentView.backgroundColor = .clear
		scoreTextLabel.text = Bundle.main.localizedString(forKey: "SCORE",
		                                                  value: .none,
		                                                  table: .none).appending(":")
		raitingTextLabel.text = Bundle.main.localizedString(forKey: "RAITING",
		                                                  value: .none,
		                                                  table: .none).appending(":")
		releaseDateTextLabel.text = Bundle.main.localizedString(forKey: "RELEASE DATE",
		                                                  value: .none,
		                                                  table: .none).appending(":")
		moviePosterImageView.layer.cornerRadius = .defaultCornerRadius
	}
	
	private func configure() {
		moviePosterImageView.sd_setImage(with: movie?.posterURL(width: 150))
		
		guard let movie = self.movie
			else {
				scoreValueLabel.text = .none
				raitingValueLabel.text = .none
				releaseDateValueLabel.text = .none
				movieTitleLabel.text = .none
				return
		}
		
		scoreValueLabel.text = String(format: "%.1f", movie.score)
		
		releaseDateValueLabel.text = Formatters.releaseDateFormatter.string(from: movie.releaseDate)
		
		let releaseYear = Calendar.current.component(.year, from: movie.releaseDate)
		
		movieTitleLabel.text = movie.title.appending(" (\(releaseYear))")
		
		raitingValueLabel.text = movie.auditoryRaitingUS
		
	}
	
}
