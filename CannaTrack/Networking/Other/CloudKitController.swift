//
//  CloudKitController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/10/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import CloudKit
import NotificationCenter


typealias RequestCKPermissionCompletion = (_ accountStatus: CKAccountStatus, _ error: Error?) -> Void
typealias CreateProductCompletion = (_ success: Bool, _ resultingCloudProduct: Product?, _ error: Error?) -> Void
typealias RetrieveProductsCompletion = (_ products: [Product]?, _ error: Error?) -> Void
typealias UpdateProductCompletion = (_ success: Bool, _ resultingCloudProduct: Product?, _ error: Error?) -> Void
typealias DeleteProductCompletion = (_ success: Bool, _ error: Error?) -> Void
typealias RetrieveProductCompletion = (_ product: Product?, _ moreComing: Bool?) -> Void

//Dose record typealiases
typealias CreateDoseCompletion = (_ success: Bool, _ resultingCloudDose: Dose?, _ error: Error?) -> Void
typealias RetrieveDosesCompletion = (_ doses: [Dose]?, _ error: Error?) -> Void
typealias UpdateDoseCompletion = (_ success: Bool, _ resultingCloudDose: Dose?, _ error: Error?) -> Void
typealias DeleteDoseCompletion = (_ success: Bool, _ error: Error?) -> Void
typealias RetrieveDoseCompletion = (_ dose: Dose?, _ moreComing: Bool?) -> Void


struct CloudKitNotifications {
	static let NotificationReceived = "iCloudRemoteNotificationReceived"
	static let NotificationKey = "Notification"
	static let ProductChange = "ProductChangeReceived"

	static let DoseChange = "DoseChangeReceived"

}

struct CloudKitManager {
	static let shared = CloudKitManager()
	static let privateDatabase = CKContainer.default().privateCloudDatabase
	static let publicDatabase = CKContainer.default().publicCloudDatabase

	static let productsFetchOperation = CKFetchRecordsOperation()
	static let doseFetchOperation = CKFetchRecordsOperation()
//	static let subscriptionID = "cloudkit-product-changes"
	static let subscriptionID = "product-changes"
	static let dosesSubscriptionID = "dose-changes"
	static let subscriptionSavedKey = "ckSubscriptionSaved"
	static let serverChangeTokenKey = "ckServerChangeToken"
	var cloudKitObserver: NSObjectProtocol?

	func requestCloudKitPermission(completion: @escaping RequestCKPermissionCompletion) {
		CKContainer.default().accountStatus(completionHandler: completion)
	}


	func createCKRecord(for product: Product, completion: @escaping CreateProductCompletion) {
		let record = product.toCKRecord()

		CloudKitManager.privateDatabase.save(record) { (serverRecord, error) in
			if let error = error {
				let alertView = UIAlertController(title: "Product Creation Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
				DispatchQueue.main.async {
					UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
				}
			} else {
				guard let serverRecord = serverRecord else {
					DispatchQueue.main.async {
						completion(false, nil, error)
					}
					return
				}
				DispatchQueue.main.async {
					completion(true, Product.fromCKRecord(record: serverRecord), nil)
				}
			}
		}
	}

	func retrieveRemainingRecords(using operationCursor: CKQueryOperation.Cursor) {
		let queryOperation = CKQueryOperation(cursor: operationCursor)
		print("initialized new query using operation cursor")
		CloudKitManager.privateDatabase.add(queryOperation)

	}

	func retrieveAllProducts(completion: @escaping RetrieveProductCompletion) {
		let predicate = NSPredicate(format: "TRUEPREDICATE")
		let query = CKQuery(recordType: "Product", predicate: predicate)


		let queryOperation = CKQueryOperation(query: query)
		queryOperation.queryCompletionBlock = { (operationCursor, error) in
			DispatchQueue.main.async {
				if let error = error {

					print(error.localizedDescription)
				} else {
					if let operationCursor = operationCursor {
						print("query has finished executing, but did not obtain all records. Received operationCursor object as marker to use to receive rest of records. Creating a new query to fetch the rest")
						CloudKitManager.shared.retrieveRemainingRecords(using: operationCursor)
						completion(nil, true)


					} else {
						completion(nil, true)
						print("query completed by CKManager")
					}
				}
			}

		}
		queryOperation.recordFetchedBlock = { record in
			DispatchQueue.main.async {
				guard let product = Product.fromCKRecord(record: record) else { return }
				print("record fetched by query in CKManager")
				completion(product, false)
			}
		}
		let config = CKQueryOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForRequest = 10
		config.timeoutIntervalForResource = 10
		queryOperation.configuration = config

		CloudKitManager.privateDatabase.add(queryOperation)

	}

	func updateProduct(product: Product, completion: @escaping UpdateProductCompletion) {
		let record = product.toCKRecord()
		let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
		let config = CKModifyRecordsOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForRequest = 15
		config.timeoutIntervalForResource = 15
		operation.configuration = config
		operation.savePolicy = .allKeys
		operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
					completion(false, nil, error)
				} else {
					if product.recordID != nil {
						completion(true, product, nil)
						print("Records wwere updated")
					} else {
						completion(true, nil, nil)
						print("okay. Nothing updates")
					}
				}
			}
		}

		CloudKitManager.privateDatabase.add(operation)

	}

	func deleteProductUsingModifyRecords(product: Product, completion: @escaping DeleteProductCompletion) {
		guard let productRecordID = product.recordID else {
			completion(false, nil)
			return
		}

		let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [productRecordID])
		let config = CKModifyRecordsOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForRequest = 10
		config.timeoutIntervalForResource = 10

		operation.configuration = config

		operation.modifyRecordsCompletionBlock = { (_, deletedRecordIDs, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					if let deletedRecordIDs = deletedRecordIDs {
						print(deletedRecordIDs, "deleted")
						completion(true, nil)
					}
				}
			}
		}

		CloudKitManager.privateDatabase.add(operation)

	}




	//fetch operation for products
	func setupFetchOperation(with recordIDs: [CKRecord.ID], completion: @escaping RetrieveProductsCompletion) {
		//need to save the recordIDs locally
		let operation = CKFetchRecordsOperation(recordIDs: recordIDs)
		operation.perRecordProgressBlock = { (recordID, progress) in
			DispatchQueue.main.async {
				print("Record with \(recordID) is \(progress) done")
			}
		}

		operation.perRecordCompletionBlock = { (record, recordID, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else if let record = record, let id = recordID {
					print("Record \(record) fetch completed with ID \(id)")



				}
			}
		}

		operation.fetchRecordsCompletionBlock = { (recordsByID, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					guard let recordsByID = recordsByID else { return }
					var products: [Product] = []
					for (_, record) in recordsByID {
						guard let product = Product.fromCKRecord(record: record) else { return }
						products.append(product)
					}
					completion(products,nil)
					print("Records fetch completed")
				}

			}
		}

		let config = CKFetchRecordsOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForResource = 10
		config.timeoutIntervalForRequest = 10
		operation.configuration = config

		CloudKitManager.privateDatabase.add(operation)

	}

	mutating func saveSubscription() {
		// Use a local flag to avoid saving the subscription more than once.
		let alreadySaved = UserDefaults.standard.bool(forKey: CloudKitManager.subscriptionSavedKey)
		guard !alreadySaved else {
			return
		}

		// If you wanted to have a subscription fire only for particular
		// records you can specify a more interesting NSPredicate here.
		// For our purposes we’ll be notified of all changes.
		let predicate = NSPredicate(value: true)
		let subscription = CKQuerySubscription(recordType: "Product",
											   predicate: predicate,
											   subscriptionID: CloudKitManager.subscriptionID,
											   options: [CKQuerySubscription.Options.firesOnRecordCreation, .firesOnRecordDeletion, .firesOnRecordUpdate])

		// We set shouldSendContentAvailable to true to indicate we want CloudKit
		// to use silent pushes, which won’t bother the user (and which don’t require
		// user permission.)
		let notificationInfo = CKSubscription.NotificationInfo()
		notificationInfo.shouldSendContentAvailable = true

		subscription.notificationInfo = notificationInfo

		let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
		operation.modifySubscriptionsCompletionBlock = { (_, _, error) in
			guard error == nil else {
				return
			}

			UserDefaults.standard.set(true, forKey: CloudKitManager.subscriptionSavedKey)
		}
		operation.qualityOfService = .utility


		CloudKitManager.privateDatabase.add(operation)


	}




	func fetchProductCKQuerySubscriptions() {

		let _: [CKSubscription.ID] = ["product-changes"]

		CloudKitManager.privateDatabase.fetchAllSubscriptions { (subscriptions, error) in
			DispatchQueue.main.async {
				if error == nil {
					if let subscriptions = subscriptions {
						if subscriptions.isEmpty {
							self.setupProductCKQuerySubscription()
						} else {
							print("\(subscriptions.debugDescription) retrieved by CloudKitManager")
						}
						//more code to come!

					}
				} else {
					print(error!.localizedDescription)
				}
			}
		}

	}

	func setupProductCKQuerySubscription() {
		let predicate = NSPredicate(value: true)
		let subscription = CKQuerySubscription(recordType: "Product", predicate: predicate, subscriptionID: "product-changes", options: [CKQuerySubscription.Options.firesOnRecordCreation, CKQuerySubscription.Options.firesOnRecordUpdate, CKQuerySubscription.Options.firesOnRecordDeletion])


		let config = CKModifySubscriptionsOperation.Configuration()
		config.timeoutIntervalForRequest = 20
		config.timeoutIntervalForResource = 20


		let notification = CKSubscription.NotificationInfo()
		notification.alertBody = "There's a new product in Inventory"
		notification.soundName = "default"
		notification.shouldSendContentAvailable = true
		notification.shouldBadge = true

		subscription.notificationInfo = notification
		config.qualityOfService = .userInitiated

		CloudKitManager.privateDatabase.save(subscription) { (subscription, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error.localizedDescription)
				} else {
					print("Product Subscription Saved to Server from CloudKitManager!")
				}
			}
		}
	}

	func unsubscribeToProductUpdates() {
		CloudKitManager.privateDatabase.delete(withSubscriptionID: CloudKitManager.subscriptionID) { (subscription, error) in
			if let error = error {
				print(error)
			} else {
				print(subscription, "saved")
			}
		}
	}



	func handleNotification() {
		// Use the ChangeToken to fetch only whatever changes have occurred since the last
		// time we asked, since intermediate push notifications might have been dropped.
		var changeToken: CKServerChangeToken? = nil
		let changeTokenData = UserDefaults.standard.data(forKey: CloudKitManager.serverChangeTokenKey)
		if changeTokenData != nil {
			changeToken = NSKeyedUnarchiver.unarchiveObject(with: changeTokenData!) as! CKServerChangeToken?
		}
		let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
		options.previousServerChangeToken = changeToken
		let optionsMap: [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration]? = [CKRecordZone.default().zoneID: options]
		let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: [CKRecordZone.default().zoneID], configurationsByRecordZoneID: optionsMap)

		operation.fetchAllChanges = true
		operation.recordChangedBlock = { record in
			print(record, "updated: CKController.swift:handleNotification")
		}
		operation.recordZoneChangeTokensUpdatedBlock = { zoneID, changeToken, data in
			guard let changeToken = changeToken else {
				return
			}

			let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
			UserDefaults.standard.set(changeTokenData, forKey: CloudKitManager.serverChangeTokenKey)
			print("change token set in user defaults")
		}
		operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
			guard error == nil else {
				return
			}
			guard let changeToken = changeToken else {
				return
			}

			let changeTokenData = NSKeyedArchiver.archivedData(withRootObject: changeToken)
			UserDefaults.standard.set(changeTokenData, forKey: CloudKitManager.serverChangeTokenKey)
			print(zoneID, "changed fetch completed: CKManager: handlenotification")
		}
		operation.fetchRecordZoneChangesCompletionBlock = { error in
			guard error == nil else {
				print("Fetch Record Zone Changes completion block finished in CloudKitController:handlenotification method")
				NotificationCenter.default.post(name: NSNotification.Name(rawValue: CloudKitNotifications.ProductChange), object: nil)
				return
			}
		}
		operation.qualityOfService = .utility

		CloudKitManager.privateDatabase.add(operation)
	}


}


extension CloudKitManager {


	func createCKRecord(for dose: Dose, completion: @escaping CreateDoseCompletion) {
		let record = dose.toCKRecord()

		CloudKitManager.privateDatabase.save(record) { (serverRecord, error) in
			guard let serverRecord = serverRecord else {
				DispatchQueue.main.async {
					completion(false, nil, error)
				}
				return
			}
			DispatchQueue.main.async {
				completion(true, Dose.fromCKRecord(record: serverRecord), nil)
			}
		}
	}



	func retrieveAllDoses(completion: @escaping RetrieveDoseCompletion) {
		let predicate = NSPredicate(format: "TRUEPREDICATE")
		let query = CKQuery(recordType: "Dose", predicate: predicate)


		let queryOperation = CKQueryOperation(query: query)
		queryOperation.queryCompletionBlock = { (operationCursor, error) in
			DispatchQueue.main.async {
				if let error = error {

					print(error.localizedDescription)
				} else {
					if let operationCursor = operationCursor {
						completion(nil, true)
						print("query has finished executing, but did not obtain all records. Received operationCursor object as marker to use to receive rest of records")
						CloudKitManager.shared.retrieveRemainingRecords(using: operationCursor)
					} else {
						completion(nil, true)
						print("dose query completed by CKManager")
					}
				}
			}

		}
		queryOperation.recordFetchedBlock = { record in
			DispatchQueue.main.async {
				guard let dose = Dose.fromCKRecord(record: record) else { return }
				print("dose record fetched by query in CKManager")
				completion(dose, false)
			}
		}
		let config = CKQueryOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForRequest = 10
		config.timeoutIntervalForResource = 10
		queryOperation.configuration = config

		CloudKitManager.privateDatabase.add(queryOperation)

	}


	func updateDose(dose: Dose, completion: @escaping UpdateDoseCompletion) {
		let record = dose.toCKRecord()
		let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
		let config = CKModifyRecordsOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForRequest = 10
		config.timeoutIntervalForResource = 10
		operation.configuration = config
		operation.savePolicy = .allKeys
		operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
					completion(false, nil, error)
				} else {
					if dose.recordID != nil {
						completion(true, dose, nil)
						print("Dose Records wwere updated")
					} else {
						completion(true, nil, nil)
						print("okay. Nothing updates")
					}
				}
			}
		}

		CloudKitManager.privateDatabase.add(operation)

	}

	func deleteDoseUsingModifyRecords(dose: Dose, completion: @escaping DeleteDoseCompletion) {
		guard let doseRecordID = dose.recordID else {
			completion(false, nil)
			return
		}

		let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: [doseRecordID])
		let config = CKModifyRecordsOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForRequest = 10
		config.timeoutIntervalForResource = 10

		operation.configuration = config

		operation.modifyRecordsCompletionBlock = { (_, deletedRecordIDs, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					if let deletedRecordIDs = deletedRecordIDs {
						print(deletedRecordIDs, "deleted")
						completion(true, nil)
					}
				}
			}
		}

		CloudKitManager.privateDatabase.add(operation)

	}


	func fetchDoseCKQuerySubscriptions() {

		let _: [CKSubscription.ID] = ["dose-changes"]

		CloudKitManager.privateDatabase.fetchAllSubscriptions { (subscriptions, error) in
			DispatchQueue.main.async {
				if error == nil {
					if let subscriptions = subscriptions {
						if subscriptions.isEmpty {
							self.setupDoseCKQuerySubscription()
						} else {
							print("\(subscriptions.debugDescription) retrieved by CloudKitManager")
						}
						//more code to come!

					}
				} else {
					print(error!.localizedDescription)
				}
			}
		}

	}

	func setupDoseCKQuerySubscription() {
		let predicate = NSPredicate(value: true)
		let subscription = CKQuerySubscription(recordType: "Dose", predicate: predicate, subscriptionID: "dose-changes", options: [CKQuerySubscription.Options.firesOnRecordCreation, CKQuerySubscription.Options.firesOnRecordUpdate, CKQuerySubscription.Options.firesOnRecordDeletion])


		let config = CKModifySubscriptionsOperation.Configuration()
		config.timeoutIntervalForRequest = 20
		config.timeoutIntervalForResource = 20


		let notification = CKSubscription.NotificationInfo()
		notification.alertBody = "There's a new dose in Inventory"
		notification.soundName = "default"
		notification.shouldSendContentAvailable = true
		notification.shouldBadge = false

		subscription.notificationInfo = notification
		config.qualityOfService = .userInitiated

		CloudKitManager.privateDatabase.save(subscription) { (subscription, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error.localizedDescription)
				} else {
					print("Dose Subscription Saved to Server from CloudKitManager!")
				}
			}
		}
	}


	func unsubscribeToDoseUpdates() {
		CloudKitManager.privateDatabase.delete(withSubscriptionID: CloudKitManager.dosesSubscriptionID) { (subscription, error) in
			if let error = error {
				print(error)
			} else {
				print(subscription, "saved unsubscription")
			}
		}
	}

}



