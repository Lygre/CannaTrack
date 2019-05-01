//
//  CustomCell.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/28/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import JTAppleCalendar

class CustomCell: JTAppleCell {

	@IBOutlet weak var dateLabel: UILabel!
	@IBOutlet weak var selectedView: UIView!
	@IBOutlet weak var dosesPresentIndicatorView: UIView!

	var dosesPresentOnDate: Bool! = false

	override func draw(_ rect: CGRect) {
		super.draw(rect)

	}

	override func layoutSubviews() {
		super.layoutSubviews()
		var frame = self.bounds
		frame.size.width = min(frame.width, frame.height)
		frame.size.height = frame.width
		self.selectedView.layer.cornerRadius = frame.width * 0.5
		self.dosesPresentIndicatorView.layer.cornerRadius = self.dosesPresentIndicatorView.frame.size.height * 0.5
		self.dosesPresentIndicatorView.layer.masksToBounds = true
	}

}
