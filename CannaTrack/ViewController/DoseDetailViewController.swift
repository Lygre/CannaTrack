//
//  DoseDetailViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 6/1/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DoseDetailViewController: UIViewController {


	var activeDetailDose: Dose!


	@IBOutlet var doseImageView: UIImageView!



    override func viewDidLoad() {
        super.viewDidLoad()


		loadViewIfNeeded()

        // Do any additional setup after loading the view.
		guard let doseImage = activeDetailDose.doseImage else {
			print("no image for dose")
			return
		}
		doseImageView.image = doseImage
			/*
			{
			var imageToReturn: UIImage?
			if let productImage = self.activeDetailDose.doseImage {
				imageToReturn = productImage

				let cgImageToGetOrientedUIImage: CGImage? = productImage.cgImage
				let orientedCGImage: CGImage? = createMatchingBackingDataWithImage(imageRef: cgImageToGetOrientedUIImage, orienation: .up)
				guard let orientedCGImageUnwrapped = orientedCGImage else {
					return imageToReturn
				}
				let correctedUIImage: UIImage = UIImage(cgImage: orientedCGImageUnwrapped, scale: 1.0, orientation: .right)
				imageToReturn = correctedUIImage
//				self.activeDetailDose.doseImage = correctedUIImage
			} else {
				imageToReturn = UIImage(imageLiteralResourceName: "cannaleaf")
			}
			return imageToReturn
		}()
*/
    }
    


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }


}
