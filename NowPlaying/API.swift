//
//  API.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import Foundation
import UIKit

struct API {
	
	static private let hostname: String = "https://api.themoviedb.org/"
	
	static private let hostURL: URL = URL(string: hostname)! // swiftlint:disable:this force_unwrapping
	
	static let apiURL: URL = hostURL.appendingPathComponent("3")
	
	static let postersURL: URL = URL(string: "https://image.tmdb.org/t/p/")! // swiftlint:disable:this force_unwrapping
	
	static fileprivate let apiKey: String = "ebea8cfca72fdff8d2624ad7bbf78e4c"
	
	// Activity Indicator
	static private var lock: os_unfair_lock_s = os_unfair_lock_s()
	static private var _activeRequestsCount: UInt = 0
	fileprivate static var activeRequestsCount: UInt {
		get {
			os_unfair_lock_lock(&lock); defer { os_unfair_lock_unlock(&lock) }
			let activeRequestsCount = _activeRequestsCount
			return activeRequestsCount
		}
		set {
			os_unfair_lock_lock(&lock); defer { os_unfair_lock_unlock(&lock) }
			_activeRequestsCount = newValue
			DispatchQueue.main.async {
				UIApplication.shared.isNetworkActivityIndicatorVisible = activeRequestsCount > 0
			}
		}
	}
	
	private static let supportedPosterSizes: [UInt] = [92, 154, 185, 342, 500, 780]
	static func posterURL(width: CGFloat, at posterPath: String) -> URL {
		
		let frameWidth = UInt(ceil(width))
		
		let posterPath = posterPath.hasPrefix("/")
			? String(posterPath.characters.suffix(posterPath.characters.count - 1))
			: posterPath
		
		let posterWidthString: String
		
		if let posterWidth = supportedPosterSizes.first(where:  { $0 >= frameWidth }) {
			posterWidthString = "w\(posterWidth)"
		} else {
			posterWidthString = "original"
		}
		
		return postersURL.appendingPathComponent(posterWidthString).appendingPathComponent(posterPath)
		
	}
	
}

extension API {
	
	enum Error: LocalizedError {
		case noDataInResponse
		case cantParseResponse
		var errorDescription: String? {
			switch self {
			case .noDataInResponse:
				return "NO DATA IN RESPONSE"
			case .cantParseResponse:
				return "CAN NOT PARSE RESPONSE"
			}
		}
		
		var localizedDescription: String {
			return Bundle.main.localizedString(forKey: self.errorDescription ?? "UNKNOWN ERROR",
			                                   value: .none,
			                                   table: .none)
		}
		
	}
	
	private static func jsonResponse(handler: @escaping (Result<[String : Any]>) -> Void)
		-> ((Data?, URLResponse?, Swift.Error?) -> Void)
	{
		
		return { (data: Data?, response: URLResponse?, error: Swift.Error?) in
			if let error = error {
				handler(.failure(error))
				return
			}
			
			guard let data = data
				else {
					handler(.failure(API.Error.noDataInResponse))
					return
			}
			
			let responseObject: Any
			do {
				responseObject = try JSONSerialization.jsonObject(with: data, options: [])
			} catch {
				handler(.failure(error))
				return
			}
			
			guard let json = responseObject as? [String : Any]
				else {
					handler(.failure(API.Error.cantParseResponse))
					return
			}
			
			handler(.success(json))
			
		}
		
	}
	
	static func getItems(
		page: Int = 1,
		completionHandler: @escaping (Result<MovieResult>) -> Void)
	{
		
		let handler: (Result<MovieResult>) -> Void = { result in
			DispatchQueue.main.async {
				completionHandler(result)
			}
		}
		
		var parameters: [String : Any] = [:]
		parameters["api_key"] = apiKey
		parameters["language"] = Locale.current.identifier
		parameters["page"] = page
		
		let url = apiURL.appendingPathComponent("movie/now_playing").appendingPercentEncodedParameters(parameters)
		
		var request = URLRequest(url: url,
		                         cachePolicy: .useProtocolCachePolicy,
		                         timeoutInterval: 30.0)
		request.httpMethod = "GET"
		
		let session = URLSession.shared
		
		let dataTask = session.dataTask(with: request, completionHandler: jsonResponse { result in
			
			defer { API.activeRequestsCount -= 1 }
			
			guard
				let json = result.value,
				let results = json["results"] as? [[String : Any]],
				let totalCount = json["total_results"] as? Int
				else {
					return
			}
			
			let movies: [Movie] = results.flatMap { Movie(jsonDictionary: $0) }
			
			let movieResult = MovieResult(totalCount: totalCount, movies: movies)
			
			completionHandler(.success(movieResult))
			
		})
		
		dataTask.resume()
		
		API.activeRequestsCount += 1
		
	}
	
}
