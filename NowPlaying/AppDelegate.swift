//
//  AppDelegate.swift
//  NowPlaying
//
//  Created by Vitalii Budnik on 3/14/17.
//  Copyright © 2017 Vitalii Budnik. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	
	var window: UIWindow?
	
	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?)
		-> Bool
	{
		
		let nowPlayingController = NowPlayingCollectionViewController()
		let navigationController = UINavigationController(rootViewController: nowPlayingController)
		navigationController.navigationBar.barTintColor = .navigationBarTintColor
		
		let window = UIWindow(frame: UIScreen.main.bounds)
		window.makeKeyAndVisible()
		
		window.rootViewController = navigationController
		
		self.window = window
		
		return true
		
	}
	
}
