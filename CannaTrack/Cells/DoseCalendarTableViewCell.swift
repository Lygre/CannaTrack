//
//  DoseCalendarTableViewCell.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/29/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DoseCalendarTableViewCell: UITableViewCell {


	@IBOutlet var timeLabel: UILabel!
	@IBOutlet var productLabel: UILabel!
	@IBOutlet var strainLabel: UILabel!



    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}