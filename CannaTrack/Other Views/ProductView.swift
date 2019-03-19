//
//  ProductView.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/15/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class ProductView: UIView {

	var productForView: Product!
	var isFocusedForDetailsMin: Bool = false
	var focusTransform: CGAffineTransform?

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */
	init(frame: CGRect, product: Product) {
		super.init(frame: frame)
		self.productForView = product
		switch self.productForView.strain.race {
		case .hybrid:
			self.backgroundColor = .green
		case .indica:
			self.backgroundColor = .purple
		case .sativa:
			self.backgroundColor = .yellow
		}
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		print("product view loaded")
	}




}
