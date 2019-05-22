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

	@IBOutlet var confirmationIndicator: UIImageView!

//	var productChangeConfirmationAnimator: UIViewPropertyAnimator!

	override var isSelected: Bool {
		didSet {
			self.layer.borderWidth = isSelected ? 2 : 0
		}
	}

	override func awakeFromNib() {
		super.awakeFromNib()
		isSelected = false
		self.layer.borderColor = UIColor.blue.cgColor

		self.confirmationIndicator.alpha = 0.0

	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

	}


}

