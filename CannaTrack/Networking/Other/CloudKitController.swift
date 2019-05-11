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


struct CKProduct {
	let productData: CKRecordValue?
	let productImageData: CKAsset

	func toCKRecord(product: Product) -> CKRecord? {
		var record = CKRecord(recordType: "Product")
		let encoder = PropertyListEncoder()
		guard let productData = product.encodeProductAsCKRecordValue() else { return nil }

		
		return record

	}

}

struct CloudKitManager {
	static let shared = CloudKitManager()
	static let privateDatabase = CKContainer.default().privateCloudDatabase
	static let publicDatabase = CKContainer.default().publicCloudDatabase

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


}






