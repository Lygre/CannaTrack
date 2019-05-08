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
	@IBOutlet weak var dosesPresentIndicatorView: DoseIndicatorView!

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
		self.dosesPresentIndicatorView.layer.cornerRadius = self.dosesPresentIndicatorView.bounds.size.height / 2.0
//		self.dosesPresentIndicatorView.layer.masksToBounds = true
		self.dosesPresentIndicatorView.clipsToBounds = true
	}

}

class DoseIndicatorView: UIView {

	override var bounds: CGRect {
		get { return super.bounds }
		set(newBounds) {
			super.bounds = newBounds
			let newFrameSize = min(newBounds.size.width, newBounds.size.height)
			self.layer.cornerRadius = newFrameSize / 2.0
		}
	}

}
