//
//  Dose.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/29/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit
import JTAppleCalendar

class Dose: Codable {




	var timestamp: Date!
	var product: Product!
	var mass: Double!
	var administrationRoute: AdministrationRoute?

	init(timestamp: Date, product: Product, mass: Double, route: AdministrationRoute?) {
		self.timestamp = timestamp
		self.product = product
		self.mass = mass
		self.administrationRoute = route
	}

	required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		timestamp = try values.decode(Date.self, forKey: .timestamp)
		product = try values.decode(Product.self, forKey: .product)
		mass = try values.decode(Double.self, forKey: .mass)
		administrationRoute = try values.decode(AdministrationRoute.self, forKey: .administrationRoute)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(timestamp, forKey: .timestamp)
		try container.encode(product, forKey: .product)
		try container.encode(mass, forKey: .mass)
		try container.encode(administrationRoute, forKey: .administrationRoute)
	}


}


extension Dose {

	enum AdministrationRoute: String, Codable {
		case oral = "Oral"
		case inhalation = "Inhalation"
	}

	enum CodingKeys: String, CodingKey {
		case timestamp
		case product
		case mass
		case administrationRoute
	}


}
