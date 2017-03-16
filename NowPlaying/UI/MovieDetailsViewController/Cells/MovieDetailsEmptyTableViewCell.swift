//
//  MovieDetailsEmptyTableViewCell.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/15/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class MovieDetailsEmptyTableViewCell: UITableViewCell, NibReusable {
	
	override func layoutSubviews() {
		// Removing separator.
		separatorInset = UIEdgeInsets(top: 0,
		                              left: frame.width,
		                              bottom: 0,
		                              right: 0)
	}
	
	override func awakeFromNib() {
		super.awakeFromNib()
		contentView.backgroundColor = .clear
	}
	
}
