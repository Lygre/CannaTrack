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
typealias RetrieveProductCompletion = (_ products: [Product]?, _ error: Error?) -> Void
typealias UpdateProductCompletion = (_ success: Bool, _ resultingCloudProduct: Product?, _ error: Error?) -> Void
typealias DeleteProductCompletion = (_ success: Bool, _ error: Error?) -> Void



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

		CloudKitManager.privateDatabase.perform(query, inZoneWith: nil) { (records, error) in
			guard let records = records else {
				completion(nil, error)
				return
			}

			if error == nil {
				var products = [Product]()
				products = records.flatMap({ return Product.fromCKRecord(record: $0) })
				completion(products, nil)
			} else {
				completion(nil, error)
			}
		}
	}


}






