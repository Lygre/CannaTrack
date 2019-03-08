//
//  Product.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/21/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

class Product {


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

}



extension Product {

	enum ProductType: String {
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
