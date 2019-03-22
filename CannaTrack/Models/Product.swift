//
//  Product.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/21/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

class Product: Codable {

	

	let productType: ProductType
	let strain: Strain

	var productLabelImage: UIImage?
	var currentProductImage: UIImage?
	var mass: Double
	var dateOpened: Date?
	var numberOfDosesTakenFromProduct: Int

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

		productLabelImage = nil
//			UIImage(data: try values.decode(Data.self, forKey: .productLabelImage))
		currentProductImage = nil
//			UIImage(data: try values.decode(Data.self, forKey: .currentProductImage))
		mass = try values.decode(Double.self, forKey: .mass)
		dateOpened = try? values.decode(Date.self, forKey: .dateOpened)
		numberOfDosesTakenFromProduct = try values.decode(Int.self, forKey: .numberOfDosesTakenFromProduct)


	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(productType, forKey: .productType)
		try container.encode(strain, forKey: .strain)
		try container.encode(productLabelImage?.jpegData(compressionQuality: 0.5), forKey: .productLabelImage)
		try container.encode(currentProductImage?.jpegData(compressionQuality: 0.5), forKey: .currentProductImage)
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

	enum ProductType: String, Codable {
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
	}

}

extension Product: Equatable {

	static func == (lhs: Product, rhs: Product) -> Bool {
		return lhs.dateOpened == rhs.dateOpened && lhs.productLabelImage == rhs.productLabelImage && lhs.strain == rhs.strain && lhs.productType == rhs.productType
	}

}



extension Product {

	func saveToFile() {
		
	}



}
