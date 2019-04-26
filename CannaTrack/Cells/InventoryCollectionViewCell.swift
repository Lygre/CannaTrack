//
//  InventoryCollectionViewCell.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/25/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class InventoryCollectionViewCell: UICollectionViewCell {

	@IBOutlet var inventoryProductLabel: UILabel!
	
	@IBOutlet var productStrainNameLabel: UILabel!

	@IBOutlet var productMassRemainingLabel: UILabel!
	
	@IBOutlet var doseCountLabel: UILabel!

	@IBOutlet var dateOpenedLabel: UILabel!


	override var isSelected: Bool {
		didSet {
			self.layer.borderWidth = isSelected ? 2 : 0
		}
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		isSelected = false
		self.layer.borderColor = UIColor.blue.cgColor
	}

}
