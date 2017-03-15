//
//  MovieDetailsViewController.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/15/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class MovieDetailsViewController: UIViewController {
	
	@IBOutlet private weak var moviePosterImageView: UIImageView!
	@IBOutlet private weak var tableView: UITableView!
	
	var movie: Movie? {
		didSet {
			title = movie?.title
			configure()
		}
	}
	
	var moviePosterWidth: CGFloat = 0 {
		didSet {
			configure()
		}
	}
	
	private let dataSource = MovieDetailsTableViewDataSource()
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		tableView.contentInset = UIEdgeInsets(top: topLayoutGuide.length,
		                                      left: tableView.contentInset.left,
		                                      bottom: bottomLayoutGuide.length,
		                                      right: tableView.contentInset.right)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		configure()
		
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 44.0
		tableView.tableFooterView = UIView()
		
		dataSource.register(tableView: tableView)
		tableView.dataSource = dataSource
		
		
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	private func configure() {
		dataSource.movie = movie
		guard isViewLoaded else {
			return
		}
		moviePosterImageView.sd_setImage(with: movie?.posterURL(width: moviePosterWidth))
	}
	
	/*
	// MARK: - Navigation
	
	// In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	// Get the new view controller using segue.destinationViewController.
	// Pass the selected object to the new view controller.
	}
	*/
	
}
