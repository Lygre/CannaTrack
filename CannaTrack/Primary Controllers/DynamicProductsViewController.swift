//
//  DynamicProductsViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/15/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DynamicProductsViewController: UIViewController {


	var snap: UISnapBehavior!
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


	@objc func handlePanForProductView(recognizer: UIPanGestureRecognizer) {
		switch recognizer.state {
		case .changed:
			let translation = recognizer.translation(in: view)
			guard let productViewToTranslate = recognizer.view else { return }
			productViewToTranslate.center = CGPoint(x: productViewToTranslate.center.x + translation.x, y: productViewToTranslate.center.y + translation.y)
			recognizer.setTranslation(.zero, in: view)
		default:
			break
		}
	}

}
