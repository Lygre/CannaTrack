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
//MARK: -- CloudKitManager
struct CloudKitManager {

	//MARK: -- Static Constants
	static let shared = CloudKitManager()
	static let createZoneGroup = DispatchGroup()
	static let container = CKContainer.default()

	static let privateDatabase = CKContainer.default().privateCloudDatabase
	static let publicDatabase = CKContainer.default().publicCloudDatabase
	static let sharedDatabase = CKContainer.default().sharedCloudDatabase

	static let productsFetchOperation = CKFetchRecordsOperation()
	static let doseFetchOperation = CKFetchRecordsOperation()
//	static let subscriptionID = "cloudkit-product-changes"
	static let subscriptionID = "product-changes"
	//pretend this doesn't exist for now
	static let dosesSubscriptionID = "dose-changes"


	static let doseSubscriptionSavedKey = "doseCkSubscriptionSaved"
	static let serverChangeTokenKeyForDoses = "doseCkServerChangeToken"

	static let subscriptionSavedKey = "ckSubscriptionSaved"
	static let serverChangeTokenKey = "ckServerChangeToken"

	static let productZoneID = CKRecordZone.ID(zoneName: "Inventory", ownerName: CKCurrentUserDefaultName)
	//only working with productZoneID for now
	static let doseZoneID = CKRecordZone.ID(zoneName: "DoseLogs", ownerName: CKCurrentUserDefaultName)

	static let sharedZoneID = CKRecordZone.ID(zoneName: "SharedZone", ownerName: CKCurrentUserDefaultName)


	//MARK: -- Variables

	var cloudKitObserver: NSObjectProtocol?

	static var createdCustomProductsZone: Bool {
		get {
			guard let bool = UserDefaults.standard.value(forKey: CloudKitManager.productZoneID.zoneName) as? Bool else {
				return false
			}
			return bool
		}
		set(newValue) {
			UserDefaults.standard.setValue(newValue, forKey: CloudKitManager.productZoneID.zoneName)
		}
	}

	static var createdCustomDoseLogZone: Bool {
		get {
			guard let bool = UserDefaults.standard.value(forKey: CloudKitManager.doseZoneID.zoneName) as? Bool else {
				return false
			}
			return bool
		}
		set(newValue) {
			UserDefaults.standard.setValue(newValue, forKey: CloudKitManager.doseZoneID.zoneName)
		}
	}

	static var createdCustomSharedZone: Bool {
		get {
			guard let bool = UserDefaults.standard.value(forKey: CloudKitManager.sharedZoneID.zoneName) as? Bool else {
				return false
			}
			return bool
		}
		set(newValue) {
			UserDefaults.standard.setValue(newValue, forKey: CloudKitManager.sharedZoneID.zoneName)
		}
	}


	static var subscribedToProductChanges: Bool {
		get {
			guard let bool = UserDefaults.standard.value(forKey: CloudKitManager.subscriptionSavedKey) as? Bool else {
				return false
			}
			return bool
		}
		set(newValue) {
			UserDefaults.standard.setValue(newValue, forKey: CloudKitManager.subscriptionSavedKey)
		}
	}

	static var subscribedToDoseChanges: Bool {
		get {
			guard let bool = UserDefaults.standard.value(forKey: CloudKitManager.doseSubscriptionSavedKey) as? Bool else {
				return false
			}
			return bool
		}
		set(newValue) {
			UserDefaults.standard.setValue(newValue, forKey: CloudKitManager.doseSubscriptionSavedKey)
		}
	}

	//MARK: -- Right way variables


	static var privateDatabaseTokenKey = "private"
	static var publicDatabaseTokenKey = "public"


	static var privateDatabaseChangeToken: CKServerChangeToken? {
		get {
			guard let storedTokenData = UserDefaults.standard.data(forKey: CloudKitManager.privateDatabaseTokenKey) else { return nil }
			guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: storedTokenData) else { return nil }
			decoder.requiresSecureCoding = true
			guard let serverChangeTokenFromDecoder = CKServerChangeToken(coder: decoder) else { return nil }
			return serverChangeTokenFromDecoder
		}
		set(updatedServerChangeToken) {
			let coder = NSKeyedArchiver.init(requiringSecureCoding: true)
			updatedServerChangeToken?.encode(with: coder)
//			guard let newTokenData = try? NSKeyedArchiver.archivedData(withRootObject: CKServerChangeToken.self, requiringSecureCoding: true) else { return }
			coder.finishEncoding()

			UserDefaults.standard.set(coder.encodedData, forKey: CloudKitManager.privateDatabaseTokenKey)

			print("server change token saved and written to user defaults", updatedServerChangeToken)
		}
	}

	static var doseZoneChangeToken: CKServerChangeToken? {
		get {
			guard let storedDoseZoneTokenData = UserDefaults.standard.data(forKey: CloudKitManager.serverChangeTokenKeyForDoses) else { return nil }
			guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: storedDoseZoneTokenData) else { return nil }
			decoder.requiresSecureCoding = true
			guard let serverChangeTokenForDoseLogZoneFromDecoder = CKServerChangeToken(coder: decoder) else { return nil }
			print("change token for dose log zone read from user defaults", serverChangeTokenForDoseLogZoneFromDecoder)
			return serverChangeTokenForDoseLogZoneFromDecoder
		}
		set(updatedDoseZoneChangeToken) {
			let coder = NSKeyedArchiver.init(requiringSecureCoding: true)
			updatedDoseZoneChangeToken?.encode(with: coder)
			coder.finishEncoding()

			UserDefaults.standard.set(coder.encodedData, forKey: CloudKitManager.serverChangeTokenKeyForDoses)
			print("change token for dose log zone updated in user defaults", updatedDoseZoneChangeToken)
		}
	}
	/*
	static var inventoryZoneChangeToken: CKServerChangeToken? {
		get {
			guard let inventoryZoneTokenData = UserDefaults.standard.data(forKey: CloudKitManager.) else { return nil }
			guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: inventoryZoneTokenData) else { return nil }
			decoder.requiresSecureCoding = true
			guard let serverChangeTokenForDoseLogZoneFromDecoder = CKServerChangeToken(coder: decoder) else { return nil }
			print("change token for dose log zone read from user defaults")
			return serverChangeTokenForDoseLogZoneFromDecoder
		}
		set(updatedDoseZoneChangeToken) {
			let coder = NSKeyedArchiver.init(requiringSecureCoding: true)
			updatedDoseZoneChangeToken?.encode(with: coder)
			coder.finishEncoding()
			UserDefaults.standard.set(object: coder.encodedData, forKey: CloudKitManager.serverChangeTokenKeyForDoses)
			print("change token for dose log zone updated in user defaults")
		}
	}
	*/

	//MARK: -- Constants


	//MARK: -- Authentication
	func requestCloudKitPermission(completion: @escaping RequestCKPermissionCompletion) {
		CKContainer.default().accountStatus(completionHandler: completion)
		CKContainer.default().requestApplicationPermission(CKContainer_Application_Permissions.userDiscoverability) { (status, error) in
			switch status {
			case .granted:
				print("granted")
			case .denied:
				print("denied")
			case .initialState:
				print("initial state")
			case .couldNotComplete:
				print("an error occurred", error ?? "Unknown Error")
			}
		}
	}

	//MARK: -- Creation of Custom Zone 1 for Products
	func createCustomProductsZone() {
		if !CloudKitManager.createdCustomProductsZone {
			CloudKitManager.createZoneGroup.enter()

			let customZone = CKRecordZone(zoneID: CloudKitManager.productZoneID)

			let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [])

			createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
				if let error = error {
					let alertView = UIAlertController(title: "Custom Product Zone Creation Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
					}
				} else {
					if let _ = saved {
						CloudKitManager.createdCustomProductsZone = true
						print("Custom Zone for Products was saved to Server")
					}
				}
				CloudKitManager.createZoneGroup.leave()
			}

			createZoneOperation.qualityOfService = .userInitiated

			CloudKitManager.privateDatabase.add(createZoneOperation)
		}
	}

	//MARK: -- Creating Custom Zone 2 for Doses
	func createCustomDoseLogZone() {
		if !CloudKitManager.createdCustomDoseLogZone {
			CloudKitManager.createZoneGroup.enter()

			let customZone = CKRecordZone(zoneID: CloudKitManager.doseZoneID)

			let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [])

			createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
				if let error = error {
					let alertView = UIAlertController(title: "Custom Dose Zone Creation Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
					}
				} else {
					if let _ = saved {
						CloudKitManager.createdCustomDoseLogZone = true
						print("Custom Zone for Doses was saved to Server")
					}
				}
				CloudKitManager.createZoneGroup.leave()
			}

			createZoneOperation.qualityOfService = .userInitiated

			CloudKitManager.privateDatabase.add(createZoneOperation)
		}
	}

	//MARK: -- Subscribing to Zone Change Notifications; CKDatabaseSubscription object
	func subscribeToProductZoneChanges() {
		if !CloudKitManager.subscribedToProductChanges {

			let createSubscriptionOperation = CloudKitManager.shared.createDatabaseSubscriptionOperation(subscriptionId: CloudKitManager.subscriptionID)

			createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIDs, error) in
				if let error = error {
					let alertView = UIAlertController(title: "Product Creation Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						print(error)
						UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
					}
				} else {
					CloudKitManager.subscribedToProductChanges = true
				}
			}

			CloudKitManager.privateDatabase.add(createSubscriptionOperation)

		}

		CloudKitManager.createZoneGroup.notify(queue: DispatchQueue.global()) {
			if CloudKitManager.createdCustomProductsZone {
				CloudKitManager.shared.fetchChanges(in: CloudKitManager.privateDatabase.databaseScope) {  }
			}
		}

	}

	//MARK: -- Subscribing to Zone Change Notifications; CKDatabaseSubscription object
	func subscribeToDoseLogZoneChanges() {
		if !CloudKitManager.subscribedToDoseChanges {

			let createSubscriptionOperation = CloudKitManager.shared.createDatabaseSubscriptionOperation(subscriptionId: CloudKitManager.dosesSubscriptionID)

			createSubscriptionOperation.modifySubscriptionsCompletionBlock = { (subscriptions, deletedIDs, error) in
				if let error = error {
					let alertView = UIAlertController(title: "ModifyDoseLog Sub Fail", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						print(error)
						UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
					}
				} else {
					CloudKitManager.subscribedToDoseChanges = true
				}
			}

			CloudKitManager.privateDatabase.add(createSubscriptionOperation)

		}

		CloudKitManager.createZoneGroup.notify(queue: DispatchQueue.global()) {
			if CloudKitManager.createdCustomDoseLogZone {
				CloudKitManager.shared.fetchChanges(in: CloudKitManager.privateDatabase.databaseScope) {  }
			}
		}
	}

	//MARK: -- Method to create the Database Subscription from Sub ID
	func createDatabaseSubscriptionOperation(subscriptionId: String) -> CKModifySubscriptionsOperation {
		let subscription = CKDatabaseSubscription.init(subscriptionID: subscriptionId)
		//silent notification
		let notificationInfo = CKSubscription.NotificationInfo()
		notificationInfo.shouldSendContentAvailable = true
		subscription.notificationInfo = notificationInfo

		let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: [])
		operation.qualityOfService = .utility

		return operation

	}

	func fetchProductDatabaseChanges(_ previousChangeToken: CKServerChangeToken?, completion: @escaping ()->Void) {
		//client is responsible for saving the change token at the end of the operation and passing it into the next call to CKFetchDatabaseChangesOperation

		let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: previousChangeToken)

		operation.fetchAllChanges = true
		operation.resultsLimit = 20
		operation.fetchDatabaseChangesCompletionBlock = { (changeToken, moreComing, error) in
			DispatchQueue.main.async {
				if let error = error {
					let alertView = UIAlertController(title: "Fetch Database Changes Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
					}
					print(error)
				}
				if let changeToken = changeToken {
					CloudKitManager.privateDatabaseChangeToken = changeToken
					print("database changes fetched", changeToken)

				}

				if moreComing {
					print("more records coming, creating a new fetch with last change token")
					completion()
					self.fetchProductDatabaseChanges(CloudKitManager.privateDatabaseChangeToken, completion: completion)
				} else {
					print("no more records coming from inventoryVC fetchProductDatabaseChanges method")
					completion()
					//					self.updateInventoryCollectionView()
				}

			}
		}



		operation.changeTokenUpdatedBlock = { changeToken in
			DispatchQueue.main.async {
				print("database change token value updated through changeToken completionblock; new: \(changeToken.debugDescription)")
				CloudKitManager.privateDatabaseChangeToken = changeToken
			}
		}

		operation.recordZoneWithIDChangedBlock = { zoneID in
			DispatchQueue.main.async {
				//mabye should append these IDs into an array? meh
				print("\(zoneID.debugDescription) ID of zone was changed")
			}
		}

		let config = CKFetchDatabaseChangesOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForRequest = 12
		config.timeoutIntervalForResource = 12
		operation.configuration = config

		CloudKitManager.privateDatabase.add(operation)

	}

	//MARK: -- Fetch Changes

	func fetchChanges(in databaseScope: CKDatabase.Scope, completion: @escaping () -> Void) {
		switch databaseScope {
		case .private:
			print("implemented this")
			fetchDatabaseChanges(database: CloudKitManager.privateDatabase, databaseTokenKey: CloudKitManager.privateDatabaseTokenKey, completion: completion)
		case .public:
			print("not implemented to fetch changes from public database")
		case .shared:
			print("not implemented to fetch changes from shared database")
		}
	}

	//MARK: -- Fetch Database Changes CKFetchDatabaseChangesOperation

	func fetchDatabaseChanges(database: CKDatabase, databaseTokenKey: String, completion: @escaping () -> Void) {
		var changedZoneIDs: [CKRecordZone.ID] = []

		var changeToken: CKServerChangeToken? = CloudKitManager.privateDatabaseChangeToken

		// Read change token from disk
		let operation = CKFetchDatabaseChangesOperation(previousServerChangeToken: changeToken)

		operation.recordZoneWithIDChangedBlock = { (zoneID) in
			changedZoneIDs.append(zoneID)
		}

		operation.recordZoneWithIDWasDeletedBlock = { (zoneID) in
			// Write this zone deletion to memory
		}

		operation.changeTokenUpdatedBlock = { (token) in
			CloudKitManager.privateDatabaseChangeToken = token
			// Flush zone deletions for this database to disk
			// Write this new database change token to memory
		}

		operation.fetchDatabaseChangesCompletionBlock = { (token, moreComing, error) in
			if let error = error {
				print("Error during fetch shared database changes operation", error)
				completion()
				return
			}
			// Flush zone deletions for this database to disk
			// Write this new database change token to memory
			CloudKitManager.privateDatabaseChangeToken = token
			if !changedZoneIDs.isEmpty {
				self.fetchZoneChanges(database: database, databaseTokenKey: databaseTokenKey, zoneIDs: changedZoneIDs) {
					// Flush in-memory database change token to disk
					completion()
				}
			} else { print("no changed zone IDs to process") }
		}
		operation.qualityOfService = .userInitiated

		CloudKitManager.privateDatabase.add(operation)
	}



	//MARK: -- Fetch Zone Changes

	func fetchZoneChanges(database: CKDatabase, databaseTokenKey: String, zoneIDs: [CKRecordZone.ID], completion: @escaping () -> Void) {

		// Look up the previous change token for each zone
		var needsUpdatingZoneIDs: [CKRecordZone.ID] = []
		var optionsByRecordZoneID = [CKRecordZone.ID: CKFetchRecordZoneChangesOperation.ZoneConfiguration]()
		for zoneID in zoneIDs {
			let options = CKFetchRecordZoneChangesOperation.ZoneConfiguration()
			//			options.previousServerChangeToken =
			options.previousServerChangeToken = CloudKitManager.privateDatabaseChangeToken
			// Read change token from disk
			optionsByRecordZoneID[zoneID] = options
			print(options.debugDescription)
		}
		let operation = CKFetchRecordZoneChangesOperation(recordZoneIDs: zoneIDs, configurationsByRecordZoneID: optionsByRecordZoneID)

		struct ChangedRecord {
			var changedRecords: [CKRecord] = []
			var deleteRecordIDs: [CKRecord.ID] = []
		}

		var recordChanges = ChangedRecord()

		operation.recordChangedBlock = { (record) in
			print("Record changed:", record)
			recordChanges.changedRecords.append(record)
			if !needsUpdatingZoneIDs.contains(record.recordID.zoneID) {
				needsUpdatingZoneIDs.append(record.recordID.zoneID)
			}
			// Write this record change to memory
		}

		operation.recordWithIDWasDeletedBlock = { (recordId, recordType) in
			print("Record deleted:", recordId, recordType)
			if recordType == "Dose" {
				recordChanges.deleteRecordIDs.append(recordId)
				if !needsUpdatingZoneIDs.contains(recordId.zoneID) {
					needsUpdatingZoneIDs.append(recordId.zoneID)
				}
//				DoseController.shared.delete(dose: <#T##Dose#>)
			}
			// Write this record deletion to memory
		}

		operation.recordZoneChangeTokensUpdatedBlock = { (zoneId, token, data) in
			// Flush record changes and deletions for this zone to disk
			// Write this new zone change token to disk

			if let changeToken = token {
				if let data = data {
					guard let decoder = try? NSKeyedUnarchiver.init(forReadingFrom: data) else { return }
					if changeToken != CKServerChangeToken(coder: decoder) {
						print("new change token is not the same as last from device")
						CloudKitManager.privateDatabaseChangeToken = changeToken
						CloudKitManager.shared.fetchChanges(in: CloudKitManager.privateDatabase.databaseScope, completion: {
							print("fetching changes after receiving record zone change tokens updated block")
						})
					} else {
						print("new change token is the same as last from device")
					}
				}
//				CloudKitManager.privateDatabaseChangeToken = changeToken
				print("set new change token in record zone change tokens updated block")
			} else {
				print("no change token in record zone change tokens updated block")
			}
//			if zoneId == CloudKitManager.doseZoneID {
//				CloudKitManager.doseZoneChangeToken = token
//				print("dose zone change token has been updated")
//			} else { print("the updated zone token was not the dose zone; doing nothing") }

			//MARK: -- need to make a new constant to track the individual zone changes and a token for them
//			CloudKitManager.privateDatabase
			needsUpdatingZoneIDs.append(zoneId)
			print("Record zone with id \(zoneId) and token \(token)")
		}

		operation.recordZoneFetchCompletionBlock = { (zoneId, changeToken, data, _, error) in
			if let error = error {
				let alertView = UIAlertController(title: "Record Zone Fetch Completion", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
				DispatchQueue.main.async {
					UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
				}

				print("Error fetching zone changes for \(databaseTokenKey) database:", error)
				return
			} else {
				if let changeToken = changeToken {
//					CloudKitManager.privateDatabaseChangeToken = changeToken
					if let data = data {
						guard let decoder = try? NSKeyedUnarchiver.init(forReadingFrom: data) else { return }
						if changeToken != CKServerChangeToken(coder: decoder) {
							print("new change token is not the same as last from device")
							CloudKitManager.privateDatabaseChangeToken = changeToken
							CloudKitManager.shared.fetchChanges(in: CloudKitManager.privateDatabase.databaseScope, completion: {
								print("fetching changes after receiving record zone change tokens updated block")
							})
						} else {
							print("new change token is the same as last from device")
						}
					}
					print("updating server change token")
				} else {
					//				if zoneId == CloudKitManager.doseZoneID {
					//					CloudKitManager.doseZoneChangeToken = changeToken
					//				}
					print("record zone fetch completed", needsUpdatingZoneIDs, "need updating")
				}

			}

			// Flush record changes and deletions for this zone to disk
			// Write this new zone change token to disk
		}

		operation.fetchRecordZoneChangesCompletionBlock = { (error) in
			if let error = error {
				print("Error fetching zone changes for \(databaseTokenKey) database:", error)
			}
			if !recordChanges.changedRecords.isEmpty {
				print("changed records array is not empty. not doing anything with the changed records yet")
			}
			if !recordChanges.deleteRecordIDs.isEmpty {
				print("deleted record IDs array was not empty. processing deletions.")
				for recordID in recordChanges.deleteRecordIDs {
					guard let doseToDelete = DoseController.doses.filter({ (someLocalDose) -> Bool in
						if let localDoseRecordID = someLocalDose.recordID {
							return localDoseRecordID == recordID
						} else { return false }
					}).first else { return }

					DoseController.shared.delete(dose: doseToDelete)
					print("processed server dose record deletions locally")
				}
			}
			print("fetch record zone changes completion block executed")
			completion()
		}

		CloudKitManager.privateDatabase.add(operation)
	}

}


//MARK: -- Handling Database changes the correct way
extension CloudKitManager {




}




extension CloudKitManager {

	//MARK: -- Create Product Record
	func createCKRecord(for product: Product, completion: @escaping CreateProductCompletion) {
		createCustomProductsZone()
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

	//MARK: -- Finish incomplete Query operation
	func retrieveRemainingRecords(using operationCursor: CKQueryOperation.Cursor) {
		let queryOperation = CKQueryOperation(cursor: operationCursor)
		print("initialized new query using operation cursor")
		CloudKitManager.privateDatabase.add(queryOperation)

	}

	//MARK: -- Query Operation for Products
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

	//MARK: -- Update and Delete Product with CKModifyRecordsOperation
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




	//MARK: -- fetch operation for products CKFetchRecordsOperation
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

	//MARK: -- Saving Product-Changes subscription

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


	//MARK: -- Fetch Product Subscription
	//This is actually fetching all though. Causing duplication

	func fetchProductCKQuerySubscriptions() {

		let _: [CKSubscription.ID] = ["product-changes"]

		CloudKitManager.privateDatabase.fetchAllSubscriptions { (subscriptions, error) in
			DispatchQueue.main.async {
				if error == nil {
					if let subscriptions = subscriptions {
						if subscriptions.isEmpty {
							self.setupProductCKQuerySubscription()
//							self.setupDoseCKQuerySubscription()
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

	//MARK: -- Setup Product CKModifySubscriptionsOperation
	func setupProductCKQuerySubscription() {
		let predicate = NSPredicate(value: true)
		let subscription = CKQuerySubscription(recordType: "Product", predicate: predicate, subscriptionID: CloudKitManager.subscriptionID, options: [CKQuerySubscription.Options.firesOnRecordCreation, CKQuerySubscription.Options.firesOnRecordUpdate, CKQuerySubscription.Options.firesOnRecordDeletion])


		let config = CKModifySubscriptionsOperation.Configuration()
		config.timeoutIntervalForRequest = 20
		config.timeoutIntervalForResource = 20


		let notification = CKSubscription.NotificationInfo()
		notification.alertBody = "There's a new product in Inventory"
		//		notification.soundName = "default"
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

	//MARK: -- Unsubscribe to Product Updates subscription
	func unsubscribeToProductUpdates() {
		CloudKitManager.privateDatabase.delete(withSubscriptionID: CloudKitManager.subscriptionID) { (subscription, error) in
			if let error = error {
				print(error)
			} else {
				print(subscription, "saved")
			}
		}
	}


	//MARK: -- Handle push notification - CKFetchRecordZoneChangesOperation

	func handleNotificationForInventory() {
		// Use the ChangeToken to fetch only whatever changes have occurred since the last
		// time we asked, since intermediate push notifications might have been dropped.
		var changeToken: CKServerChangeToken? = nil
		let changeTokenData = UserDefaults.standard.data(forKey: CloudKitManager.serverChangeTokenKey)
		if changeTokenData != nil {
			guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: changeTokenData!) else { return }
			changeToken = CKServerChangeToken(coder: decoder)
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

//			let coder = NSKeyedArchiver(requiringSecureCoding: true)
//			changeToken.encode(with: coder)
//			coder.finishEncoding()
//
//			UserDefaults.standard.set(coder.encodedData, forKey: CloudKitManager.serverChangeTokenKey)
//			print("change token set in user defaults")
		}
		operation.recordZoneFetchCompletionBlock = { zoneID, changeToken, data, more, error in
			guard error == nil else {
				return
			}
			guard let changeToken = changeToken else {
				return
			}

			let coder = NSKeyedArchiver(requiringSecureCoding: true)
			changeToken.encode(with: coder)
			coder.finishEncoding()

			UserDefaults.standard.set(coder.encodedData, forKey: CloudKitManager.serverChangeTokenKey)
			print("change token set in user defaults")
			print(zoneID, "changed fetch completed: CKManager: handlenotification")
		}
		operation.fetchRecordZoneChangesCompletionBlock = { error in
			guard error == nil else {
				print("Fetch Record Zone Changes completion block finished in CloudKitController:handlenotification method")
				//				NotificationCenter.default.post(name: NSNotification.Name(rawValue: CloudKitNotifications.ProductChange), object: nil)
				return
			}
		}
		operation.qualityOfService = .userInitiated

		CloudKitManager.privateDatabase.add(operation)
	}


	func handleNotification() {
		// Use the ChangeToken to fetch only whatever changes have occurred since the last
		// time we asked, since intermediate push notifications might have been dropped.
		var changeToken: CKServerChangeToken? = nil
		let changeTokenData = UserDefaults.standard.data(forKey: CloudKitManager.serverChangeTokenKey)
		if changeTokenData != nil {
			guard let decoder = try? NSKeyedUnarchiver(forReadingFrom: changeTokenData!) else { return }
			changeToken = CKServerChangeToken(coder: decoder)
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
				//				NotificationCenter.default.post(name: NSNotification.Name(rawValue: CloudKitNotifications.ProductChange), object: nil)
				return
			}
		}
		operation.qualityOfService = .userInitiated

		CloudKitManager.privateDatabase.add(operation)
	}

}


/*

// obtain the metadata from the CKRecord
let data = NSMutableData()
let coder = NSKeyedArchiver.init(forWritingWith: data)
coder.requiresSecureCoding = true
record.encodeSystemFields(with: coder)
coder.finishEncoding()

// store this metadata on your local object
yourLocalObject.encodedSystemFields = data



// set up the CKRecord with its metadata
let coder = NSKeyedUnarchiver(forReadingWith: yourLocalObject.encodedSystemFields!)
coder.requiresSecureCoding = true
let record = CKRecord(coder: coder)
coder.finishDecoding()
// write your custom fields...



*/









extension CloudKitManager {


	func createCKRecord(for dose: Dose, completion: @escaping CreateDoseCompletion) {
		let record = dose.toCKRecord()

		CloudKitManager.privateDatabase.save(record) { (serverRecord, error) in
			if let error = error {
				let alertView = UIAlertController(title: "Dose Creation Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
				DispatchQueue.main.async {
					UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
				}

			}

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
		config.timeoutIntervalForRequest = 15
		config.timeoutIntervalForResource = 15
		queryOperation.configuration = config

		CloudKitManager.privateDatabase.add(queryOperation)

	}


	func updateDose(dose: Dose, completion: @escaping UpdateDoseCompletion) {
		let record = dose.toCKRecord()
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
		config.timeoutIntervalForRequest = 15
		config.timeoutIntervalForResource = 15

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
		let subscription = CKQuerySubscription(recordType: "Dose", predicate: predicate, subscriptionID: CloudKitManager.dosesSubscriptionID, options: [CKQuerySubscription.Options.firesOnRecordCreation, CKQuerySubscription.Options.firesOnRecordUpdate, CKQuerySubscription.Options.firesOnRecordDeletion])



		let notification = CKSubscription.NotificationInfo()
		notification.alertBody = "There's a new dose in Inventory"
		//		notification.soundName = "default"
		notification.shouldSendContentAvailable = true
		notification.shouldBadge = false

		subscription.notificationInfo = notification

		let operation = CKModifySubscriptionsOperation(subscriptionsToSave: [subscription], subscriptionIDsToDelete: nil)
		let config = CKModifySubscriptionsOperation.Configuration()
		config.timeoutIntervalForRequest = 20
		config.timeoutIntervalForResource = 20
		config.qualityOfService = .userInitiated

		operation.configuration = config

		/*
		CloudKitManager.privateDatabase.save(subscription) { (subscription, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error.localizedDescription)
				} else {
					CloudKitManager.subscribedToDoseChanges = true
					print("Dose Subscription Saved to Server from CloudKitManager!")
				}
			}
		}
		*/
		operation.modifySubscriptionsCompletionBlock = { (savedSubscriptions, deletedSubscriptionIDs, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error.localizedDescription)
					let alertView = UIAlertController(title: "Modify Dose Sub Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
					}

				} else {
					CloudKitManager.subscribedToDoseChanges = true
					print("Dose Subscription Saved to Server from CloudKitManager!")
				}
			}

		}


		CloudKitManager.privateDatabase.add(operation)
	}


	func unsubscribeToDoseUpdates() {
		CloudKitManager.privateDatabase.delete(withSubscriptionID: CloudKitManager.dosesSubscriptionID) { (subscription, error) in
			if let error = error {
				print(error)
			} else {
				CloudKitManager.subscribedToDoseChanges = false
				print(subscription, "saved unsubscription")
			}
		}
	}




	func setupFetchOperationForDoses(with recordIDs: [CKRecord.ID], completion: @escaping RetrieveDosesCompletion) {
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
					let alertView = UIAlertController(title: "Fetch Record Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
					}

					print(error)
				} else if let record = record, let id = recordID {
					print("Record \(record) fetch completed with ID \(id)")



				}
			}
		}

		operation.fetchRecordsCompletionBlock = { (recordsByID, error) in
			DispatchQueue.main.async {
				if let error = error {
					let alertView = UIAlertController(title: "Fetch Record Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
					}
					print(error)
				} else {
					guard let recordsByID = recordsByID else { return }
//					var doses: [Dose] = []
					for (recordID, record) in recordsByID {
						guard let dose = Dose.fromCKRecord(record: record) else { return }
						if !DoseController.doses.contains(dose) {
							DoseController.shared.log(dose: dose)
							print("logged dose from CKRecord in fetch records completion block")
						} else { print("doses contained dose from CK Record already") }
					}


//					DoseController.doses = doses
					completion(DoseController.doses,nil)
					print("Records fetch completed")
				}

			}
		}

		let config = CKFetchRecordsOperation.Configuration()
		config.qualityOfService = .userInitiated
		config.timeoutIntervalForResource = 15
		config.timeoutIntervalForRequest = 15
		operation.configuration = config

		CloudKitManager.privateDatabase.add(operation)

	}


}


//MARK: -- CKShare
extension CloudKitManager {


	func createSharedZone(completionHandler:@escaping (CKRecordZone?, Error?)->Void) {
		if !CloudKitManager.createdCustomSharedZone {
			CloudKitManager.createZoneGroup.enter()

			let customZone = CKRecordZone(zoneID: CloudKitManager.sharedZoneID)

			let createZoneOperation = CKModifyRecordZonesOperation(recordZonesToSave: [customZone], recordZoneIDsToDelete: [])

			createZoneOperation.modifyRecordZonesCompletionBlock = { (saved, deleted, error) in
				if let error = error {
					let alertView = UIAlertController(title: "Custom Shared Zone Creation Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						UIApplication.shared.windows[0].rootViewController?.present(alertView, animated: true, completion:nil)
					}
				} else {
					if let _ = saved {
						CloudKitManager.createdCustomSharedZone = true
						print("Custom Zone for Shared Records was saved to Server")
					}
				}
				CloudKitManager.createZoneGroup.leave()
			}

			createZoneOperation.qualityOfService = .userInitiated

			CloudKitManager.privateDatabase.add(createZoneOperation)
		}
	}


	func shareProductRecord(product: Product, completion: @escaping (CKShare?, CKContainer?, Error?)->Void) {
		let record = product.toCKRecord()
		let share = CKShare(rootRecord: record)
//		share[CKShare.SystemFieldKey.title] = "\(product.strain.name + product.productType.rawValue) Shared" as CKRecordValue
		share.publicPermission = .readOnly

		let modifyRecordsOperation = CKModifyRecordsOperation(recordsToSave: [record, share], recordIDsToDelete: nil)
		let config = CKModifyRecordsOperation.Configuration()
		config.timeoutIntervalForRequest = 15
		config.timeoutIntervalForResource = 15
		config.qualityOfService = .userInitiated
		modifyRecordsOperation.savePolicy = .allKeys

		modifyRecordsOperation.perRecordCompletionBlock = { record, error in
			if let error = error {
				print(error.localizedDescription)
			}

		}

		modifyRecordsOperation.modifyRecordsCompletionBlock = { records, recordIDs, error in
			DispatchQueue.main.async {
				if let error = error {
					completion(nil, nil, error)
					let alertView = UIAlertController(title: "Product Share Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						UIApplication.shared.windows[0].rootViewController?.presentedViewController?.present(alertView, animated: true, completion:nil)
					}

				} else {
					completion(share, CloudKitManager.container, nil)
					guard let savedRecords = records else { return }
					print(savedRecords)
				}
			}

		}

		CloudKitManager.privateDatabase.add(modifyRecordsOperation)
	}


	func createPublicSharedRecord() {

	}

}


