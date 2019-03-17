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
	let ThrowingVelocityPadding: CGFloat = 35

	var originalBounds = CGRect.zero
	var originalCenter = CGPoint.zero

	var snap: UISnapBehavior!
	var attachment: UIAttachmentBehavior!
	var pushBehavior: UIPushBehavior!
	var itemBehavior: UIDynamicItemBehavior!
	var animator: UIDynamicAnimator!
	var productViewArray: [ProductView]!

    override func viewDidLoad() {
        super.viewDidLoad()
		animator = UIDynamicAnimator(referenceView: view)
		self.view.layoutIfNeeded()
		productViewArray = []

		//execute for loop here to iterate over inventory and create ProductView for each product and add it to the view hierarchy
		for product in globalMasterInventory {
			let productView = ProductView(frame: CGRect(x: self.view.frame.width / 2, y: 10, width: 50, height: 50), product: product)
			view.addSubview(productView)
			productView.center = CGPoint(x: self.view.frame.width / 2, y: -productView.frame.height)
			let origPos = view.center
			snap = UISnapBehavior(item: productView, snapTo: origPos)
			productViewArray.append(productView)
			animator.addBehavior(snap)
		}

		for productView in productViewArray {
			let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanForProductView(recognizer:)))
			productView.addGestureRecognizer(pan)
			productView.isUserInteractionEnabled = true
		}

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

	@objc func handlePanForProductView(recognizer: UIPanGestureRecognizer) {
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
			productViewToTranslate.center = attachment.anchorPoint
		}

	}

}
