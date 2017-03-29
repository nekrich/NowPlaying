//
//  CollectionViewCellDescriptor.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/21/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

struct CollectionViewCellDescriptor {
	let reuseIdentifier: String
	let configure: (UICollectionViewCell, IndexPath) -> Void
	let register: (UICollectionView) -> Void
	
	init<Cell: UICollectionViewCell>(reuseIdentifier: String, configure: @escaping (Cell, IndexPath) -> Void) {
		self.reuseIdentifier = reuseIdentifier
		self.configure = { cell, indexPath in
			configure(cell as! Cell, indexPath) // swiftlint:disable:this force_cast
		}
		self.register = { collectionView in
			collectionView.register(Cell.self, forCellWithReuseIdentifier: reuseIdentifier)
		}
	}
	
	init<Cell: UICollectionViewCell>(configure: @escaping (Cell, IndexPath) -> Void) where Cell: NibReusable {
		self.reuseIdentifier = Cell.reuseIdentifier
		self.configure = { cell, indexPath in
			configure(cell as! Cell, indexPath) // swiftlint:disable:this force_cast
		}
		self.register = { collectionView in
			collectionView.register(cellType: Cell.self)
		}
	}
	
}
