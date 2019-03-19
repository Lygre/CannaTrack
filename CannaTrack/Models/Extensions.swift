//
//  Extensions.swift
//  CannaTracker
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

let testProduct1 = Product(typeOfProduct: .truShatter, strainForProduct: Strain(id: 1, name: "dick", race: .hybrid, description: "no"), inGrams: 0.5)
let testProduct2 = Product(typeOfProduct: .truCrmbl, strainForProduct: Strain(id: 2, name: "not dick", race: .indica, description: "yes"), inGrams: 0.8)

var globalMasterInventory: [Product] = [testProduct1, testProduct2]






extension UILabel {

	/// Will auto resize the contained text to a font size which fits the frames bounds.
	/// Uses the pre-set font to dynamically determine the proper sizing
	func fitTextToBounds() {
		guard let text = text, let currentFont = font else { return }

		let bestFittingFont = UIFont.bestFittingFont(for: text, in: bounds, fontDescriptor: currentFont.fontDescriptor, additionalAttributes: basicStringAttributes)
		font = bestFittingFont
	}

	private var basicStringAttributes: [NSAttributedString.Key: Any] {
		var attribs = [NSAttributedString.Key: Any]()

		let paragraphStyle = NSMutableParagraphStyle()
		paragraphStyle.alignment = self.textAlignment
		paragraphStyle.lineBreakMode = self.lineBreakMode
		attribs[.paragraphStyle] = paragraphStyle

		return attribs
	}
}

extension UIFont {

	/**
	Will return the best font conforming to the descriptor which will fit in the provided bounds.
	*/
	static func bestFittingFontSize(for text: String, in bounds: CGRect, fontDescriptor: UIFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> CGFloat {
		let constrainingDimension = min(bounds.width, bounds.height)
		let properBounds = CGRect(origin: .zero, size: bounds.size)
		var attributes = additionalAttributes ?? [:]

		let infiniteBounds = CGSize(width: CGFloat.infinity, height: CGFloat.infinity)
		var bestFontSize: CGFloat = constrainingDimension

		for fontSize in stride(from: bestFontSize, through: 0, by: -1) {
			let newFont = UIFont(descriptor: fontDescriptor, size: fontSize)
			attributes[.font] = newFont

			let currentFrame = text.boundingRect(with: infiniteBounds, options: [.usesLineFragmentOrigin, .usesFontLeading], attributes: attributes, context: nil)

			if properBounds.contains(currentFrame) {
				bestFontSize = fontSize
				break
			}
		}
		return bestFontSize
	}

	static func bestFittingFont(for text: String, in bounds: CGRect, fontDescriptor: UIFontDescriptor, additionalAttributes: [NSAttributedString.Key: Any]? = nil) -> UIFont {
		let bestSize = bestFittingFontSize(for: text, in: bounds, fontDescriptor: fontDescriptor, additionalAttributes: additionalAttributes)
		return UIFont(descriptor: fontDescriptor, size: bestSize)
	}
}
