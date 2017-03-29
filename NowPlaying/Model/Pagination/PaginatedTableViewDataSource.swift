//
//  PaginatedTableViewDataSource.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/21/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class PaginatedTableViewDataSource<Element, FetchTask: Cancelable, Filter>:
	PaginatedDataSource<Element, FetchTask, Filter>,
	
	UITableViewDataSource
{
	
	let cellDescriptor: (Element?) -> TableViewCellDescriptor
	
	init(
		pageSize: Int,
		pageFetchBlock: @escaping DataSourceType.PageFetchBlock,
		prefetchingBlock: DataSourceType.PrefetchingBlock? = .none,
		completionHandler: DataSourceType.FetchCompletionBlock? = .none,
		cellDescriptor: @escaping (Element?) -> TableViewCellDescriptor)
	{
		self.cellDescriptor = cellDescriptor
		super.init(pageSize: pageSize,
		           pageFetchBlock: pageFetchBlock,
		           prefetchingBlock: prefetchingBlock,
		           completionHandler: completionHandler)
	}
	
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return numberOfRows
	}
	
	private var reuseIdentifiers: Set<String> = []
	
	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let element: Element?
		if indexPath.row < elements.count {
			element = elements[indexPath.row]
		} else {
			element = .none
		}
		
		if element == nil && elements.count != dataSource.totalElementsCount {
			fetchNextPage(tableView: tableView)
		}
		
		let descriptor = cellDescriptor(element)
		
		if !reuseIdentifiers.contains(descriptor.reuseIdentifier) {
			descriptor.register(tableView)
		}
		
		let cell = tableView.dequeueReusableCell(withIdentifier: descriptor.reuseIdentifier, for: indexPath)
		descriptor.configure(cell, indexPath)
		return cell
		
	}
	
}
