//
//  Inventory.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

class Inventory: Codable {

	var productArray: [Product] {
		didSet(newValue) {
		//implement writing user data here
			print("value set; writing to user data")
			CannaTrackSpecial.saveInventoryToCloud(inventory: self)
			writeInventoryToUserData()
		}

	}

	init() {

		self.productArray = loadProductInventoryFromUserData()
	}

	required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		productArray = try values.decode([Product].self, forKey: .productArray)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(productArray, forKey: .productArray)
	}

}

extension Inventory {
	enum CodingKeys: String, CodingKey {
		case productArray
	}
}

extension Inventory: Equatable {

	static func == (lhs: Inventory, rhs: Inventory) -> Bool {
		return lhs.productArray == rhs.productArray
	}

}

extension Inventory {

	func writeInventoryToUserData() {
		let propertyListEncoder = PropertyListEncoder()
		do {
			let inventoryData: [Product] = self.productArray
			let data = try propertyListEncoder.encode(inventoryData)
			UserDefaults.standard.set(data, forKey: "data")
		}
		catch {
			print(error)
		}
	}

	func removeProductFromInventoryMaster(product: Product) {
		guard let indexOfProduct = self.productArray.firstIndex(of: product) else { return }
		self.productArray.remove(at: indexOfProduct)

		let propertyListEncoder = PropertyListEncoder()
		do {
//			let inventory: Inventory = self
			let products: [Product] = self.productArray
			let data = try propertyListEncoder.encode(products)
			UserDefaults.standard.set(data, forKey: "data")
		}
		catch {
			print(error)
		}

	}

	func addProductToInventoryMaster(product: Product) {
		self.productArray.append(product)
		let propertyListEncoder = PropertyListEncoder()
		do {
			let inventoryData: [Product] = self.productArray
			let data = try propertyListEncoder.encode(inventoryData)
			UserDefaults.standard.set(data, forKey: "data")
		}
		catch {
			print(error)
		}
	}

}

extension Inventory {
	func saveInventoryToCloud() {
		let database = CKContainer.default().privateCloudDatabase
		let encoder = PropertyListEncoder()
		do {

			let inventoryData = self.productArray

			let dataEncodedForCloud = try encoder.encode(inventoryData)

			let newInventoryForCloud = CKRecord(recordType: "Inventory", recordID: CKRecord.ID(recordName: "InventoryData"))

			newInventoryForCloud.setValue(dataEncodedForCloud, forKey: "inventoryData")

			database.save(newInventoryForCloud) { (record, error) in
				guard record != nil else { return }
				print("saved inventory to cloud \(record.debugDescription)", error)
			}
		}
		catch {
			print(error)
		}

	}

}
