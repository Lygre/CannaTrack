//
//  ProductPreviewViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 6/16/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class ProductPreviewViewController: UIViewController {

	private let imageView = UIImageView()

	override func loadView() {
		view = imageView
	}

	init(product: Product) {
		super.init(nibName: nil, bundle: nil)
		imageView.clipsToBounds = true
		imageView.contentMode = .scaleAspectFill
		imageView.image = {
			var imageToReturn: UIImage?
			if let productImage = product.productLabelImage {
				imageToReturn = productImage

				let cgImageToGetOrientedUIImage: CGImage? = productImage.cgImage
				let orientedCGImage: CGImage? = createMatchingBackingDataWithImage(imageRef: cgImageToGetOrientedUIImage, orienation: .up)
				guard let orientedCGImageUnwrapped = orientedCGImage else {
					return imageToReturn
				}
				let correctedUIImage: UIImage = UIImage(cgImage: orientedCGImageUnwrapped, scale: 1.0, orientation: .right)
				imageToReturn = correctedUIImage
				product.productLabelImage = correctedUIImage
			} else {
				imageToReturn = UIImage(imageLiteralResourceName: "cannaleaf.png")
			}
			return imageToReturn
		}()

		preferredContentSize = product.productLabelImage?.size ?? CGSize(width: 200, height: 200)
	}

	required init?(coder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
