//
//  EditMassDelegate.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/9/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import CloudKit


protocol EditMassDelegate: class {
	func editMassForProduct(product: Product, with record: CKRecord)
}


