//
//  PaginatedListSource.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/16/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation
import UIKit

class PaginatedListSource<Element, FetchTask, Filter>: NSObject { // swiftlint:disable:this type_body_length
	
	let pageSize: Int
	
	typealias FetchCompletionBlock =
		(_ result: Result<[Element]>,
		_ totalElementsCount: Int?)
		-> Void
	
	typealias PageFetchBlock = (
		_ pageNumber: Int,
		_ filter: Filter?,
		_ completionHandler: @escaping FetchCompletionBlock)
		-> FetchTask?
	
	typealias PrefetchingBlock = (Element, _ prefetchingState: PaginatedListSourcePrefetchingState) -> Void
	
	private typealias Tuple = (FetchTask?, FetchCompletionBlock)
	
	var prefetchingBlock: PrefetchingBlock?
	
	private var prefetchingPages: Atomic<[Int : FetchTask]> = Atomic(value: [:])
	
	private var prefetchedPages: Atomic<[Int : [Element]]> = Atomic(value: [:])

	private var waitingForPrefetchingCompletionPages: Atomic<[Int : FetchCompletionBlock]> = Atomic(value: [:])
	
	private var fetchingPages: Atomic<[Int : Tuple]> = Atomic(value: [:])
	
	private var fetchedPages: Atomic<Set<Int>> = Atomic(value: Set())
	
	private(set) var totalElementsCount: Int = 0 {
		didSet {
			totalPageNumber = Int(floor(Float(totalElementsCount) / Float(pageSize))) + (totalElementsCount == 0 ? 0 : 1)
		}
	}
	
	private(set) var totalPageNumber: Int = 0
	
	private var _items: Atomic<[Element]> = Atomic(value: [])
	var items: [Element] {
		return _items.value
	}
	private(set) var lastFetchedPage: Atomic<Int> = Atomic(value: 0)
	
	var filter: Filter? {
		didSet {
			reloadData(completionHandler: { _ in })
		}
	}
	
	var fetchPage: PageFetchBlock
	
	init(
		pageSize: Int = 20,
		pageFetchBlock: @escaping PageFetchBlock,
		completionHandler: @escaping FetchCompletionBlock)
	{
		self.fetchPage = pageFetchBlock
		self.pageSize = pageSize
		super.init()
		reloadData(completionHandler: completionHandler)
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func reloadData(completionHandler: @escaping FetchCompletionBlock) {
		
		fetchedPages = Atomic(value: Set())
		lastFetchedPage.value = 0
		fetch(pageNumber: 1, completionHandler: completionHandler)
		
	}
	
	func fetchNextPage(completionHandler: @escaping FetchCompletionBlock) {
		fetch(pageNumber: lastFetchedPage.value + 1, completionHandler: completionHandler)
	}
	
	func fetchNextPage(collectionView: UICollectionView, completionHandler: FetchCompletionBlock?) {
		fetchNextPage { [weak self] result, totalElementsCount in
			
			self?.addRowsTo(view: collectionView,
			                result: result,
			                totalElementsCount: totalElementsCount,
			                completionHandler: completionHandler)
			
		}
	}
	
	func fetchNextPage(tableView: UITableView, completionHandler: FetchCompletionBlock?) {
		fetchNextPage { [weak self] result, totalElementsCount in
			
			self?.addRowsTo(view: tableView,
			                result: result,
			                totalElementsCount: totalElementsCount,
			                completionHandler: completionHandler)
			
		}
	}
	
	private func addRowsTo(
		view: UIScrollView,
		result: Result<[Element]>,
		totalElementsCount: Int?,
		completionHandler: FetchCompletionBlock?)
	{
		
		let handler: FetchCompletionBlock = {
			if view.contentSize.height > view.frame.height {
				view.flashScrollIndicators()
			}
			completionHandler?($0, $1)
		}
		
		let startingIndex = (lastFetchedPage.value - 1) * pageSize
		let lastIndex = startingIndex + (result.value?.count ?? 0)
		var indexPaths: [IndexPath] = []
		for index in startingIndex..<lastIndex {
			indexPaths.append(IndexPath(row: index, section: 0))
		}
		guard !indexPaths.isEmpty
			else {
				return
		}
		let lastIndexPath: IndexPath?
		if items.count == totalElementsCount {
			lastIndexPath = IndexPath(row: (totalPageNumber - 1) * pageSize,
			                          section: 0)
		} else {
			lastIndexPath = .none
		}
		
		if let tableView = view as? UITableView {
			tableView.beginUpdates()
			
			if let lastIndexPath = lastIndexPath {
				tableView.deleteRows(at: [lastIndexPath], with: .automatic)
			}
			if !indexPaths.isEmpty {
				tableView.insertRows(at: indexPaths, with: .automatic)
			}
			
			tableView.endUpdates()
			
			handler(result, totalElementsCount)
		} else if let collectionView = view as? UICollectionView {
			collectionView.performBatchUpdates({
				
				if let lastIndexPath = lastIndexPath {
					collectionView.deleteItems(at: [lastIndexPath])
				}
				if !indexPaths.isEmpty {
					collectionView.insertItems(at: indexPaths)
				}
				
			}) { _ in
				handler(result, self.totalElementsCount)
			}
		}
		
	}
	
	private func fetch(
		pageNumber: Int,
		completionHandler: @escaping FetchCompletionBlock)
	{
		
		guard items.count != totalElementsCount || totalElementsCount == 0
			else {
				return
		}
		
		guard
			!fetchedPages.value.contains(pageNumber)
				&& !fetchingPages.value.keys.contains(pageNumber)
			else {
				return
		}
		
		guard !prefetchingPages.value.keys.contains(pageNumber)
			else {
				waitingForPrefetchingCompletionPages.value[pageNumber] = completionHandler
				return
		}
		
		if let items = prefetchedPages.value[pageNumber] {
			fetchResult(pageNumber: pageNumber,
			            result: .success(items),
			            totalElementsCount: totalElementsCount,
			            completionHandler: completionHandler)
			return
		}
		
		let task = fetchPage(pageNumber, filter) { [weak self] (result: Result<[Element]>, totalElementsCount) in
			
			self?.fetchResult(pageNumber: pageNumber,
			                  result: result,
			                  totalElementsCount: totalElementsCount,
			                  completionHandler: completionHandler)
			
		}
		
		fetchingPages.value[pageNumber] = (task, completionHandler)
		
	}
	
	private var queue: DispatchQueue = {
		
		let queue: DispatchQueue
		let label = "itemsFetching queue\(Element.self)"
		if #available(iOS 10.0, *) {
			queue = DispatchQueue(label: label,
			                      qos: .utility,
			                      attributes: [],
			                      autoreleaseFrequency: .workItem,
			                      target: .global())
		} else {
			queue = DispatchQueue(label: label,
			                      qos: .utility,
			                      attributes: [],
			                      target: .global())
		}
		
		return queue
		
	}()
	
	private func fetchResult(
		pageNumber: Int,
		result: Result<[Element]>,
		totalElementsCount: Int?,
		prefetching: Bool = false,
		completionHandler: FetchCompletionBlock? = .none)
	{
		
		guard
			let itemsResult = result.value,
			let _totalElementsCount = totalElementsCount
			else {
				if !prefetching {
					DispatchQueue.main.async {
						completionHandler?(result, totalElementsCount)
					}
				}
				return
		}
		
		if DispatchQueue.currentLabel != queue.label {
			queue.async {
				self.fetchResult(pageNumber: pageNumber,
				                 result: result,
				                 totalElementsCount: totalElementsCount,
				                 prefetching: prefetching,
				                 completionHandler: completionHandler)
			}
			return
		}
		
		if pageNumber == 1 && self.totalElementsCount == 0 {
			self.totalElementsCount = _totalElementsCount
		}
		
		if !prefetching {
			fetchedItems(pageNumber: pageNumber,
			             items: itemsResult,
			             totalElementsCount: _totalElementsCount,
			             completionHandler: completionHandler)
		} else {
			prefetchedItems(pageNumber: pageNumber,
			                items: itemsResult,
			                totalElementsCount: _totalElementsCount)
		}
		
	}
	
	private func prefetchedItems(
		pageNumber: Int, items: [Element],
		totalElementsCount: Int)
	{
		
		defer {
			prefetchingPages.value[pageNumber] = .none
		}
		
		prefetchedPages.value[pageNumber] = items
		
		if let waitingForPrefetchingBlock = waitingForPrefetchingCompletionPages.value[pageNumber] {
			fetchResult(pageNumber: pageNumber,
			            result: .success(items),
			            totalElementsCount: totalElementsCount,
			            completionHandler: waitingForPrefetchingBlock)
		}
		
	}
	
	private func fetchedItems(
		pageNumber: Int,
		items: [Element],
		totalElementsCount: Int,
		completionHandler: FetchCompletionBlock? = .none)
	{
		
		defer {
			fetchedPages.value.insert(pageNumber)
			fetchingPages.value[pageNumber] = .none
			lastFetchedPage.value += 1
			DispatchQueue.main.async {
				completionHandler?(.success(items), totalElementsCount)
			}
		}
		
		assert(lastFetchedPage.value < pageNumber,
		       "Wrong fetched page number: \(pageNumber) instead of \(lastFetchedPage.value + 1)")
		if totalPageNumber == 0 && pageNumber != 1 {
			assert(totalPageNumber >= pageNumber,
			       "Wrong fetched page number: \(pageNumber) instead of \(1)")
		} else if totalPageNumber != 0 {
			assert(totalPageNumber >= pageNumber,
			       "Wrong fetched page number: \(pageNumber) instead of \(totalPageNumber)")
		}
		
		self._items.value = self._items.value.appending(contentsOf: items)
		
		if (pageNumber + 1) < totalPageNumber {
			prefetch(pageNumber: pageNumber + 1)
		}
		
	}
	
	private func prefetch(pageNumber: Int) {
		
		guard prefetchingPages.value[pageNumber] == nil
			else {
				return
		}
		
		let task = fetchPage(pageNumber, filter) { [weak self] result, totalElementsCount in
			
			self?.fetchResult(pageNumber: pageNumber,
			                  result: result,
			                  totalElementsCount: totalElementsCount,
			                  prefetching: true)
			
		}
		
		prefetchingPages.value[pageNumber] = task
		
	}
	
	func shouldFetchNextPage(afterPrefetchItemsAt indexPaths: [IndexPath]) -> Bool {
		
		var shouldFetchNextPage: Bool = false
		indexPaths.forEach {
			guard $0.row < items.count
				else {
					shouldFetchNextPage = true
					return
			}
			guard let prefetchingBlock = prefetchingBlock
				else {
					return
			}
			prefetchingBlock(items[$0.row], .prefetch)
		}
		
		return shouldFetchNextPage
		
	}
	
	func cancelPrefetchingForItemsAt(indexPaths: [IndexPath]) {
		
		indexPaths.forEach {
			guard
				$0.row < items.count,
				let prefetchingBlock = prefetchingBlock
				else {
					return
			}
			prefetchingBlock(items[$0.row], .cancel)
		}
	
	}
	
}
