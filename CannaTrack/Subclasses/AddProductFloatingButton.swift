//
//  AddProductFloatingButton.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class AddProductFloatingButton: UIButton {

	let indicaColor = UIColor(named: "indicaColor")
	var addButtonDelegate: AddButtonDelegate?


	override init(frame: CGRect) {
		super.init(frame: frame)


		self.backgroundColor = UIColor(named: "sativaColor")


		self.setTitle("+", for: .normal)
		self.setTitle("+", for: .disabled)
		self.setTitle("+", for: .focused)
		self.setTitle("+", for: .application)
		self.setTitle("+", for: .highlighted)
		self.setTitle("+", for: .reserved)
		self.setTitle("+", for: .selected)

		self.setTitleColor(indicaColor, for: .normal)
		self.setTitleColor(indicaColor, for: .disabled)
		self.setTitleColor(indicaColor, for: .focused)
		self.setTitleColor(indicaColor, for: .application)
		self.setTitleColor(indicaColor, for: .highlighted)
		self.setTitleColor(indicaColor, for: .reserved)
		self.setTitleColor(indicaColor, for: .selected)


	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.clipsToBounds = true
		self.layer.cornerRadius = self.bounds.size.height / 2
		self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
		self.layer.shadowOffset = CGSize(width: 0.0, height: 0.2)
		self.layer.shadowOpacity = 1.0
		self.layer.shadowRadius = 0.0
		self.layer.masksToBounds = false

//		setupMotionEffectForAddButton()
		setupShadowMotionEffectForAddButton()


	}


	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
			self.frame = CGRect(x: self.frame.minX, y: self.frame.maxY, width: self.frame.width * 2, height: self.frame.height * 2)
		}
		addButtonDelegate?.animateTouchesBegan(button: self, animator: animator)
	}

	/*
	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {

		let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
			self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: self.frame.width / 2, height: self.frame.height / 2)
		}
		addButtonDelegate?.animateTouchesBegan(button: self, animator: animator)

	}
	*/
	/*
	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
		let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
			self.frame = CGRect(x: self.frame.minX, y: self.frame.minY, width: self.frame.width / 2, height: self.frame.height / 2)
		}
		addButtonDelegate?.animateTouchesBegan(button: self, animator: animator)
	}
	*/

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}



extension AddProductFloatingButton {
	//basic functionality. Setting up MOtion effects for the button, etc

	fileprivate func setupMotionEffectForAddButton() {
		//some UI playing around with Motion Effects and with the floating add product button
		let horizontalEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)

		horizontalEffect.minimumRelativeValue = -16
		horizontalEffect.maximumRelativeValue = 16

		let verticalEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
		verticalEffect.minimumRelativeValue = -16
		verticalEffect.maximumRelativeValue = 16

		let effectGroup = UIMotionEffectGroup()
		effectGroup.motionEffects = [ horizontalEffect, verticalEffect ]


		self.addMotionEffect(effectGroup)
	}

	fileprivate func setupShadowMotionEffectForAddButton() {
		let horizontalEffect = UIInterpolatingMotionEffect(
			keyPath: "layer.shadowOffset.width",
			type: .tiltAlongHorizontalAxis)
		horizontalEffect.minimumRelativeValue = 16
		horizontalEffect.maximumRelativeValue = -16

		let verticalEffect = UIInterpolatingMotionEffect(
			keyPath: "layer.shadowOffset.height",
			type: .tiltAlongVerticalAxis)
		verticalEffect.minimumRelativeValue = 16
		verticalEffect.maximumRelativeValue = -16

		let effectGroup = UIMotionEffectGroup()
		effectGroup.motionEffects = [ horizontalEffect,
									  verticalEffect ]

		self.addMotionEffect(effectGroup)
	}


}
