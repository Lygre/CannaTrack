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

	//create all of the interface elements here
	var minimumLabelStackView:UIStackView!
	var productLabel:UILabel!
	var strainLabel:UILabel!


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
		self.productLabel = UILabel(frame: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height/2))
		self.strainLabel = UILabel(frame: CGRect(x: 0, y: self.frame.height/2, width: self.frame.width, height: self.frame.height/2))
		self.productLabel.text = product.productType.rawValue
		self.strainLabel.text = product.strain.name
		self.productLabel.textAlignment = .center
		self.strainLabel.textAlignment = .center

		self.minimumLabelStackView = UIStackView(arrangedSubviews: [self.productLabel, self.strainLabel])
		self.minimumLabelStackView.axis = .vertical
		self.minimumLabelStackView.alignment = .center
		self.minimumLabelStackView.spacing = 2
		self.minimumLabelStackView.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
		self.addSubview(self.minimumLabelStackView)
		self.minimumLabelStackView.translatesAutoresizingMaskIntoConstraints = false
		self.minimumLabelStackView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
		self.minimumLabelStackView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
		self.minimumLabelStackView.widthAnchor.constraint(equalToConstant: self.frame.width - 10).isActive = true
		self.minimumLabelStackView.heightAnchor.constraint(equalToConstant: self.frame.height - 10).isActive = true

		self.productLabel.isUserInteractionEnabled = false
		self.strainLabel.isUserInteractionEnabled = false
		self.minimumLabelStackView.isUserInteractionEnabled = false

	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		print("product view loaded")
	}




}
