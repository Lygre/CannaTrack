//
//  StrainCollectionViewCell.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/18/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class StrainCollectionViewCell: UICollectionViewCell {

	/*
	override func awakeFromNib() {
		super.awakeFromNib()
	}
	*/

	@IBOutlet var strainAbbreviation: UILabel!

	@IBOutlet var strainName: UILabel!

	@IBOutlet var varietyLabel: UILabel!

	var isFavorite: Bool = false {
		didSet {
			self.layer.borderWidth = isFavorite ? 2 : 0
		}
	}



	override func awakeFromNib() {
		super.awakeFromNib()
		isFavorite = false
		self.layer.borderColor = UIColor.green.cgColor
	}


}
