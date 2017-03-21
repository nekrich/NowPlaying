//
//  Atomic.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/21/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

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
