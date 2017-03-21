//
//  DispatchQueue+currentLabel.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/21/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

extension DispatchQueue {
	
	class var currentLabel: String? {
		return String(validatingUTF8: __dispatch_queue_get_label(nil))
	}
	
}
