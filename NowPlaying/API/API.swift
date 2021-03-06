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
	static private var lock: DispatchSemaphore = DispatchSemaphore(value: 1)
	static private var _activeRequestsCount: UInt = 0
	fileprivate static var activeRequestsCount: UInt {
		get {
			lock.wait(); defer { lock.signal() }
			let activeRequestsCount = _activeRequestsCount
			return activeRequestsCount
		}
		set {
			lock.wait(); defer { lock.signal() }
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
			? String(posterPath[posterPath.index(after: posterPath.startIndex)])
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
	
	private static func jsonResponse(handler: @escaping (Result<[String: Any]>) -> Void)
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
			
			guard let json = responseObject as? [String: Any]
				else {
					handler(.failure(API.Error.cantParseResponse))
					return
			}
			
			handler(.success(json))
			
		}
		
	}
	
	private static func getRequest(
		to apiPath: String,
		with parameters: [String: Any]? = .none)
		-> URLRequest
	{
		var parameters = parameters ?? [:]
		parameters["api_key"] = apiKey
		parameters["language"] = Locale.current.identifier
		
		let url = apiURL.appendingPathComponent(apiPath).appendingPercentEncodedParameters(parameters)
		
		var request = URLRequest(url: url,
		                         cachePolicy: .reloadIgnoringLocalCacheData,
		                         timeoutInterval: 30.0)
		request.httpMethod = "GET"
		
		return request
		
	}
	
	@discardableResult
	static func getItems(
		pageIndex: Int = 1,
		filter: Void?,
		completionHandler: @escaping (Result<[Movie]>, Int?) -> Void)
		-> URLSessionDataTask
	{
		
		return getItems(page: pageIndex) { (result: Result<MovieResult>) in
			guard
				let movieResult = result.value
				else {
					completionHandler(.failure(result.error!), .none) // swiftlint:disable:this force_unwrapping
					return
			}
			completionHandler(.success(movieResult.movies),
			                  movieResult.totalCount)
		}
		
	}
	
	@discardableResult
	static func getItems(
		page: Int = 1,
		completionHandler: @escaping (Result<MovieResult>) -> Void)
		-> URLSessionDataTask
	{
		
		let handler: (Result<MovieResult>) -> Void = { result in
			DispatchQueue.main.async {
				completionHandler(result)
			}
		}
		
		let request = getRequest(to: "movie/now_playing",
		                         with: ["page" : page])
		
		let session = URLSession.shared
		
		let dataTask = session.dataTask(with: request, completionHandler: jsonResponse { result in
			
			defer { API.activeRequestsCount -= 1 }
			
			guard
				let json = result.value,
				let results = json["results"] as? [[String: Any]],
				let totalCount = json["total_results"] as? Int
				else {
					return
			}
			
			let movies: [Movie] = results.compactMap(Movie.init)
			
			let movieResult = MovieResult(totalCount: totalCount, movies: movies)
			
			handler(.success(movieResult))
			
		})
		
		dataTask.resume()
		
		API.activeRequestsCount += 1
		
		return dataTask
		
	}
	
	@discardableResult
	static func getMovieDetails(
		_ movie: Movie,
		completionHandler: @escaping (Result<Movie>) -> Void)
		-> URLSessionDataTask
	{
		
		let handler: (Result<Movie>) -> Void = { result in
			DispatchQueue.main.async {
				completionHandler(result)
			}
		}
		
		let request = getRequest(to: "movie/\(movie.id)",
		                         with: ["append_to_response" : "releases"])
		
		let session = URLSession.shared
		
		let dataTask = session.dataTask(with: request, completionHandler: jsonResponse { result in
			
			defer { API.activeRequestsCount -= 1 }
			
			guard
				let json = result.value,
				let updatedMovie = Movie(jsonDictionary: json)
				else {
					handler(.success(movie))
					return
			}
			
			handler(.success(updatedMovie))
			
		})
		
		dataTask.resume()
		
		API.activeRequestsCount += 1
		
		return dataTask
		
	}
	
}
