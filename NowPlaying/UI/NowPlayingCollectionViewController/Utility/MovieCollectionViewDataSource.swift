//
//  MovieCollectionViewDataSource.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation
import UIKit
import SDWebImage

protocol MovieCollectionViewDataSourceDelegate: class {
	
	func movieCollectionViewDataSource(_ source: MovieCollectionViewDataSource,
	                                   didFinshInitializationWith result: Result<Void>)
	
}

private let pageSize: Int = 20
private let fetchNextPageItemIndex: Int = 10

class MovieCollectionViewDataSource: NSObject,
	UICollectionViewDataSource,
	UICollectionViewDataSourcePrefetching
{
	
	weak var delegate: MovieCollectionViewDataSourceDelegate?
	fileprivate private(set) var dataSource: PaginatedListSource<Movie, Void>!
	
	fileprivate var prefetchingImages: [URL : SDWebImageOperation] = [:]
	
	typealias Item = Movie
	typealias Filter = Void
	var movies: [Item] {
		return dataSource.items
	}
	override init() {
		
		super.init()
		
		dataSource = PaginatedListSource(pageFetchBlock: API.getItems) { result, _ in
			let delegateResult: Result<Void>
			if let error = result.error {
				delegateResult = .failure(error)
			} else {
				delegateResult = .success()
			}
			self.delegate?.movieCollectionViewDataSource(self, didFinshInitializationWith: delegateResult)
		}
		
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func reloadData(completionHandler: @escaping PaginatedListSource<Item, Filter>.FetchCompletionBlock) {
		
		dataSource.reloadData { result, totalEelementsCount in
			
			let delegateResult: Result<Void>
			if let error = result.error {
				delegateResult = .failure(error)
			} else {
				delegateResult = .success()
			}
			self.delegate?.movieCollectionViewDataSource(self, didFinshInitializationWith: delegateResult)
			
			completionHandler(result, totalEelementsCount)
			
		}
		
	}
	
	func fetchNextPage(collectionView: UICollectionView) {
		let dataSource = self.dataSource! // swiftlint:disable:this force_unwrapping
		dataSource.fetchNextPage { result, _ in
			
			var startingIndex = (dataSource.lastFetchedPage.value - 1) * dataSource.pageSize
			if
				let indexPaths: [IndexPath] = result.value?.map({ _ -> IndexPath in
					defer { startingIndex += 1 }
					return IndexPath(row: startingIndex, section: 0)
				})
			{
				collectionView.performBatchUpdates({
					if dataSource.items.count == dataSource.totalElementsCount {
						collectionView.deleteItems(at: [IndexPath(row: (dataSource.totalPageNumber - 1) * dataSource.pageSize,
						                                          section: 0)])
					}
					collectionView.insertItems(at: indexPaths)
				},
				                                   completion: .none)
				
			}
		}
	}
	
}

// MARK: - UICollectionViewDataSourcePrefetching

extension MovieCollectionViewDataSource {
	
	fileprivate func page(for row: Int) -> Int {
		return Int(floor(Float(row) / Float(pageSize))) + 1
	}
	
	private func pages<S: Sequence>(from indexPaths: S) -> Set<Int> where S.Iterator.Element == IndexPath {
		return indexPaths
			.reduce(Set<Int>()) {
				$0.0.union([page(for: $0.1.row)])
		}
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		prefetchItemsAt indexPaths: [IndexPath])
	{
		
		var shouldFetchNextPage: Bool = false
		indexPaths.forEach {
			let width = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize.width ?? 300
			guard $0.row < movies.count
				else {
					shouldFetchNextPage = true
					return
			}
			guard let url = movies[$0.row].posterURL(width: width)
				else {
					return
			}
			let task = SDWebImageManager.shared().loadImage(with: url, options: [], progress: .none) { [weak self] _ in
				self?.prefetchingImages[url] = .none
			}
			prefetchingImages[url] = task
		}
		
		if shouldFetchNextPage {
			
			self.fetchNextPage(collectionView: collectionView)
			
		}
		
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		cancelPrefetchingForItemsAt indexPaths: [IndexPath])
	{
		
		indexPaths.forEach {
			let width = (collectionView.collectionViewLayout as? UICollectionViewFlowLayout)?.itemSize.width ?? 300
			guard let url = movies[$0.row].posterURL(width: width)
				else {
					return
			}
			prefetchingImages[url]?.cancel()
			prefetchingImages[url] = .none
		}
		
	}
	
}

// MARK: - UICollectionViewDelegate

extension MovieCollectionViewDataSource {
	
	func collectionView(
		_ collectionView: UICollectionView,
		numberOfItemsInSection section: Int)
		-> Int
	{
		let moviesCount = dataSource.items.count
		return moviesCount + (moviesCount == dataSource.totalElementsCount ? 0 : 1)
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		cellForItemAt indexPath: IndexPath)
		-> UICollectionViewCell
	{
		
		let cell: UICollectionViewCell
		if indexPath.row < movies.count {
			let movieCell: MovieCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
			movieCell.indexPath = indexPath
			let movie = dataSource.items[indexPath.row]
			movieCell.movie = movie
			cell = movieCell
		} else {
			let spinnerCell: SpinnerCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
			cell = spinnerCell
			self.fetchNextPage(collectionView: collectionView)
		}
		
		return cell
		
	}
	
}
