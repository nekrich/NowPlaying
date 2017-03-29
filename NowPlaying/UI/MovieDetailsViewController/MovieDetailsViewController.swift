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
			if
				let movie = movie,
				let indexPath = indexPath,
				(movie.auditoryRaitingUS?.isEmpty ?? true)
			{
				movie.fetchRaiting(itemIndexPath: indexPath,
				                   completionHandler: { [weak self] in self?.newMovieAuditoryRaitingDetails($0) })
			}
		}
	}
	
	var indexPath: IndexPath?
	
	var moviePosterWidth: CGFloat = 0 {
		didSet {
			configure()
		}
	}
	
	private let dataSource: MovieDetailsTableViewDataSource = MovieDetailsTableViewDataSource()
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		tableView.contentInset = UIEdgeInsets(top: topLayoutGuide.length,
		                                      left: tableView.contentInset.left,
		                                      bottom: bottomLayoutGuide.length,
		                                      right: tableView.contentInset.right)
	}
	
	private func newMovieAuditoryRaitingDetails(_ result: Result<Movie>) {
		if result.value?.auditoryRaitingUS != .none {
			self.movie = result.value
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		configure()
		
		tableView.rowHeight = UITableViewAutomaticDimension
		tableView.estimatedRowHeight = 44.0
		tableView.tableFooterView = UIView()
		
		dataSource.register(tableView: tableView)
		tableView.dataSource = dataSource
		
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
			self.movie = notification.userInfo?[Notification.Name.MovieUserInfoKeys.movie] as? Movie
		}
	}
	
	private func configure() {
		dataSource.movie = movie
		guard isViewLoaded else {
			return
		}
		moviePosterImageView.sd_setImage(with: movie?.posterURL(width: moviePosterWidth))
		tableView.reloadData()
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
