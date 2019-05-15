//
//  AddButtonProtocol.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

protocol AddButtonDelegate: class {

	var viewPropertyAnimator: UIViewPropertyAnimator! { get set }
	var dynamicAnimator: UIDynamicAnimator! { get set }
	var snapBehavior: UISnapBehavior! { get set }

	var originalAddButtonPosition: CGPoint! { get set }

	func animateTouchesBegan(button: AddProductFloatingButton, animator: UIViewPropertyAnimator)

	func snapAddButtonToInitialPosition(button: AddProductFloatingButton, animator: UIViewPropertyAnimator, dynamicAnimator: UIDynamicAnimator)

	func setupAddButtonPanGesture(button: AddProductFloatingButton)

	//there also must be 2 objc methods to handle the Pan for the add button, and to handle the haptic feedback for it
	//@handlePanForAddButton(recognizer:) @handleHapticsForAddButton(sender:Button)


}
