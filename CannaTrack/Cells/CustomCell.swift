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
	@IBOutlet weak var selectedView: DateSelectedIndicatorView!
	@IBOutlet weak var dosesPresentIndicatorView: DoseIndicatorView!

	var dosesPresentOnDate: Bool! = false

	override func draw(_ rect: CGRect) {
		super.draw(rect)

	}

	

	override func layoutSubviews() {
		super.layoutSubviews()

		let edgeInsets = UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)

		self.selectedView.bounds.inset(by: edgeInsets)

		var frame = self.bounds
		frame.size.width = min(frame.width, frame.height)
		frame.size.height = frame.width

		self.selectedView.layer.cornerRadius = self.selectedView.bounds.size.height / 2.0
		self.selectedView.clipsToBounds = true
		self.dosesPresentIndicatorView.layer.cornerRadius = self.dosesPresentIndicatorView.bounds.size.height / 2.0
		self.dosesPresentIndicatorView.clipsToBounds = true
	}

}


