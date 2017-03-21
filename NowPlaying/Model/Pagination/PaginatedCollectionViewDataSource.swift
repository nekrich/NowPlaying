//
//  PaginatedCollectionViewDataSource.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/21/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

class PaginatedCollectionViewDataSource<Element, FetchTask, Filter>: PaginatedDataSource<Element, FetchTask, Filter>,
	UICollectionViewDataSource
{
	
	let cellDescriptor: (Element?) -> CollectionViewCellDescriptor
	
	init(
		pageFetchBlock: @escaping DataSourceType.PageFetchBlock,
		prefetchingBlock: DataSourceType.PrefetchingBlock? = .none,
		completionHandler: DataSourceType.FetchCompletionBlock? = .none,
		cellDescriptor: @escaping (Element?) -> CollectionViewCellDescriptor
		)
	{
		self.cellDescriptor = cellDescriptor
		super.init(pageFetchBlock: pageFetchBlock, prefetchingBlock: prefetchingBlock, completionHandler: completionHandler)
	}
	
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return numberOfRows
	}
	
	private var reuseIdentifiers: Set<String> = []
	
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let element: Element?
		if indexPath.row < elements.count {
			element = elements[indexPath.row]
		} else {
			element = .none
		}
		
		if element == nil && elements.count != dataSource.totalElementsCount {
			fetchNextPage(collectionView: collectionView)
		}
		
		let descriptor = cellDescriptor(element)
		
		if !reuseIdentifiers.contains(descriptor.reuseIdentifier) {
			descriptor.register(collectionView)
		}
		
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: descriptor.reuseIdentifier, for: indexPath)
		descriptor.configure(cell, indexPath)
		return cell
	}
	
}
