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

	var path: UIBezierPath!

	override var bounds: CGRect {
		get { return super.bounds }
		set(newBounds) {
			super.bounds = newBounds
			let newFrameSize = min(newBounds.size.width, newBounds.size.height)
			self.layer.cornerRadius = newFrameSize / 2.0
		}
	}

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

		setupMotionEffectForAddButton()

	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
		self.layer.shadowOffset = CGSize(width: 0.0, height: 0.2)
		self.layer.shadowOpacity = 1.0
		self.layer.shadowRadius = 0.0
		self.clipsToBounds = true

//		setupMotionEffectForAddButton()
//		setupShadowMotionEffectForAddButton()

	}


	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		let animator = UIViewPropertyAnimator(duration: 0.3, curve: .linear) {
			self.bounds = CGRect(x: self.frame.minX, y: self.frame.minY, width: self.bounds.height * 2, height: self.bounds.height * 2)
		}
		addButtonDelegate?.animateTouchesBegan(button: self, animator: animator)
	}



    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
		self.createCircle()

		UIColor.purple.setFill()
		path.fill()
		UIColor.purple.setStroke()
		path.stroke()
    }

	func createCircle() {
		self.path = UIBezierPath(ovalIn: CGRect(x: self.frame.size.width / 2 - self.frame.size.height / 2, y: 0.0, width: self.frame.size.height, height: self.frame.size.height))
	}

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
