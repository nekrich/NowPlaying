//
//  MovieCollectionViewDataSource.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation
import UIKit

protocol MovieCollectionViewDataSourceDelegate: class {
	
	func movieCollectionViewDataSource(_ source: MovieCollectionViewDataSource,
	                                   didFinshInitializationWith result: Result<Void>)
	
}

class MovieCollectionViewDataSource: NSObject,
	UICollectionViewDataSource,
	UICollectionViewDataSourcePrefetching
{
	
	fileprivate private(set) var movies: [Movie?] = []
	
	weak var delegate: MovieCollectionViewDataSourceDelegate?
	
	override init() {
		super.init()
		
		reloadData()
		
	}
	
	func reloadData() {
		
		fetch(pageNumber: 1) { [weak self] (result) in
			
			guard let sSelf = self
				else {
					return
			}
			
			let delegateResult: Result<Void>
			if let error = result.error {
				delegateResult = .failure(error)
			} else {
				delegateResult = .success()
			}
			
			sSelf.delegate?.movieCollectionViewDataSource(sSelf,
			                                              didFinshInitializationWith: delegateResult)
			
		}
		
	}
	
	private func fetch(
		pageNumber: Int,
		completionHandler: @escaping (Result<MovieResult>) -> Void)
	{
		
		API.getItems(page: pageNumber) { [weak self] (result) in
			
			defer { completionHandler(result) }
			
			guard
				let movieResult = result.value,
				let sSelf = self
				else {
					return
			}
			
			var movies: [Movie?]
			if pageNumber == 1 {
				movies = Array(repeating: .none, count: Int(movieResult.totalCount))
			} else {
				movies = sSelf.movies
			}
			
			var index = (pageNumber - 1) * 20 + pageNumber == 1 ? 0 : 1
			movieResult.movies.forEach {
				defer { index += 1 }
				movies[index] = $0
			}
			
			sSelf.movies = movies
			
		}
		
	}
	
}

// MARK: - UICollectionViewDataSourcePrefetching

extension MovieCollectionViewDataSource {
	
	func collectionView(
		_ collectionView: UICollectionView,
		prefetchItemsAt indexPaths: [IndexPath])
	{
		
	}
	
}

// MARK: - UICollectionViewDelegate

extension MovieCollectionViewDataSource {
	
	func collectionView(
		_ collectionView: UICollectionView,
		numberOfItemsInSection section: Int)
		-> Int
	{
		return movies.count
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
		
		cell.movie = movies[indexPath.row]
		
		return cell
		
	}
	
}
