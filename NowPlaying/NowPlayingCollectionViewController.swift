//
//  NowPlayingCollectionViewController.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class NowPlayingCollectionViewController: UIViewController,
	MovieCollectionViewDataSourceDelegate,
	UICollectionViewDelegate
{
	
	@IBOutlet fileprivate private(set) weak var collectionView: UICollectionView!
	
	// MARK: Lifecycle
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		title = Bundle.main.localizedString(forKey: "NOW PLAYING", value: .none, table: .none)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	fileprivate private(set) var movies: [Movie?] = []
	
	let dataSource = MovieCollectionViewDataSource()
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		collectionView.register(cellType: MovieCollectionViewCell.self)
		
		collectionView.backgroundColor = .collectionViewBackground
		
		dataSource.delegate = self
		collectionView.dataSource = dataSource
		collectionView.prefetchDataSource = dataSource
		
		collectionView.refreshControl = UIRefreshControl()
		collectionView.refreshControl?.addTarget(self,
		                                         action: #selector(self.reloadData(_:)),
		                                         for: .valueChanged)
		
		let backButtonTitle = Bundle.main.localizedString(forKey: "BACK",
		                                                  value: .none,
		                                                  table: .none)
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title: backButtonTitle,
		                                                        style: .done,
		                                                        target: .none,
		                                                        action: .none)
		
	}
	
	func reloadData(_ sender: Any) {
		
		dataSource.reloadData()
		
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		didSelectItemAt indexPath: IndexPath)
	{
		
		let itemIndex = indexPath.row
		let movieDetailsController = MovieDetailsViewController()
		movieDetailsController.indexPath = indexPath
		movieDetailsController.movie = dataSource.movies[itemIndex]
		movieDetailsController.moviePosterWidth =
			(collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize.width
			?? view.frame.width
		navigationController?.pushViewController(movieDetailsController, animated: true)
		
	}
	
}

// MARK: - MovieCollectionViewDataSourceDelegate

extension NowPlayingCollectionViewController {
	
	func movieCollectionViewDataSource(
		_ source: MovieCollectionViewDataSource,
		didFinshInitializationWith result: Result<Void>)
	{
		collectionView.refreshControl?.endRefreshing()
		collectionView.reloadData()
	}
	
}
