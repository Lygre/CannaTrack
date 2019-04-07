//
//  DoseProductsTableView.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DoseProductsTableView: UITableView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

	override init(frame: CGRect, style: UITableView.Style) {
		super.init(frame: frame, style: style)
		backgroundView = UIImageView(image: UIImage(imageLiteralResourceName: "cannabisbg.png"))
		backgroundColor = .purple
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}

}
