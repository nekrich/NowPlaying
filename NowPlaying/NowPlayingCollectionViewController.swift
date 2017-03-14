//
//  NowPlayingCollectionViewController.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class NowPlayingCollectionViewController: UIViewController,
	UICollectionViewDataSource,
	UICollectionViewDelegate
{
	
	@IBOutlet private weak var collectionView: UICollectionView!
	
	// MARK: Lifecycle
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		title = Bundle.main.localizedString(forKey: "NOW PLAYING", value: .none, table: .none)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	override func viewDidLoad() {
		
		super.viewDidLoad()
		
		collectionView.register(MovieCollectionViewCell.nib,
		                        forCellWithReuseIdentifier: MovieCollectionViewCell.reuseIdentifier)
		
		collectionView.backgroundColor = .collectionViewBackground
		
		collectionView.dataSource = self
		
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		didSelectItemAt indexPath: IndexPath)
	{
		let itemIndex = indexPath.row
	}
	
}

// MARK: - UICollectionViewDataSource

extension NowPlayingCollectionViewController {
	
	func collectionView(
		_ collectionView: UICollectionView,
		numberOfItemsInSection section: Int)
		-> Int
	{
		return 100
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		cellForItemAt indexPath: IndexPath)
		-> UICollectionViewCell
	{
		
		let bareCell = collectionView.dequeueReusableCell(withReuseIdentifier: MovieCollectionViewCell.reuseIdentifier,
		                                                  for: indexPath)
		guard let cell = bareCell as? MovieCollectionViewCell else {
			fatalError(
				"Failed to dequeue a cell with identifier \(MovieCollectionViewCell.reuseIdentifier)"
					+ " matching type \(MovieCollectionViewCell.self). "
					+ "Check that the reuseIdentifier is set properly in your XIB/Storyboard "
					+ "and that you registered the cell beforehand"
			)
		}
		
		cell.backgroundColor = .red
		
		return cell
		
	}
	
}
