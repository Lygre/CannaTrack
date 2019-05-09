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
	func animateTouchesBegan(button: AddProductFloatingButton, animator: UIViewPropertyAnimator)
}
