//
//  Inventory.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

class Inventory: Codable {

	var productArray: [Product] {
		didSet {
		//implement writing user data here
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
