//
//  PaginatedDataSource.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/21/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

protocol PaginatedDataSourceDelegate: class {
	func paginatedDataSource<Element, FetchTask, Filter>(_ source: PaginatedDataSource<Element, FetchTask, Filter>,
	                         didFinshInitializationWith: Result<Void>)
}

class PaginatedDataSource<Element, FetchTask, Filter>: NSObject,
	UICollectionViewDataSourcePrefetching,
	UITableViewDataSourcePrefetching
{
	
	weak var delegate: PaginatedDataSourceDelegate?
	private(set) var dataSource: DataSourceType!
	
	typealias DataSourceType = PaginatedListSource<Element, FetchTask, Filter>
	
	var elements: [Element] {
		return dataSource.items
	}
	
	var prefetchingBlock: DataSourceType.PrefetchingBlock? {
		get {
			return dataSource.prefetchingBlock
		}
		set {
			dataSource.prefetchingBlock = newValue
		}
	}
	
	var filter: Filter? {
		get {
			return dataSource.filter
		}
		set {
			dataSource.filter = newValue
		}
	}
	
	init(
		pageFetchBlock: @escaping DataSourceType.PageFetchBlock,
		prefetchingBlock: DataSourceType.PrefetchingBlock?,
		completionHandler: DataSourceType.FetchCompletionBlock? = .none)
	{
		
		super.init()
		
		dataSource = PaginatedListSource(pageFetchBlock: pageFetchBlock) { [weak self] result, totalElementsCount in
			self?.delegateDidFinshInitialization(result: result)
			completionHandler?(result, totalElementsCount)
		}
		
		dataSource.prefetchingBlock = prefetchingBlock
		
	}
	
	private func delegateDidFinshInitialization(result: Result<[Element]>) {
		let delegateResult: Result<Void>
		if let error = result.error {
			delegateResult = .failure(error)
		} else {
			delegateResult = .success()
		}
		delegate?.paginatedDataSource(self, didFinshInitializationWith: delegateResult)
	}
	
	func reloadData(completionHandler: @escaping DataSourceType.FetchCompletionBlock) {
		
		dataSource.reloadData { [weak self] result, totalEelementsCount in
			
			self?.delegateDidFinshInitialization(result: result)
			
			completionHandler(result, totalEelementsCount)
			
		}
		
	}
	
	func fetchNextPage(
		collectionView: UICollectionView,
		completionHandler: DataSourceType.FetchCompletionBlock? = .none)
	{
		dataSource.fetchNextPage(collectionView: collectionView, completionHandler: completionHandler)
	}
	
	func fetchNextPage(
		tableView: UITableView,
		completionHandler: DataSourceType.FetchCompletionBlock? = .none)
	{
		dataSource.fetchNextPage(tableView: tableView, completionHandler: completionHandler)
	}
	
	// MARK: - UICollectionViewDataSourcePrefetching
	
	func collectionView(
		_ collectionView: UICollectionView,
		prefetchItemsAt indexPaths: [IndexPath])
	{
		
		if dataSource.shouldFetchNextPage(afterPrefetchItemsAt: indexPaths) {
			
			self.fetchNextPage(collectionView: collectionView)
			
		}
		
	}
	
	func collectionView(
		_ collectionView: UICollectionView,
		cancelPrefetchingForItemsAt indexPaths: [IndexPath])
	{
		
		dataSource.cancelPrefetchingForItemsAt(indexPaths: indexPaths)
		
	}
	
	// MARK: - UITableViewDataSourcePrefetching
	
	func tableView(
		_ tableView: UITableView,
		prefetchRowsAt indexPaths: [IndexPath])
	{
		
		if dataSource.shouldFetchNextPage(afterPrefetchItemsAt: indexPaths) {
			
			self.fetchNextPage(tableView: tableView)
			
		}
		
	}
	
	func tableView(
		_ tableView: UITableView,
		cancelPrefetchingForRowsAt indexPaths: [IndexPath])
	{
		
		dataSource.cancelPrefetchingForItemsAt(indexPaths: indexPaths)
		
	}
	
	// MARK: - Rows count
	
	var numberOfRows: Int {
		let itemsCount = elements.count
		return itemsCount + (itemsCount == dataSource.totalElementsCount ? 0 : 1)
	}
	
}
