//
//  PaginatedListSourcePrefetchingState.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/21/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

enum PaginatedListSourcePrefetchingState {
	
	case prefetch
	case cancel
	
	var prefetch: Bool {
		switch self {
		case .prefetch:
			return true
		case .cancel:
			return false
		}
	}
	
	var cancel: Bool {
		switch self {
		case .prefetch:
			return false
		case .cancel:
			return true
		}
	}
	
	static func == (
		lhs: PaginatedListSourcePrefetchingState,
		rhs: PaginatedListSourcePrefetchingState)
		-> Bool
	{
		
		switch (lhs, rhs) {
			
		case (.prefetch, .prefetch),
		     (.cancel, .cancel):
			
			return true
			
		default:
			return false
		}
		
	}
	
}
