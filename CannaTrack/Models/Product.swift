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
	var mass: Double
	var dateOpened: Date?

	init(typeOfProduct: ProductType, inGrams massOfProduct: Double) {
		self.productType = typeOfProduct
		self.mass = massOfProduct
	}

}



extension Product {

	enum ProductType {
		case truFlower, truCrmbl, truClear, truPod, truShatter
		case vapePenCartridge, co2VapePenCartridge, oralSyringe, tinctureDropletBottle, capsuleBottle, topicalSunscreen, topicalLotion, rsoSyringe, topicalCream, nasalSpray
	}




}


extension Product {

	func openProduct() {
		self.dateOpened = Date()
	}

}
