//
//  ProductTableViewCell.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class ProductTableViewCell: UITableViewCell {

	@IBOutlet var productTypeLabel: UILabel!
	@IBOutlet var productStrainLabel: UILabel!
	@IBOutlet var productDoseCountLabel: UILabel!
	@IBOutlet var massForProductInDoseLabel: UILabel!



    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
