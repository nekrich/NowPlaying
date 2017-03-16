//
//  PaginatedListSource.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/16/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation
import UIKit

extension DispatchQueue {
	
	class var currentLabel: String? {
		return String(validatingUTF8: __dispatch_queue_get_label(nil))
	}
	
}

extension Array {
	
	func appending(_ newElement: Element) -> [Element] {
		var result = self
		result.append(newElement)
		return result
	}
	
	func appending<S: Sequence>(contentsOf newElements: S) -> [Element]
		where S.Iterator.Element == Element
	{
		var result = self
		newElements.forEach { result.append($0) }
		return result
	}
	
	func appending<C: Collection>(contentsOf newElements: C) -> [Element]
		where C.Iterator.Element == Element
	{
		var result = self
		newElements.forEach { result.append($0) }
		return result
	}
	
}

struct Atomic<Value> {
	
	private var semaphore = DispatchSemaphore(value: 1)
	
	private var _value: Value
	var value: Value {
		get {
			semaphore.wait(); defer { semaphore.signal() }
			let value = _value
			return value
		}
		set {
			semaphore.wait(); defer { semaphore.signal() }
			_value = newValue
		}
	}
	
	init(value: Value) {
		self._value = value
	}
	
}

class PaginatedListSource<Item: Any, Filter: Any> {
	
	private(set) var pageSize: Int = 20
	private(set) var fetchNextPageItemIndex: Int = 10
	
	typealias Tuple = (URLSessionDataTask, FetchCompletionBlock)
	
	private var prefetchingPages: Atomic<[Int : URLSessionDataTask]> = Atomic(value: [:])
	
	private var waitingForPrefetchingCompletionPages: Atomic<[Int : FetchCompletionBlock]> = Atomic(value: [:])
	
	private var fetchingPages: Atomic<[Int : Tuple]> = Atomic(value: [:])
	
	private var prefetchedPages: Atomic<[Int : [Item]]> = Atomic(value: [:])
	
	private var fetchedPages: Atomic<Set<Int>> = Atomic(value: Set())
	
	private(set) var totalElementsCount: Int = 0 {
		didSet {
			totalPageNumber = Int(floor(Float(totalElementsCount) / Float(pageSize))) + (totalElementsCount == 0 ? 0 : 1)
		}
	}
	
	private(set) var totalPageNumber: Int = 0
	
	private var _items: Atomic<[Item]> = Atomic(value: [])
	var items: [Item] {
		return _items.value
	}
	private(set) var lastFetchedPage: Atomic<Int> = Atomic(value: 0)
	
	var filter: Filter? {
		didSet {
			reloadData(completionHandler: { _ in })
		}
	}
	
	typealias FetchCompletionBlock =
		(_ result: Result<[Item]>,
		_ totalElementsCount: Int?)
		-> Void
	
	typealias PageFetchBlock = (
		_ pageNumber: Int,
		_ filter: Filter?,
		_ completionHandler: @escaping FetchCompletionBlock)
		-> URLSessionDataTask
	
	var fetchPage: PageFetchBlock
	
	init(pageFetchBlock: @escaping PageFetchBlock, completionHandler: @escaping FetchCompletionBlock) {
		self.fetchPage = pageFetchBlock
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
	
	private func fetch(
		pageNumber: Int,
		completionHandler: @escaping FetchCompletionBlock)
	{
		
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
		
		let task = fetchPage(pageNumber, filter) { [weak self] (result: Result<[Item]>, totalElementsCount) in
			
			self?.fetchResult(pageNumber: pageNumber,
			                  result: result,
			                  totalElementsCount: totalElementsCount,
			                  completionHandler: completionHandler)
			
		}
		
		fetchingPages.value[pageNumber] = (task, completionHandler)
		
	}
	
	private var queue: DispatchQueue = {
		
		let queue: DispatchQueue
		let label = "itemsFetching queue\(Item.self)"
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
		result: Result<[Item]>,
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
		pageNumber: Int, items: [Item],
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
		items: [Item],
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
		
		guard prefetchingPages.value[pageNumber] == .none
			else {
				return
		}
		
		let task = fetchPage(pageNumber, filter) { [weak self] (result: Result<[Item]>, totalElementsCount) in
			
			self?.fetchResult(pageNumber: pageNumber,
			                  result: result,
			                  totalElementsCount: totalElementsCount,
			                  prefetching: true)
			
		}
		
		prefetchingPages.value[pageNumber] = task
		
	}
	
}
