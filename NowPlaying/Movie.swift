//
//  Movie.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation
import UIKit

struct Movie {
	
	let id: UInt64
	let title: String
	let movieDescription: String
	
	private let posterPath: String
	
	let score: Double
	
	private(set) var auditoryRaitingUS: String?
	
	func posterURL(width: CGFloat) -> URL {
		return API.posterURL(width: width, at: posterPath)
	}
	
	init?(jsonDictionary: [AnyHashable : Any]) {
		
		guard
			let id = jsonDictionary["id"] as? UInt64,
			let title = jsonDictionary["title"] as? String,
			let movieDescription = jsonDictionary["overview"] as? String,
			let score = jsonDictionary["vote_average"] as? Double,
			let posterPath = jsonDictionary["poster_path"] as? String
			else {
				return nil
		}
		
		self.id = id
		self.title = title
		self.score = score
		self.movieDescription = movieDescription
		self.posterPath = posterPath
		
	}
	
}
