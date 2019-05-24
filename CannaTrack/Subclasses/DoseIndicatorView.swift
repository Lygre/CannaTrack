//
//  DoseIndicatorView.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/24/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit


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
