//
//  AddProductFloatingButton.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class AddProductFloatingButton: UIButton {


	var actionOptionSubviews: [UIView]!

	var addOptionSubview: UIView!
	var deleteOptionSubview: UIView!

	let indicaColor = UIColor(named: "indicaColor")
	unowned var addButtonDelegate: AddButtonDelegate?


	var path: UIBezierPath!

	var propertyAnimator: UIViewPropertyAnimator = {
		let propertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
		})
		propertyAnimator.isUserInteractionEnabled = true
		propertyAnimator.isInterruptible = true
		propertyAnimator.scrubsLinearly = true
		propertyAnimator.pausesOnCompletion = true
		return propertyAnimator
	}()


	override var transform: CGAffineTransform {
		get { return super.transform }
		set(newTransform) {
			super.transform = newTransform

		}
	}


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

		self.backgroundColor = .clear

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
		self.clipsToBounds = true

		addOptionSubview = UIView(frame: self.frame)
		deleteOptionSubview = UIView(frame: self.frame)

		actionOptionSubviews = [addOptionSubview, deleteOptionSubview]

		propertyAnimator.addAnimations {
			self.transform = .init(scaleX: 2.5, y: 2.5)
		}

	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)

		self.backgroundColor = .clear

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
		self.clipsToBounds = true

		addOptionSubview = UIView(frame: self.frame)
		deleteOptionSubview = UIView(frame: self.frame)

		actionOptionSubviews = [addOptionSubview, deleteOptionSubview]

		for view in actionOptionSubviews {
			self.addSubview(view)
			view.backgroundColor = .yellow
			view.layer.cornerRadius = 12
			view.layer.masksToBounds = true
			view.layer.opacity = 0.0
		}

		propertyAnimator.addAnimations {
			self.transform = .init(scaleX: 2.5, y: 2.5)
			
		}

//		guard let _ = superview else {
//			print("no superview")
//			return
//		}



	}

	override func layoutSubviews() {
		super.layoutSubviews()
		self.backgroundColor = .purple
		self.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
		self.layer.shadowOffset = CGSize(width: 0.0, height: 0.5)
		self.layer.shadowOpacity = 1.0
		self.layer.shadowRadius = 0.0
		self.layer.masksToBounds = true
		self.translatesAutoresizingMaskIntoConstraints = false
		setupShadowMotionEffectForAddButton()
//
//		dynamicAnimator = UIDynamicAnimator(referenceView: (self.superview ?? nil)!)
//
//		snapBehavior1 = UISnapBehavior(item: actionOptionSubviews[0], snapTo: CGPoint(x: self.center.x + self.bounds.width / 2, y: self.center.y))
//
//		snapBehavior2 = UISnapBehavior(item: actionOptionSubviews[1], snapTo: CGPoint(x: self.center.x - self.bounds.width / 2, y: self.center.y))
//		snapBehavior1.damping = 1.0
//		snapBehavior2.damping = 1.0
//		dynamicAnimator.addBehavior(snapBehavior1)
//		dynamicAnimator.addBehavior(snapBehavior2)
	}


	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		propertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear) {
			self.transform = .init(scaleX: 2.5, y: 2.5)
		}
		propertyAnimator.startAnimation()
		propertyAnimator.pauseAnimation()
//		addButtonDelegate?.animateTouchesBegan(button: self, animator: animator)
	}



    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
		super.draw(rect)
		self.createCircle()

		UIColor.purple.setFill()
		path.fill()
		UIColor.purple.setStroke()
		path.stroke()

		self.bounds = path.bounds
    }

	func createCircle() {
		self.path = UIBezierPath(ovalIn: CGRect(x: self.frame.size.width / 2 - self.frame.size.height / 2, y: 0.0, width: self.bounds.size.height, height: self.bounds.size.height))
	}

}



extension AddProductFloatingButton {
	//basic functionality. Setting up MOtion effects for the button, etc

	fileprivate func setupMotionEffectForAddButton() {
		//some UI playing around with Motion Effects and with the floating add product button
		let horizontalEffect = UIInterpolatingMotionEffect(keyPath: "center.x", type: .tiltAlongHorizontalAxis)

		horizontalEffect.minimumRelativeValue = -3
		horizontalEffect.maximumRelativeValue = 3

		let verticalEffect = UIInterpolatingMotionEffect(keyPath: "center.y", type: .tiltAlongVerticalAxis)
		verticalEffect.minimumRelativeValue = -3
		verticalEffect.maximumRelativeValue = 3

		let effectGroup = UIMotionEffectGroup()
		effectGroup.motionEffects = [ horizontalEffect, verticalEffect ]


		self.addMotionEffect(effectGroup)
	}

	fileprivate func setupShadowMotionEffectForAddButton() {
		if self.motionEffects.count > 0 {
			self.removeMotionEffect(self.motionEffects[0])
		} else {
			let horizontalEffect = UIInterpolatingMotionEffect(
				keyPath: "layer.shadowOffset.width",
				type: .tiltAlongHorizontalAxis)
			horizontalEffect.minimumRelativeValue = 3
			horizontalEffect.maximumRelativeValue = -3

			let verticalEffect = UIInterpolatingMotionEffect(
				keyPath: "layer.shadowOffset.height",
				type: .tiltAlongVerticalAxis)
			verticalEffect.minimumRelativeValue = 3
			verticalEffect.maximumRelativeValue = -3

			let effectGroup = UIMotionEffectGroup()
			effectGroup.motionEffects = [ horizontalEffect,
										  verticalEffect ]

			self.addMotionEffect(effectGroup)
		}
	}


}

//property animator extensions

extension AddProductFloatingButton {

	func updateAnimationProgress(with progress: CGFloat) {

		self.propertyAnimator.fractionComplete = progress

	}

	func completePreview() {
		self.updateAnimationProgress(with: 0)
		if self.propertyAnimator.isRunning {
			self.propertyAnimator.stopAnimation(false)
			self.propertyAnimator.finishAnimation(at: .end)
		} else {
			self.propertyAnimator.stopAnimation(false)
			self.propertyAnimator.finishAnimation(at: .end)
			print("tried to complete preview, but animator was still running?")}
	}

	func animateButtonToRegularSize() {
		self.propertyAnimator.addAnimations {
			self.bounds.size = CGSize(width: 60, height: 60)
		}
	}

	func animateButtonForRegion(for size: CGSize) {
		self.propertyAnimator.stopAnimation(false)
		self.propertyAnimator.finishAnimation(at: .start)
		self.propertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
			self.bounds = CGRect(origin: self.center, size: size)
		})
		self.propertyAnimator.startAnimation()
	}

	func animateButtonForPreviewInteractionChoice() {
		self.propertyAnimator.stopAnimation(false)
		self.propertyAnimator.finishAnimation(at: .start)
		self.propertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
			self.addOptionSubview.layer.opacity = 1.0
			self.deleteOptionSubview.layer.opacity = 1.0
			self.addOptionSubview.frame = CGRect(origin: CGPoint(x: self.frame.minX, y: self.frame.midY), size: self.bounds.size)
			self.deleteOptionSubview.frame = CGRect(origin: CGPoint(x: self.frame.minX, y: self.frame.midY), size: self.bounds.size)
		})
		print("starting animator with new added animations")
		self.propertyAnimator.startAnimation()
//		self.propertyAnimator.pauseAnimation()
	}

}
