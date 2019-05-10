//
//  Product.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/21/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

class Product: Codable {

	

	var productType: ProductType
	var strain: Strain

	var productLabelImage: UIImage?
	var currentProductImage: UIImage?
	var mass: Double
	var dateOpened: Date?
	var numberOfDosesTakenFromProduct: Int
	var recordID: CKRecord.ID?

	init(typeOfProduct: ProductType, strainForProduct: Strain, inGrams massOfProduct: Double) {
		self.productType = typeOfProduct
		self.strain = strainForProduct
		self.mass = massOfProduct
		self.numberOfDosesTakenFromProduct = 0
	}

	required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		productType = try values.decode(ProductType.self, forKey: .productType)
		strain = try values.decode(Strain.self, forKey: .strain)

		// new method of encoding the images for Cloud storage
		let imgURL = try values.decode(URL.self, forKey: .productLabelImage)
		let imgPath = imgURL.path
		productLabelImage = UIImage(contentsOfFile: imgPath)

		currentProductImage = nil
		mass = try values.decode(Double.self, forKey: .mass)
		dateOpened = try? values.decode(Date.self, forKey: .dateOpened)
		numberOfDosesTakenFromProduct = try values.decode(Int.self, forKey: .numberOfDosesTakenFromProduct)


	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(productType, forKey: .productType)
		try container.encode(strain, forKey: .strain)

		//trying different encoding method for image
		let img = productLabelImage
		let manager = FileManager.default
		let dir = manager.urls(for: .documentDirectory, in: .userDomainMask)
		let file = dir[0].appendingPathComponent(productType.rawValue + self.strain.name + (dateOpened?.description(with: .current) ?? "Unopened"))
		try img?.jpegData(compressionQuality: 0.5)?.write(to: file, options: .atomic)
		let imgURL = NSURL.fileURL(withPath: file.path)
		try container.encode(imgURL, forKey: .productLabelImage)

		try container.encode(currentProductImage?.pngData(), forKey: .currentProductImage)
		try container.encode(mass, forKey: .mass)
		try container.encode(dateOpened, forKey: .dateOpened)
		try container.encode(numberOfDosesTakenFromProduct, forKey: .numberOfDosesTakenFromProduct)
	}

}

extension Product {

	enum CodingKeys: String, CodingKey {
		case productType
		case strain
		case productLabelImage
		case currentProductImage
		case mass
		case dateOpened
		case numberOfDosesTakenFromProduct
	}


}


extension Product {

	enum ProductType: String, Codable, CaseIterable {
		case truFlower = "truFlower"
		case truCrmbl = "truCRMBL"
		case truClear = "truClear"
		case truPod = "truPod"
		case truShatter = "truShatter"
		case vapePenCartridge = "Vape Pen Cartridge"
		case co2VapePenCartridge = "CO2 Vape Pen Cartridge"
		case oralSyringe = "Oral Syringe"
		case tinctureDropletBottle = "Tincture Droplet Bottle"
		case capsuleBottle = "Capsule Bottle"
		case topicalSunscreen = "Topical Sunscreen"
		case topicalLotion = "Topical Lotion"
		case rsoSyringe = "RSO Syringe"
		case topicalCream = "Topical Cream"
		case nasalSpray = "Nasal Spray"
	}




}


extension Product {

	func openProduct() {
		self.dateOpened = Date()
		saveCurrentProductInventoryToUserData()
//		saveProductChangesToCloud(product: self)
	}

	func saveNewProductToCloud() {
		let newProduct = CKRecord(recordType: "Product")

		let encoder = PropertyListEncoder()

		let productData: CKRecordValue = {
			do {
				let data = try encoder.encode(self)
				return data as CKRecordValue
			}
			catch { print(error); return Data() as CKRecordValue }
		}()

		let manager = FileManager.default
		let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
		let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask

		let paths = manager.urls(for: nsDocumentDirectory, in: nsUserDomainMask)

		if paths.count > 0 {
			let dirPath = paths[0]
			let writePath = dirPath.appendingPathComponent(self.productType.rawValue + self.strain.name + (self.dateOpened?.description(with: .current) ?? "Unopened"))
			let productImage: UIImage = {
				let imageToReturn: UIImage = UIImage(imageLiteralResourceName: "cannaleaf.png")
				guard let image = self.productLabelImage else { return imageToReturn }
				return image
			}()

			try? productImage.pngData()?.write(to: writePath)
			let productImageData: CKAsset? = CKAsset(fileURL: NSURL(fileURLWithPath: writePath.path) as URL)
			newProduct.setObject(productImageData, forKey: "ProductImageData")
		}

		newProduct.setObject(productData, forKey: "ProductData")


		//assign Product a record ID to fetch and modify it later



		privateDatabase.save(newProduct) { (record, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					self.recordID = newProduct.recordID
					print("Record was saved in private DB by Product.swift method")
				}
			}
		}

	}

	func saveProductChangesToCloud(product: Product) {
		guard let recordID = product.recordID else { return }
		let operation = CKModifyRecordsOperation(recordsToSave: [CKRecord(recordType: "Product", recordID: recordID)], recordIDsToDelete: nil)
		let config = CKModifyRecordsOperation.Configuration()
		config.timeoutIntervalForRequest = 20
		config.timeoutIntervalForResource = 20
		operation.configuration = config

		operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else if let records = savedRecords {
					print("saved \(records.count) records")
				}
			}
		}

		privateDatabase.add(operation)


	}

	func encodeProductAsCKRecordValue() -> CKRecordValue? {
		let plistEncoder = PropertyListEncoder()
		let data = try? plistEncoder.encode(self)

		return data as CKRecordValue?
	}


	func deleteProductFromCloud() {
		guard let recordID = self.recordID else { return }

		privateDatabase.delete(withRecordID: recordID) { (deletedRecordID, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					print("Record was deleted from ProductDetailViewController.swift method")

				}
			}
		}
	}

}

extension Product: Equatable {

	static func == (lhs: Product, rhs: Product) -> Bool {
		return lhs.dateOpened == rhs.dateOpened && lhs.productLabelImage == rhs.productLabelImage && lhs.strain == rhs.strain && lhs.productType == rhs.productType
	}

}


extension Product: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(productType)
		hasher.combine(strain)
		hasher.combine(dateOpened)

	}
}


extension Product {

	func saveToFile() {
		
	}



}
