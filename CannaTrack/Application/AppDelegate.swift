//
//  AppDelegate.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import CloudKit
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

	var window: UIWindow?
	var shortcutItemToProcess: UIApplicationShortcutItem?

	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
		// Override point for customization after application launch.

		UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge]) { (granted, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error.localizedDescription)
				} else {
					application.registerForRemoteNotifications()
				}
			}

		}
		UNUserNotificationCenter.current().delegate = self

		if let shortcutItem = launchOptions?[UIApplication.LaunchOptionsKey.shortcutItem] as? UIApplicationShortcutItem {
			shortcutItemToProcess = shortcutItem
		}
		application.isNetworkActivityIndicatorVisible = true

		return true
	}

	func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
		// Alternatively, a shortcut item may be passed in through this delegate method if the app was
		// still in memory when the Home screen quick action was used. Again, store it for processing.
		shortcutItemToProcess = shortcutItem
	}



	func applicationWillResignActive(_ application: UIApplication) {
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.

		//dynamic quick items setup
		/*
		application.shortcutItems = {
			let shortcutItems: [UIApplicationShortcutItem] = [
				UIApplicationShortcutItem(type: "com.Lygre.CannaTrack.dose", localizedTitle: "Dose", localizedSubtitle: "Can dose now", icon: UIApplicationShortcutIcon(type: .compose), userInfo: nil),
				UIApplicationShortcutItem(type: "SearchAction", localizedTitle: "Search", localizedSubtitle: "Can search", icon: UIApplicationShortcutIcon(type: .search), userInfo: nil)
			]
			return shortcutItems
		}()
		*/
	}

	func applicationDidEnterBackground(_ application: UIApplication) {
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication) {
		// Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication) {
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
		if let shortcutItem = shortcutItemToProcess {
			let storyboard = UIStoryboard(name: "Main", bundle: nil)
			guard let modalDoseVC = storyboard.instantiateViewController(withIdentifier: modalDoseViewControllerIdentifier) as? LogDoseFromCalendarViewController else { return }
			let navController = UINavigationController(rootViewController: modalDoseVC)

			window?.rootViewController?.present(navController, animated: true, completion: nil)
			shortcutItemToProcess = nil
		}

	}

	func applicationWillTerminate(_ application: UIApplication) {
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}


	func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
		print("received remote notification")
		let dict = userInfo as! [String: NSObject]
		let notification = CKNotification(fromRemoteNotificationDictionary: dict)
		let db = CloudKitManager.shared
		if notification?.subscriptionID == CloudKitManager.subscriptionID {
			db.handleNotificationForInventory()
			completionHandler(.newData)
		}
		else {
			completionHandler(.noData)
		}

		/*
let dict = userInfo as! [String: NSObject]
guard let notification: CKDatabaseNotification = CKNotification(fromRemoteNotificationDictionary: dict) as? CKDatabaseNotification else { return }
let db = CloudKitManager.shared
if notification.subscriptionID == CloudKitManager.subscriptionID {
//			guard let viewController = viewController as? InventoryViewController else { return }

db.handleNotification()
completionHandler(.newData)
} else if notification.subscriptionID == CloudKitManager.dosesSubscriptionID {
//			db.handleDoseNotification()
print("notification received from dose subscription")
}
else {
completionHandler(.noData)
}
*/
	}

	func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
		//!!MARK -- change the nature of the notification, alter this array being passed by completion handler
		completionHandler([.alert, .badge])
	}
}

