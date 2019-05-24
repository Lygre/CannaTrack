//
//  UINavigationController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/24/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

extension UINavigationController {
	func pushToViewController(_ viewController: UIViewController, animated:Bool = true, completion: @escaping ()->()) {
		CATransaction.begin()
		CATransaction.setCompletionBlock(completion)
		self.pushViewController(viewController, animated: animated)
		CATransaction.commit()
	}

	func popViewController(animated:Bool = true, completion: @escaping ()->()) {
		CATransaction.begin()
		CATransaction.setCompletionBlock(completion)
		self.popViewController(animated: true)
		CATransaction.commit()
	}

	func popToViewController(_ viewController: UIViewController, animated:Bool = true, completion: @escaping ()->()) {
		CATransaction.begin()
		CATransaction.setCompletionBlock(completion)
		self.popToViewController(viewController, animated: animated)
		CATransaction.commit()
	}

	func popToRootViewController(animated:Bool = true, completion: @escaping ()->()) {
		CATransaction.begin()
		CATransaction.setCompletionBlock(completion)
		self.popToRootViewController(animated: animated)
		CATransaction.commit()
	}
}
