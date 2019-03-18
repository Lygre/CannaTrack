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

	var snap: UISnapBehavior!
	var attachment: UIAttachmentBehavior!
	var pushBehavior: UIPushBehavior!
	var itemBehavior: UIDynamicItemBehavior!
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
			animator.addBehavior(snap)
		}

		for productView in productViewArray {
			let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanForProductView(recognizer:)))
			productView.addGestureRecognizer(pan)
			productView.isUserInteractionEnabled = true
		}
		//add collision
		collision = UICollisionBehavior(items: productViewArray)
		collision.collisionDelegate = self
//		collision.setTranslatesReferenceBoundsIntoBoundary(with: UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10))
		collision.translatesReferenceBoundsIntoBoundary = true
		collision.collisionMode = .everything
		animator.addBehavior(collision)
		//add gravity
		gravity = UIGravityBehavior(items: productViewArray)
//		animator.addBehavior(gravity)


		pushBehavior = UIPushBehavior(items: productViewArray, mode: .continuous)
		for view in pushBehavior.items {
			pushBehavior.setTargetOffsetFromCenter(UIOffset(horizontal: 50, vertical: 50), for: view)
		}
//		pushBehavior.magnitude = 1.0
//		pushBehavior.angle = .pi
		animator.addBehavior(pushBehavior)
		pushBehavior.active = true



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
			let translation = recognizer.translation(in: view)

			productViewToTranslate.center = CGPoint(x: productViewToTranslate.center.x + translation.x, y: productViewToTranslate.center.y + translation.y)
			recognizer.setTranslation(.zero, in: view)

		case .began:
			animator.removeBehavior(snap)
			pushBehavior.active = true
			print(collision.items.debugDescription)
//			animator.addBehavior(snap)
//			animator.removeBehavior(snap)
		case .cancelled, .failed:
//			recognizer.setTranslation(.zero, in: view)
			animator.addBehavior(snap)
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
				itemBehavior.elasticity = 0.5
				itemBehavior.allowsRotation = false
//				itemBehavior.addAngularVelocity(CGFloat(angle), for: productViewToTranslate)
				animator.addBehavior(itemBehavior)
			}
		case .possible:
			break
		}

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
