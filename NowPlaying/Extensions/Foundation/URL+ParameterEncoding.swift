//
//  URL+ParameterEncoding.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation

extension URL {
	
	private static func query(_ parameters: [String: Any]) -> String {
		
		let components: [String: String] = parameters.reduce([String: String]()) {
			var result = $0
			result[$1.key] = String(describing: $1.value).addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
			return result
		}
		
		return components.map { "\($0.key)=\($0.value)" }.joined(separator: "&")
		
	}
	
	func appendingPercentEncodedParameters(_ parameters: [String: Any]) -> URL {
		
		var urlComponents = URLComponents(url: self, resolvingAgainstBaseURL: false)!
		// swiftlint:disable:previous force_unwrapping
		let percentEncodedQuery = (urlComponents.percentEncodedQuery.map { $0 + "&" } ?? "") + URL.query(parameters)
		urlComponents.percentEncodedQuery = percentEncodedQuery
		return urlComponents.url! // swiftlint:disable:this force_unwrapping
	}
	
}
