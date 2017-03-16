//
//  MovieDetailsTableViewDataSource.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/15/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class MovieDetailsTableViewDataSource: NSObject, UITableViewDataSource {
	
	var movie: Movie? {
		didSet {
			
		}
	}
	
	func register(tableView: UITableView) {
		tableView.register(cellType: MovieMainInfoTableViewCell.self)
		tableView.register(cellType: MovieTextDescriptionTableViewCell.self)
		tableView.register(cellType: MovieDetailsEmptyTableViewCell.self)
	}
	
	func numberOfSections(in tableView: UITableView) -> Int {
		return 1
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return 3
	}
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		switch indexPath.row {
		case 0:
			let cell: MovieMainInfoTableViewCell = tableView.dequeueReusableCell(for: indexPath)
			cell.movie = movie
			return cell
		case 1:
			let cell: MovieTextDescriptionTableViewCell = tableView.dequeueReusableCell(for: indexPath)
			cell.movie = movie
			return cell
		case 2:
			let cell: MovieDetailsEmptyTableViewCell = tableView.dequeueReusableCell(for: indexPath)
			return cell
		default:
			return UITableViewCell()
		}
	}
	
	func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		return false
	}
	
}
