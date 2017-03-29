//
//  Array+appending.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/21/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

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
