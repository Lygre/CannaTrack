//
//  DateSelectedIndicatorView.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/24/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DateSelectedIndicatorView: UIView {

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

	override var bounds: CGRect {
		get { return super.bounds }
		set(newBounds) {
			super.bounds = newBounds
			let newFrameSize = min(newBounds.size.width, newBounds.size.height)
			self.layer.cornerRadius = newFrameSize / 2.0
		}
	}

}
