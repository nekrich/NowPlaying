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

private let pageSize: Int = 20

class MovieCollectionViewDataSource: NSObject,
	UICollectionViewDataSource,
	UICollectionViewDataSourcePrefetching
{
	
	private(set) var movies: [Movie?] = []
	
	weak var delegate: MovieCollectionViewDataSourceDelegate?
	
	fileprivate var prefechingPages: [Int : URLSessionDataTask] = [:]
	fileprivate var fetchedPages: Set<Int> = Set()
	
	override init() {
		super.init()
		
		reloadData()
		
		NotificationCenter.default.addObserver(self,
		                                       selector: #selector(newMovieRaiting(_:)),
		                                       name: .NewMovieAuditoryRaiting,
		                                       object: .none)
		
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func newMovieRaiting(_ notification: Notification) {
		if
			let indexPath = notification.object as? IndexPath,
			let movie = notification.userInfo?["movie"] as? Movie,
			!(movie.auditoryRaitingUS?.isEmpty ?? true)
		{
			movies[indexPath.row] = movie
		}
	}
	
	func reloadData() {
		
		fetchedPages = Set()
		
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
			
			if let totalCount = result.value?.totalCount {
				// On fast (only fast?) scrolling collectionView dosen't pass last indexPath.
				sSelf.fetch(pageNumber: sSelf.page(for: totalCount), completionHandler: { _ in })
			}
			
		}
		
	}
	
	fileprivate func fetch(
		pageNumber: Int,
		completionHandler: @escaping (Result<MovieResult>) -> Void)
	{
		
		let task = API.getItems(page: pageNumber) { [weak self] (result) in
			
			defer {
				self?.fetchedPages.insert(pageNumber)
				self?.prefechingPages[pageNumber] = .none
				completionHandler(result)
				
			}
			
			guard
				let movieResult = result.value,
				let sSelf = self
				else {
					return
			}
			
			var movies: [Movie?]
			if pageNumber == 1 && sSelf.fetchedPages.isEmpty {
				movies = Array(repeating: .none, count: Int(movieResult.totalCount))
			} else {
				movies = sSelf.movies
			}
			
			var rowIndex = (pageNumber - 1) * pageSize
			movieResult.movies.forEach {
				defer { rowIndex += 1 }
				movies[rowIndex] = $0
				let indexPath = IndexPath(row: rowIndex, section: 0)
				NotificationCenter.default.post(name: .NewMovieDetails,
				                                object: indexPath,
				                                userInfo: ["movie" : $0])
				
			}
			
			sSelf.movies = movies
			
		}
		
		prefechingPages[pageNumber] = task
		
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
		
		let pagesToFetch: Set<Int> = pages(from: indexPaths)
			.subtracting(prefechingPages.keys)
			.subtracting(fetchedPages)
		
		guard !pagesToFetch.isEmpty
			else {
				return
		}
		
		pagesToFetch.forEach {
			
			self.fetch(pageNumber: $0, completionHandler: { _ in })
			
		}
		
	}
	
	func collectionView(_ collectionView: UICollectionView, cancelPrefetchingForItemsAt indexPaths: [IndexPath]) {
		
		// On fast (only fast?) scrolling collectionView passes previous indexPath'es, that are not downloaded yet.
		let indexPaths = Set(indexPaths).subtracting(collectionView.indexPathsForVisibleItems)
		
		let pagesToCancelPrefetching: Set<Int> = pages(from: indexPaths)
			.intersection(prefechingPages.keys)
		
		pagesToCancelPrefetching.forEach {
			prefechingPages[$0]?.cancel()
			prefechingPages[$0] = .none
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
		return movies.count
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		cellForItemAt indexPath: IndexPath)
		-> UICollectionViewCell
	{
		
		let cell: MovieCollectionViewCell = collectionView.dequeueReusableCell(for: indexPath)
		
		cell.indexPath = indexPath
		let movie = movies[indexPath.row]
		cell.movie = movie
		
		if
			movie == nil,
			prefechingPages[page(for: indexPath.row)] == .none
		{
			fetch(pageNumber: page(for: indexPath.row), completionHandler: { _ in })
		}
		
		return cell
		
	}
	
}
