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
	UICollectionViewDelegateFlowLayout
{
	
	@IBOutlet fileprivate private(set) weak var collectionView: UICollectionView!
	
	@IBOutlet fileprivate weak var collectionViewFlowLayout: MoviesCollectionViewFlowLayout!
	
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
	
	private(set) weak var refreshControl: UIRefreshControl!
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		collectionView.register(cellType: MovieCollectionViewCell.self)
		collectionView.register(cellType: SpinnerCollectionViewCell.self)
		
		collectionView.backgroundColor = .collectionViewBackground
		
		dataSource.delegate = self
		collectionView.dataSource = dataSource
		if #available(iOS 10.0, *) {
			collectionView.prefetchDataSource = dataSource
		} else {
			// Fallback on earlier versions
		}
		
		collectionView.delegate = self
		
		let refreshControl = UIRefreshControl()
		refreshControl.addTarget(self,
		                         action: #selector(self.reloadData(_:)),
		                         for: .valueChanged)
		
		if #available(iOS 10.0, *) {
			collectionView.refreshControl = refreshControl
			collectionView.sendSubview(toBack: refreshControl)
		} else {
			collectionView.insertSubview(refreshControl, at: 0)
		}
		self.refreshControl = refreshControl
		
		let backButtonTitle = Bundle.main.localizedString(forKey: "BACK",
		                                                  value: .none,
		                                                  table: .none)
		self.navigationItem.backBarButtonItem = UIBarButtonItem(title: backButtonTitle,
		                                                        style: .done,
		                                                        target: .none,
		                                                        action: .none)
		
	}
	
	func reloadData(_ sender: Any) {
		
		dataSource.reloadData { _ in }
		
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		didSelectItemAt indexPath: IndexPath)
	{
		
		guard indexPath.row < dataSource.movies.count
			else {
				return
		}
		
		let itemIndex = indexPath.row
		let movieDetailsController = MovieDetailsViewController()
		movieDetailsController.indexPath = indexPath
		movieDetailsController.movie = dataSource.movies[itemIndex]
		movieDetailsController.moviePosterWidth = collectionViewFlowLayout.itemSize.width
		navigationController?.pushViewController(movieDetailsController, animated: true)
		
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		layout collectionViewLayout: UICollectionViewLayout,
		sizeForItemAt indexPath: IndexPath)
		-> CGSize
	{
		let layout = self.collectionViewFlowLayout! // swiftlint:disable:this force_unwrapping
		guard indexPath.row >= dataSource.movies.count  else {
			return layout.itemSize
		}
		
		let width = collectionView.bounds.width - (layout.sectionInset.left + layout.sectionInset.right)
		
		return CGSize(width: width, height: 45)
		
	}
	
}

// MARK: - MovieCollectionViewDataSource

extension NowPlayingCollectionViewController {
	
	func movieCollectionViewDataSource(
		_ source: MovieCollectionViewDataSource,
		didFinshInitializationWith result: Result<Void>)
	{
		refreshControl.endRefreshing()
		collectionView.reloadData()
	}
	
}
