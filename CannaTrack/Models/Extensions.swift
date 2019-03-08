//
//  Extensions.swift
//  CannaTracker
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

let testProduct1 = Product(typeOfProduct: .truShatter, strainForProduct: Strain(id: 1, name: "dick", race: .hybrid, description: "no"), inGrams: 0.5)
let testProduct2 = Product(typeOfProduct: .truCrmbl, strainForProduct: Strain(id: 2, name: "not dick", race: .indica, description: "yes"), inGrams: 0.8)

var globalMasterInventory: [Product] = [testProduct1, testProduct2]
