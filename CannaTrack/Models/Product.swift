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
	var mass: Double
	var dateOpened: Date?

	init(typeOfProduct: ProductType, strainForProduct: Strain, inGrams massOfProduct: Double) {
		self.productType = typeOfProduct
		self.strain = strainForProduct
		self.mass = massOfProduct
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
