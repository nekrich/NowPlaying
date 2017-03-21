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

class MovieCollectionViewDataSource: PaginatedCollectionViewDataSource<Movie, URLSessionDataTask, Void> {
	
	weak var collectionViewFlowLayout: UICollectionViewFlowLayout?
	
	private let defaultItemWidth: CGFloat
	private var itemWidth: CGFloat {
		return collectionViewFlowLayout?.itemSize.width ?? defaultItemWidth
	}
	
	private var prefetchingImages: [URL : SDWebImageOperation] = [:]
	
	init(collectionViewFlowLayout: UICollectionViewFlowLayout) {
		self.collectionViewFlowLayout = collectionViewFlowLayout
		self.defaultItemWidth = collectionViewFlowLayout.itemSize.width
		
		super.init(pageFetchBlock: API.getItems) { (movie) -> CollectionViewCellDescriptor in
			switch movie {
			case .some(let element):
				return CollectionViewCellDescriptor { (cell: MovieCollectionViewCell, indexPath) in
					cell.indexPath = indexPath
					cell.movie = element
				}
			case .none:
				return CollectionViewCellDescriptor { (_: SpinnerCollectionViewCell, _) in }
			}
		}
		
		prefetchingBlock = prefetch
		
	}
	
	private func prefetch(element: Movie, prefetch: PaginatedListSourcePrefetchingState) {
		guard
			let url = element.posterURL(width: itemWidth)
			else {
				return
		}
		
		if prefetch.prefetch {
			
			let task = SDWebImageManager.shared().loadImage(with: url, options: [], progress: .none) { [weak self] _ in
				self?.prefetchingImages[url] = .none
			}
			self.prefetchingImages[url] = task
			
		} else {
			
			self.prefetchingImages[url]?.cancel()
			self.prefetchingImages[url] = .none
			
		}
		
	}
	
}
