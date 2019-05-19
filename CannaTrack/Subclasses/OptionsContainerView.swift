//
//  OptionsContainerView.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/19/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class OptionsContainerView: UIView {

	let imagesForOptions: [UIImage] = [#imageLiteral(resourceName: "addIcon"), #imageLiteral(resourceName: "deleteIcon")]
	let imageSize: CGFloat = 60
	let padding: CGFloat = 6

	let propertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear)

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		let imageViewArray: [UIImageView] = imagesForOptions.map({ (image) -> UIImageView in
			let imageView = UIImageView(image: image)
			imageView.backgroundColor = .clear
			imageView.isUserInteractionEnabled = true

			return imageView
		})
		//add tag
		imageViewArray[0].tag = 0
		//delete tag
		imageViewArray[1].tag = 1
		let stackView = UIStackView(arrangedSubviews: imageViewArray)
		stackView.spacing = 10
		stackView.layoutMargins = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
		stackView.isLayoutMarginsRelativeArrangement = true
		stackView.distribution = .fillEqually
		stackView.axis = .horizontal
		self.addSubview(stackView)
		self.frame = CGRect(origin: .zero, size: CGSize(width: 250, height: imageSize))
		stackView.frame = self.frame
		self.alpha = 0.0
		self.backgroundColor = .clear
		self.propertyAnimator.addAnimations {
			self.alpha = 1.0
		}


	}
    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}
