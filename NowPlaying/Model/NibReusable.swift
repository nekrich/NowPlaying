//
//  NibReusable.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/15/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

protocol NibReusable: class {
	
	static var reuseIdentifier: String { get }
	
	static var nib: UINib { get }
	
}

extension NibReusable {
	
	static var reuseIdentifier: String {
		return String(describing: self)
	}
	
	static var nib: UINib {
		return UINib(nibName: String(describing: self), bundle: Bundle(for: self))
	}
	
}

extension UICollectionView {
	
	final func register<T: UICollectionViewCell>(cellType: T.Type)
		where T: NibReusable
	{
		self.register(cellType.nib,
		              forCellWithReuseIdentifier: cellType.reuseIdentifier)
	}
	
	final func dequeueReusableCell<T: UICollectionViewCell>(
		for indexPath: IndexPath)
		-> T where T: NibReusable
	{
		let bareCell = self.dequeueReusableCell(withReuseIdentifier: T.reuseIdentifier,
		                                        for: indexPath)
		guard let cell = bareCell as? T
			else {
				fatalError(
					"Failed to dequeue a cell with identifier \(T.reuseIdentifier) matching type \(T.self). "
						+ "Check that the reuseIdentifier is set properly in your XIB/Storyboard "
						+ "and that you registered the cell beforehand"
				)
		}
		return cell
	}
	
}

extension UITableView {
	
	final func register<T: UITableViewCell>(cellType: T.Type)
		where T: NibReusable
	{
		self.register(cellType.nib,
		              forCellReuseIdentifier: cellType.reuseIdentifier)
	}
	
	final func dequeueReusableCell<T: UITableViewCell>(
		for indexPath: IndexPath)
		-> T where T: NibReusable
	{
		guard let cell = self.dequeueReusableCell(withIdentifier: T.reuseIdentifier,
		                                          for: indexPath) as? T
			else {
				fatalError(
					"Failed to dequeue a cell with identifier \(T.reuseIdentifier) matching type \(T.self). "
						+ "Check that the reuseIdentifier is set properly in your XIB/Storyboard "
						+ "and that you registered the cell beforehand"
				)
		}
		return cell
	}
	
}
