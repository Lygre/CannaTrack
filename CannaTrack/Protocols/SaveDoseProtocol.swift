//
//  SaveDoseProtocol.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/11/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

protocol SaveDoseDelegate: class {

	func saveDoseInformation(product: Product, doseDate: Date, updatedMass: Double?, updatedProductImage: UIImage?)

}
