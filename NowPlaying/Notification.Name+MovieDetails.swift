//
//  Notification.Name+MovieDetails.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/15/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

extension Notification.Name {
	
	static var NewMovieDetails: Notification.Name {
		return Notification.Name("NPNewMovieDetails")
	}
	
	static var NewMovieAuditoryRaiting: Notification.Name {
		return Notification.Name("NPNewMovieAuditoryRaiting")
	}
	
}
