//
//  PaginatedListSource.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/16/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation
import UIKit

protocol PaginatedListSourceDelegate: class {
	
	func paginatedListSource<Element, FetchTask, Filter>(
		_ source: PaginatedListSource<Element, FetchTask, Filter>,
		didFinshInitializationWith result: Result<Void>)
	
	func paginatedListSource<Element, FetchTask, Filter>(
		_ source: PaginatedListSource<Element, FetchTask, Filter>,
		didFetchElements elements: [Element])
	
}

protocol Cancelable {
	func cancel()
}

class PaginatedListSource<Element, FetchTask: Cancelable, Filter>: NSObject { // swiftlint:disable:this type_body_length
	
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
	
	private var _elements: Atomic<[Element]> = Atomic(value: [])
	var elements: [Element] {
		return _elements.value
	}
	private(set) var lastFetchedPage: Atomic<Int> = Atomic(value: 0)
	
	var filter: Filter? {
		didSet {
			reloadData(completionHandler: { _ in })
		}
	}
	
	var fetchPage: PageFetchBlock
	
	weak var delegate: PaginatedListSourceDelegate?
	
	init(
		pageSize: Int,
		delegate: PaginatedListSourceDelegate?,
		pageFetchBlock: @escaping PageFetchBlock,
		completionHandler: @escaping FetchCompletionBlock)
	{
		self.fetchPage = pageFetchBlock
		self.pageSize = pageSize
		self.delegate = delegate
		super.init()
		DispatchQueue.main.async {
			self.reloadData(completionHandler: completionHandler)
		}
	}
	
	deinit {
		NotificationCenter.default.removeObserver(self)
	}
	
	func reloadData(completionHandler: @escaping FetchCompletionBlock) {
		prefetchingPages.value.forEach {
			$0.1.cancel()
		}
		fetchingPages.value.forEach {
			$0.1.0?.cancel()
		}
		operationQueue.cancelAllOperations()
		operationQueue.waitUntilAllOperationsAreFinished()
		fetchedPages = Atomic(value: Set())
		lastFetchedPage.value = 0
		totalElementsCount = 0
		prefetchingPages.value = [:]
		prefetchedPages.value = [:]
		fetchingPages.value = [:]
		fetch(pageNumber: 1) { [weak self] (result, totalElementsCount) in
			self?.delegateDidFinshInitialization(result: result)
			completionHandler(result, totalElementsCount)
		}
		
	}
	
	private func delegateDidFinshInitialization(result: Result<[Element]>) {
		let delegateResult: Result<Void>
		if let error = result.error {
			delegateResult = .failure(error)
		} else {
			delegateResult = .success()
		}
		delegate?.paginatedListSource(self, didFinshInitializationWith: delegateResult)
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
		if elements.count == totalElementsCount {
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
		
		guard elements.count != totalElementsCount || totalElementsCount == 0
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
		
		if let elements = prefetchedPages.value[pageNumber] {
			fetchResult(pageNumber: pageNumber,
			            result: .success(elements),
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
	
	private lazy var operationQueue: OperationQueue = {
		let operationQueue = OperationQueue()
		operationQueue.maxConcurrentOperationCount = 1
		operationQueue.qualityOfService = .utility
		operationQueue.underlyingQueue = self.queue
		return operationQueue
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
			operationQueue.addOperation {
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
			self._elements.value = []
		}
		
		if !prefetching {
			fetchedItems(pageNumber: pageNumber,
			             elements: itemsResult,
			             totalElementsCount: _totalElementsCount,
			             completionHandler: completionHandler)
		} else {
			prefetchedItems(pageNumber: pageNumber,
			                elements: itemsResult,
			                totalElementsCount: _totalElementsCount)
		}
		
	}
	
	private func prefetchedItems(
		pageNumber: Int,
		elements: [Element],
		totalElementsCount: Int)
	{
		
		defer {
			prefetchingPages.value[pageNumber] = .none
		}
		
		prefetchedPages.value[pageNumber] = elements
		
		if let waitingForPrefetchingBlock = waitingForPrefetchingCompletionPages.value[pageNumber] {
			fetchResult(pageNumber: pageNumber,
			            result: .success(elements),
			            totalElementsCount: totalElementsCount,
			            completionHandler: waitingForPrefetchingBlock)
		}
		
	}
	
	private func fetchedItems(
		pageNumber: Int,
		elements: [Element],
		totalElementsCount: Int,
		completionHandler: FetchCompletionBlock? = .none)
	{
		
		defer {
			fetchedPages.value.insert(pageNumber)
			fetchingPages.value[pageNumber] = .none
			lastFetchedPage.value += 1
			DispatchQueue.main.async {
				completionHandler?(.success(elements), totalElementsCount)
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
		
		self._elements.value = self._elements.value.appending(contentsOf: elements)
		
		if (pageNumber + 1) < totalPageNumber {
			prefetch(pageNumber: pageNumber + 1)
		}
		
		delegate?.paginatedListSource(self, didFetchElements: elements)
		
	}
	
	private func prefetch(pageNumber: Int) {
		
		guard prefetchingPages.value[pageNumber] == nil
			else {
				return
		}
		
		let task = fetchPage(pageNumber, filter) { [weak self] result, totalElementsCount in
			
			if self?.prefetchingPages.value.keys.contains(pageNumber) ?? false {
				
				self?.fetchResult(pageNumber: pageNumber,
				                  result: result,
				                  totalElementsCount: totalElementsCount,
				                  prefetching: true)
			}
		}
		
		prefetchingPages.value[pageNumber] = task
		
	}
	
	func shouldFetchNextPage(afterPrefetchItemsAt indexPaths: [IndexPath]) -> Bool {
		
		var shouldFetchNextPage: Bool = false
		indexPaths.forEach {
			guard $0.row < elements.count
				else {
					shouldFetchNextPage = true
					return
			}
			guard let prefetchingBlock = prefetchingBlock
				else {
					return
			}
			prefetchingBlock(elements[$0.row], .prefetch)
		}
		
		return shouldFetchNextPage
		
	}
	
	func cancelPrefetchingForItemsAt(indexPaths: [IndexPath]) {
		
		indexPaths.forEach {
			guard
				$0.row < elements.count,
				let prefetchingBlock = prefetchingBlock
				else {
					return
			}
			prefetchingBlock(elements[$0.row], .cancel)
		}
		
	}
	
} // swiftlint:disable:this file_length
