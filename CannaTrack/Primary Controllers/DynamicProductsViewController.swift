//
//  DynamicProductsViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/15/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DynamicProductsViewController: UIViewController {

	let ThrowingThreshold: CGFloat = 900
	let ThrowingVelocityPadding: CGFloat = 50

	var originalBounds = CGRect.zero
	var originalCenter = CGPoint.zero

	var previousTouchPoint: CGPoint = .zero
	var snap: UISnapBehavior!
	var attachment: UIAttachmentBehavior!
	var pushBehavior: UIPushBehavior!
	var itemBehavior: UIDynamicItemBehavior!
	var itemBehavior2: UIDynamicItemBehavior!
	var animator: UIDynamicAnimator!
	var gravity: UIGravityBehavior!
	var collision: UICollisionBehavior!
	var fieldBehavior: UIFieldBehavior!
//	var collisionDelegate: UICollisionBehaviorDelegate!
	var productViewArray: [ProductView]!

    override func viewDidLoad() {
        super.viewDidLoad()
		animator = UIDynamicAnimator(referenceView: view)
		self.view.layoutIfNeeded()
		productViewArray = []
		var countForViews: Int = 0
		//execute for loop here to iterate over inventory and create ProductView for each product and add it to the view hierarchy
		for product in globalMasterInventory {
			let productView = ProductView(frame: CGRect(x: self.view.frame.width / 2, y: 10, width: 100, height: 100), product: product)
			productView.layer.cornerRadius = productView.frame.width / 2
			view.addSubview(productView)
			productView.center = CGPoint(x: self.view.frame.width / 2, y: (10 + (productView.bounds.height * CGFloat(countForViews))))
			countForViews += 1
			let origPos = view.center
			snap = UISnapBehavior(item: productView, snapTo: origPos)
			snap.damping = 0.8
			productViewArray.append(productView)
//			animator.addBehavior(snap)
		}

		for productView in productViewArray {
			let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanForProductView(recognizer:)))
			let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapForProductView(recognizer:)))
			productView.addGestureRecognizer(pan)
			productView.addGestureRecognizer(tap)
			productView.isUserInteractionEnabled = true
		}
		//add collision
		collision = UICollisionBehavior(items: productViewArray)
		collision.collisionDelegate = self
		collision.translatesReferenceBoundsIntoBoundary = true
		collision.collisionMode = .everything
		animator.addBehavior(collision)
		//add gravity
		gravity = UIGravityBehavior(items: productViewArray)
//		animator.addBehavior(gravity)

		itemBehavior = UIDynamicItemBehavior(items: productViewArray)
		itemBehavior.friction = 0.2
		itemBehavior.elasticity = 0.5
		itemBehavior.allowsRotation = false
		//				itemBehavior.addAngularVelocity(CGFloat(angle), for: productViewToTranslate)
		animator.addBehavior(itemBehavior)

//		pushBehavior = UIPushBehavior(items: productViewArray, mode: .instantaneous)
//		for view in pushBehavior.items {
//			pushBehavior.setTargetOffsetFromCenter(UIOffset(horizontal: 50, vertical: 50), for: view)
//		}
//		pushBehavior.magnitude = 1.0
//		pushBehavior.angle = .pi
//		animator.addBehavior(pushBehavior)
//		pushBehavior.active = true



        // Do any additional setup after loading the view.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
	@IBAction func refreshViewClicked(_ sender: Any) {
		refreshUI()
	}

}


extension DynamicProductsViewController {

	func refreshUI() {
		view.layoutSubviews()
	}


	func resetViews() {
		animator.removeAllBehaviors()

		UIView.animate(withDuration: 0.45) {
			for productView in self.productViewArray {
				productView.bounds = self.originalBounds
				productView.center = self.originalCenter
				productView.transform = CGAffineTransform.identity
			}
		}

	}

	//the behavior has to be added and removed so as to not interfere with the normal pan gesture functionality
	//noted******
	@objc func handlePanForProductView(recognizer: UIPanGestureRecognizer) {
		let location = recognizer.location(in: self.view)
		let locationCenterView = view.center
		guard let productViewToTranslate = recognizer.view else { return }

		switch recognizer.state {
		case .changed:


			itemBehavior.isAnchored = false
			let translation = recognizer.translation(in: view)
			let velocity = recognizer.velocity(in: view)
			let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
			let pushBehavior = UIPushBehavior(items: [productViewToTranslate], mode: .instantaneous)
			pushBehavior.pushDirection = CGVector(dx: velocity.x / 10, dy: velocity.y / 10)
			pushBehavior.magnitude = magnitude / ThrowingVelocityPadding
			self.pushBehavior = pushBehavior
			animator.addBehavior(pushBehavior)

			pushBehavior.active = false

//			productViewToTranslate.center = CGPoint(x: productViewToTranslate.center.x + translation.x, y: productViewToTranslate.center.y + translation.y)
			productViewToTranslate.center = location
			previousTouchPoint = location
			animator.updateItem(usingCurrentState: productViewToTranslate)


		case .began:
			recognizer.setTranslation(.zero, in: view)
//			let dragStartPoint = recognizer.location(in: productViewToTranslate)
			previousTouchPoint = location

			animator.removeBehavior(snap)
			productViewToTranslate.center = location

			print(collision.items.debugDescription)
			guard let push = pushBehavior else { return }
			animator.removeBehavior(push)

			let itemCurrentVelocity = itemBehavior.linearVelocity(for: productViewToTranslate)
			print(itemCurrentVelocity)
			itemBehavior.addLinearVelocity(CGPoint(x: -itemCurrentVelocity.x, y: -itemCurrentVelocity.y), for: productViewToTranslate)


//			animator.removeBehavior(snap)
		case .cancelled, .failed:
//			recognizer.setTranslation(.zero, in: view)
			animator.addBehavior(snap)
		case .ended:
//			animator.updateItem(usingCurrentState: productViewToTranslate)
			itemBehavior.isAnchored = false
			let velocity = recognizer.velocity(in: view)
			let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
			pushBehavior.active = true
			if magnitude > ThrowingThreshold {
				let pushBehavior = UIPushBehavior(items: productViewArray, mode: .instantaneous)
				pushBehavior.pushDirection = CGVector(dx: velocity.x / 10, dy: velocity.y / 10)
				pushBehavior.magnitude = magnitude / ThrowingVelocityPadding
				self.pushBehavior = pushBehavior
				animator.addBehavior(pushBehavior)

//				let angle = Int(arc4random_uniform(20)) - 10


			}
//			self.pushBehavior.active = true

		case .possible:
			break
		}

	}

	@objc func handleTapForProductView(recognizer: UITapGestureRecognizer) {
		let location = recognizer.location(in: self.view)
		let locationCenterView = view.center
		guard let productViewToTranslate = recognizer.view as? ProductView else { return }
		print("tap recognized in \(productViewToTranslate)")

		if productViewToTranslate.isFocusedForDetailsMin == false {
			UIView.animate(withDuration: 0.4) {
				productViewToTranslate.frame.size = CGSize(width: productViewToTranslate.frame.width * 2, height: productViewToTranslate.frame.height * 2)
				productViewToTranslate.transform = CGAffineTransform(scaleX: 2, y: 2)

				let textView = UILabel()
				productViewToTranslate.addSubview(textView)
				textView.text = "Hi"
				textView.translatesAutoresizingMaskIntoConstraints = false
				textView.centerXAnchor.constraint(equalTo: productViewToTranslate.centerXAnchor).isActive = true
				textView.centerYAnchor.constraint(equalTo: productViewToTranslate.centerYAnchor).isActive = true
				textView.widthAnchor.constraint(equalToConstant: 50).isActive = true
				textView.heightAnchor.constraint(equalToConstant: 30).isActive = true

				productViewToTranslate.isFocusedForDetailsMin = true
				productViewToTranslate.contentMode = .scaleAspectFit
				self.view.layoutIfNeeded()
			}
			animator.updateItem(usingCurrentState: productViewToTranslate)
		} else { UIView.animate(withDuration: 0.4) {
			productViewToTranslate.frame.size = CGSize(width: productViewToTranslate.frame.width / 2, height: productViewToTranslate.frame.height / 2)
			productViewToTranslate.transform = CGAffineTransform.identity
			productViewToTranslate.isFocusedForDetailsMin = false
			self.view.layoutIfNeeded()
			} }


	}



	@objc func handleOldPanForProductView(recognizer: UIPanGestureRecognizer) {
		let location = recognizer.location(in: self.view)
		let locationCenterView = view.center
		//		let boxLocation = recognizer.location(in: self.)
		guard let productViewToTranslate = recognizer.view else { return }

		switch recognizer.state {
		case .changed:
			let translation = recognizer.translation(in: view)

			productViewToTranslate.center = CGPoint(x: productViewToTranslate.center.x + translation.x, y: productViewToTranslate.center.y + translation.y)
			recognizer.setTranslation(.zero, in: view)

		case .began:
			animator.removeAllBehaviors()

			let centerOffset = UIOffset(horizontal: 50, vertical: -50)

			attachment = UIAttachmentBehavior(item: productViewToTranslate, offsetFromCenter: centerOffset, attachedToAnchor: locationCenterView)

			//			productViewToTranslate.center = attachment.anchorPoint
			animator.addBehavior(attachment)

		case .ended:
			let velocity = recognizer.velocity(in: view)
			let magnitude = sqrt((velocity.x * velocity.x) + (velocity.y * velocity.y))
			if magnitude > ThrowingThreshold {
				let pushBehavior = UIPushBehavior(items: productViewArray, mode: .instantaneous)
				pushBehavior.pushDirection = CGVector(dx: velocity.x / 10, dy: velocity.y / 10)
				pushBehavior.magnitude = magnitude / ThrowingVelocityPadding
				self.pushBehavior = pushBehavior
				animator.addBehavior(pushBehavior)

				let angle = Int(arc4random_uniform(20)) - 10

				itemBehavior = UIDynamicItemBehavior(items: productViewArray)
				itemBehavior.friction = 0.2
				itemBehavior.allowsRotation = true
				itemBehavior.addAngularVelocity(CGFloat(angle), for: productViewToTranslate)
				animator.addBehavior(itemBehavior)
			}
		//			else { resetViews() }
		default:
			attachment.anchorPoint = location
			//			productViewToTranslate.center = attachment.anchorPoint
		}

	}

}


extension DynamicProductsViewController: UICollisionBehaviorDelegate {



}
