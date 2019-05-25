//
//  OrientedImageExtension.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/25/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

func createMatchingBackingDataWithImage(imageRef: CGImage?, orienation: UIImage.Orientation) -> CGImage?
{
	var orientedImage: CGImage?

	if let imageRef = imageRef {
		let originalWidth = imageRef.width
		let originalHeight = imageRef.height
		let bitsPerComponent = imageRef.bitsPerComponent
		let bytesPerRow = imageRef.bytesPerRow

		let bitmapInfo = imageRef.bitmapInfo

		guard let colorSpace = imageRef.colorSpace else {
			return nil
		}

		var degreesToRotate: Double
		var swapWidthHeight: Bool
		var mirrored: Bool
		switch orienation {
		case .up:
			degreesToRotate = 0.0
			swapWidthHeight = false
			mirrored = false
			break
		case .upMirrored:
			degreesToRotate = 0.0
			swapWidthHeight = false
			mirrored = true
			break
		case .right:
			degreesToRotate = 90.0
			swapWidthHeight = true
			mirrored = false
			break
		case .rightMirrored:
			degreesToRotate = 90.0
			swapWidthHeight = true
			mirrored = true
			break
		case .down:
			degreesToRotate = 180.0
			swapWidthHeight = false
			mirrored = false
			break
		case .downMirrored:
			degreesToRotate = 180.0
			swapWidthHeight = false
			mirrored = true
			break
		case .left:
			degreesToRotate = -90.0
			swapWidthHeight = true
			mirrored = false
			break
		case .leftMirrored:
			degreesToRotate = -90.0
			swapWidthHeight = true
			mirrored = true
			break
		}
		let radians = degreesToRotate * Double.pi / 180.0

		var width: Int
		var height: Int
		if swapWidthHeight {
			width = originalHeight
			height = originalWidth
		} else {
			width = originalWidth
			height = originalHeight
		}

		let contextRef = CGContext(data: nil, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)
		contextRef?.translateBy(x: CGFloat(width) / 2.0, y: CGFloat(height) / 2.0)
		if mirrored {
			contextRef?.scaleBy(x: -1.0, y: 1.0)
		}
		contextRef?.rotate(by: CGFloat(radians))
		if swapWidthHeight {
			contextRef?.translateBy(x: -CGFloat(height) / 2.0, y: -CGFloat(width) / 2.0)
		} else {
			contextRef?.translateBy(x: -CGFloat(width) / 2.0, y: -CGFloat(height) / 2.0)
		}
		contextRef?.draw(imageRef, in: CGRect(x: 0.0, y: 0.0, width: CGFloat(originalWidth), height: CGFloat(originalHeight)))
		orientedImage = contextRef?.makeImage()
	}

	return orientedImage
}
