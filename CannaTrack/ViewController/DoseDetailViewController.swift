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

	let dateFormatter = DateFormatter()

	@IBOutlet var doseImageView: UIImageView!

	@IBOutlet var timestampTextField: UITextField!
	@IBOutlet var productTextField: UITextField!
	@IBOutlet var massTextField: UITextField!
	@IBOutlet var administrationRouteTextField: UITextField!
	@IBOutlet var otherProductTextField: UITextField!

	@IBOutlet var doseDetailTextFieldCollection: [UITextField]!

    override func viewDidLoad() {
        super.viewDidLoad()

		dateFormatter.dateFormat = "yyy MM dd"
		dateFormatter.timeZone = Calendar.current.timeZone
		dateFormatter.calendar = .current
		dateFormatter.locale = .current

		loadViewIfNeeded()

		timestampTextField.text = dateFormatter.string(from: activeDetailDose.timestamp)
		productTextField.text = activeDetailDose.product.strain.name + " " + activeDetailDose.product.productType.rawValue
		massTextField.text = "\(activeDetailDose.mass ?? 0.0) g"
		administrationRouteTextField.text = activeDetailDose.administrationRoute.map { $0.rawValue }
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

	@IBAction func editDoseDetaiTapped(_ sender: UIBarButtonItem) {
		doseDetailTextFieldCollection = doseDetailTextFieldCollection.compactMap { (textField) -> UITextField in
			if !textField.isEnabled {
				textField.backgroundColor = .GreenWebColor()
				textField.isEnabled = true
				textField.isUserInteractionEnabled = true
			} else {
				textField.backgroundColor = UIColor(named: "sativaColor")
				textField.isEnabled = false
				textField.isUserInteractionEnabled = false
			}
			return textField
		}

	}



}
