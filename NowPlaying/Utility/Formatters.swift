//
//  Formatters.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/15/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

struct Formatters {
	
	static let incomingReleaseDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateFormat = "yyyy-MM-dd"
		return formatter
	}()
	
	static let releaseDateFormatter: DateFormatter = {
		let formatter = DateFormatter()
		formatter.dateStyle = .medium
		formatter.timeStyle = .none
		return formatter
	}()
	
}
