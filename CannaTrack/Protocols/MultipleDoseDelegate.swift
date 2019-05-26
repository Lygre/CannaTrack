//
//  MultipleDoseDelegate.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/9/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation



protocol MultipleDoseDelegate: class {
	func saveCompositeDoseProductEntry(product: Product, mass: Double)
	func saveAdministrationRouteForCompositeDoseProductEntry(product: Product, adminRoute: Dose.AdministrationRoute)
}
