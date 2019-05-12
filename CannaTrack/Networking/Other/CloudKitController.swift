//
//  CloudKitController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/10/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import CloudKit

typealias RequestCKPermissionCompletion = (_ accountStatus: CKAccountStatus, _ error: Error?) -> Void
typealias CreateProductCompletion = (_ success: Bool, _ resultingCloudProduct: Product?, _ error: Error?) -> Void
typealias RetrieveProductsCompletion = (_ products: [Product]?, _ error: Error?) -> Void
typealias UpdateProductCompletion = (_ success: Bool, _ resultingCloudProduct: Product?, _ error: Error?) -> Void
typealias DeleteProductCompletion = (_ success: Bool, _ error: Error?) -> Void
typealias RetrieveProductCompletion = (_ product: Product?) -> Void


struct CloudKitManager {
	static let shared = CloudKitManager()
	static let privateDatabase = CKContainer.default().privateCloudDatabase
	static let publicDatabase = CKContainer.default().publicCloudDatabase

	static let productsFetchOperation = CKFetchRecordsOperation()

	static let subscriptionID = "product-changes"
	static let subscriptionSavedKey = "ckSubscriptionSaved"

	func requestCloudKitPermission(completion: @escaping RequestCKPermissionCompletion) {
		CKContainer.default().accountStatus(completionHandler: completion)
	}


	func createCKRecord(for product: Product, completion: @escaping CreateProductCompletion) {
		let record = product.toCKRecord()

		CloudKitManager.privateDatabase.save(record) { (serverRecord, error) in
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

	func retrieveAllProducts(completion: @escaping RetrieveProductCompletion) {
		let predicate = NSPredicate(format: "TRUEPREDICATE")
		let query = CKQuery(recordType: "Product", predicate: predicate)


		let queryOperation = CKQueryOperation(query: query)
		queryOperation.queryCompletionBlock = { (operationCursor, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error.localizedDescription)
				} else {
					print("query completed by CKManager")
				}
			}

		}
		queryOperation.recordFetchedBlock = { record in
			DispatchQueue.main.async {
				guard let product = Product.fromCKRecord(record: record) else { return }
				print("record fetched by query in CKManager")
				completion(product)
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


	func deleteProduct(product: Product, completion: @escaping DeleteProductCompletion) {
		guard let productRecordID = product.recordID else {
			completion(false, nil)
			return
		}

		CloudKitManager.privateDatabase.delete(withRecordID: productRecordID) { (id, error) in
			guard let _ = id else {
				completion(false, error)
				return
			}
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					completion(true, nil)
					print("Product Record was deleted by CKManager")
				}
			}

		}
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



	func saveSubscription() {
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
		config.qualityOfService = .utility

		CloudKitManager.privateDatabase.save(subscription) { (subscription, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error.localizedDescription)
				} else {
					print("Subscription Saved to Server from CloudKitManager!")
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

}






