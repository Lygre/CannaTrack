//
//  InventoryManagerDelegate.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/11/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import CloudKit
import UIKit


protocol InventoryManagerDelegate: class {
	func deleteProductFromLocalInventory(product: Product)

	func addProductToInventory(product: Product)

	func updateProduct(product: Product)
}
