//
//  InventoryFilterDelegate.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/9/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation

protocol InventoryFilterDelegate: class {
	func filterInventory(using filterOption: FilterOption)
}
