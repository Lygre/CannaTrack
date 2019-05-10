//
//  Extensions.swift
//  CannaTracker
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

let testProduct1 = Product(typeOfProduct: .truShatter, strainForProduct: Strain(id: 1, name: "dick", race: .hybrid, description: "no"), inGrams: 0.5)
let testProduct2 = Product(typeOfProduct: .truCrmbl, strainForProduct: Strain(id: 2, name: "not dick", race: .indica, description: "yes"), inGrams: 0.8)


let masterInventory = Inventory()

var globalMasterInventory: [Product] {
	get {
		return masterInventory.productArray
	}
	set(newValue) {
		//not this. this works
		masterInventory.productArray = newValue
//		saveCurrentProductInventoryToUserData()
	}
}


func saveInventoryToCloud(inventory: Inventory) {
	let database = CKContainer.default().privateCloudDatabase

	let encoder = PropertyListEncoder()
	do {

		let inventoryData = inventory.productArray

		let dataEncodedForCloud = try encoder.encode(inventoryData)

		let newInventoryForCloud = CKRecord(recordType: "Inventory", recordID: CKRecord.ID(recordName: "InventoryData"))
		newInventoryForCloud.setValue(dataEncodedForCloud, forKey: "inventoryData")

		database.save(newInventoryForCloud) { (record, error) in
			guard record != nil else { return }
			print("saved inventory to cloud \(record.debugDescription)")
		}
	}
	catch {
		print(error)
	}

}

//func saveProductToCloud(product: Product) {
//
//	let newProduct = CKRecord(recordType: "Product")
//	let properyListEncoder = PropertyListEncoder()
//	do {
//		_ = try properyListEncoder.encode(product)
//		// stupids
//	}
//	catch { print(error) }
//
//	newProduct.setValue(product.dateOpened, forKey: "productTestDate")
//
//
//	privateDatabase.save(newProduct) { (record, _) in
//		guard record != nil else { return }
//		print("saved record with product \(String(describing: record?.object(forKey: "productTestDate")))")
//	}
//}


func queryCloudDatabase() {
	let database = CKContainer.default().privateCloudDatabase

	let query = CKQuery(recordType: "Inventory", predicate: NSPredicate(value: true))
	database.perform(query, inZoneWith: nil) { (recordsCompletion, _) in
		guard let records = recordsCompletion else { return }

		guard let latestRecord = records.sorted(by: { (record, otherRecord) -> Bool in
			let recordOneDate: Date = {
				let dateToReturn: Date = Date()
				if let recOneModDate = record.modificationDate {
					return recOneModDate
				} else {
					if let createDate = record.creationDate {
						return createDate
					}
				}
				return dateToReturn
			}()
			let recordTwoDate: Date = {
				let dateToReturn: Date = Date()
				if let recTwoModDate = otherRecord.modificationDate {
					return recTwoModDate
				} else {
					if let createDate = otherRecord.creationDate {
						return createDate
					} else { print ("problem in cloud query filter") }
				}
				return dateToReturn
			}()
			return recordOneDate > recordTwoDate
		}).first else { return }

		let properyListDecoder = PropertyListDecoder()

		do {

			if let latestRecordToRestore = latestRecord.value(forKey: "inventoryData") as? Data {

				let retrievedInventory = try properyListDecoder.decode([Product].self, from: latestRecordToRestore)
//
				DispatchQueue.main.async {
					masterInventory.productArray = retrievedInventory
				}
			}
		}
		catch {
			print(error)
		}


	}
}

func fetchInventoryFromCloud() {
	let database = CKContainer.default().privateCloudDatabase

	let fetchOperation = CKFetchRecordsOperation(recordIDs: [CKRecord.ID(recordName: "InventoryData")])
	fetchOperation.desiredKeys = [CKRecord.FieldKey(stringLiteral: "inventoryData")]

	fetchOperation.perRecordCompletionBlock = {(record, _, error) in
		guard let recordToEncode = record else { return }
		let properyListDecoder = PropertyListDecoder()

		do {

			if let latestRecordToRestore = recordToEncode.value(forKey: "inventoryData") as? Data {

				let retrievedInventory = try properyListDecoder.decode([Product].self, from: latestRecordToRestore)
				print(recordToEncode, retrievedInventory)
				masterInventory.productArray = retrievedInventory
			}
		}
		catch {
			print(error)
		}
	}
	database.add(fetchOperation)

//	fetchOperation.

	database.fetch(withRecordID: CKRecord.ID(recordName: "InventoryData")) { (record, error) in
		guard let record = record else { return }
		let properyListDecoder = PropertyListDecoder()

		do {
			if let latestRecordToRestore = record.value(forKey: "inventoryData") as? Data {

				let retrievedInventory = try properyListDecoder.decode([Product].self, from: latestRecordToRestore)
				print(record, retrievedInventory)
				DispatchQueue.main.async {
					masterInventory.productArray = retrievedInventory
				}
			}
		}
		catch {
			print(error)
		}
	}

}

extension UILabel {

	/// Will auto resize the contained text to a font size which fits the frames bounds.
	/// Uses the pre-set font to dynamically determine the proper sizing
	func fitTextToBounds() {
		guard let text = text, let currentFont = font else { return }

		let bestFittingFont = UIFont.bestFittingFont(for: text, in: bounds, fontDescriptor: currentFont.fontDescriptor, additionalAttributes: basicStringAttributes)
		font = bestFittingFont
	}

	private var basicStringAttributes: [NSAttributedString.Key: Any] {
		var attribs = [NSAttributedString.Key: Any]()

		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = self.textAlignment
		paragraphStyle.lineBreakMode = self.lineBreakMode
		attribs[.paragraphStyle] = paragraphStyle

		return attribs
	}
}

extension UIFont {

	/**
	Will return the best font conforming to the descriptor which will fit in the provided bounds.
	*/
	static func bestFittingFontSize(for text: String, in bounds: CGRect, fontDescriptor: UIFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> CGFloat {
		let constrainingDimension = min(bounds.width, bounds.height)
		let properBounds = CGRect(origin: .zero, size: bounds.size)
		var attributes = additionalAttributes ?? [:]

		let infiniteBounds = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
		var bestFontSize: CGFloat = constrainingDimension

		for fontSize in stride(from: bestFontSize, through: 0, by: -1) {
			let newFont = UIFont(descriptor: fontDescriptor, size: fontSize)
			attributes[.font] = newFont

			let currentFrame = text.boundingRect(with: infiniteBounds, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)

			if properBounds.contains(currentFrame) {
				bestFontSize = fontSize
				break
			}
		}
		return bestFontSize
	}

	static func bestFittingFont(for text: String, in bounds: CGRect, fontDescriptor: UIFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> UIFont {
		let bestSize = bestFittingFontSize(for: text, in: bounds, fontDescriptor: fontDescriptor, additionalAttributes: additionalAttributes)
		return UIFont(descriptor: fontDescriptor, size: bestSize)
	}
}



//!! MARK -- Saving Dose Data

func loadDoseCalendarInfo() {
	let propertyListDecoder = PropertyListDecoder()
	do {
		if let da = UserDefaults.standard.data(forKey: "doseLogData") {
			let stored = try propertyListDecoder.decode([Dose].self, from: da)
			print(stored)
			doseLogDictionaryGLOBAL = stored
		}
	}
	catch {
		print(error)
	}
}

func saveDoseCalendarInfo() {
	let propertyListEncoder = PropertyListEncoder()
	do {
		let doseLogData: [Dose] = doseLogDictionaryGLOBAL
		let data = try propertyListEncoder.encode(doseLogData)
		UserDefaults.standard.set(data, forKey: "doseLogData")
	}
	catch {
		print(error)
	}
}



//!! MARK -- Saving Product and INventory Data

func saveProductToInventory(product: Product) {
//	globalMasterInventory.append(product)

	masterInventory.productArray.append(product)

	let propertyListEncoder = PropertyListEncoder()
	do {
		let inventoryData: [Product] = masterInventory.productArray
		let data = try propertyListEncoder.encode(inventoryData)
		UserDefaults.standard.set(data, forKey: "data")
	}
	catch {
		print(error)
	}


}

func saveCurrentProductInventoryToUserData() {
	let propertyListEncoder = PropertyListEncoder()
	do {
		let inventoryData: [Product] = masterInventory.productArray
		let data = try propertyListEncoder.encode(inventoryData)
		UserDefaults.standard.set(data, forKey: "data")
	}
	catch {
		print(error)
	}
}

func loadProductInventoryFromUserData() -> [Product] {
	let propertyListDecoder = PropertyListDecoder()
	var storedCopy: [Product] = []
	do {
		if let da = UserDefaults.standard.data(forKey: "data") {
			let stored = try propertyListDecoder.decode([Product].self, from: da)
			print(stored)
//			globalMasterInventory = stored
			storedCopy = stored
		}
	}
	catch {
		print(error)
	}

	return storedCopy
}

func removeProductFromInventory(product: Product) {

	var tempInventory: [Product] = masterInventory.productArray
	guard let indexOfProduct = tempInventory.firstIndex(of: product) else { return }
	tempInventory.remove(at: indexOfProduct)

	let propertyListEncoder = PropertyListEncoder()
	do {
		let products: [Product] = tempInventory
		let data = try propertyListEncoder.encode(products)
		UserDefaults.standard.set(data, forKey: "data")
	}
	catch {
		print(error)
	}
}




extension UIControl.Event {
	static var backToAnchorPoint: UIControl.Event { return UIControl.Event(rawValue: 0b0001 << 24) }
	static var overEligibleContainerRegion: UIControl.Event { return UIControl.Event(rawValue: 0b0010 << 24) }
}
