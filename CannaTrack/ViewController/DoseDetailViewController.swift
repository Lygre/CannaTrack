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

		setupDateFormatter()

		loadViewIfNeeded()

		setupTextFieldPickerViews()




		timestampTextField.text = dateFormatter.string(from: activeDetailDose.timestamp)
		productTextField.text = activeDetailDose.product.strain.name + " " + activeDetailDose.product.productType.rawValue
		massTextField.text = "\(activeDetailDose.mass ?? 0.0)"
		administrationRouteTextField.text = activeDetailDose.administrationRoute.map { $0.rawValue }

		doseDetailTextFieldCollection = doseDetailTextFieldCollection.compactMap({ (textField) -> UITextField in
			textField.borderWidth = 3
			textField.borderColor = .clear
			return textField
		})

        // Do any additional setup after loading the view.
		guard let doseImage = activeDetailDose.doseImage else {
			print("no image for dose")
			return
		}
		doseImageView.image = {
			var imageToReturn: UIImage?
			if let doseImage = self.activeDetailDose.doseImage {
				imageToReturn = doseImage

				let cgImageToGetOrientedUIImage: CGImage? = doseImage.cgImage
				let orientedCGImage: CGImage? = createMatchingBackingDataWithImage(imageRef: cgImageToGetOrientedUIImage, orienation: .up)
				guard let orientedCGImageUnwrapped = orientedCGImage else {
					return imageToReturn
				}
				let correctedUIImage: UIImage = UIImage(cgImage: orientedCGImageUnwrapped, scale: 1.0, orientation: .right)
				imageToReturn = correctedUIImage
				self.activeDetailDose.doseImage = correctedUIImage
			} else {
				imageToReturn = UIImage(imageLiteralResourceName: "cannaleaf.png")
			}
			return imageToReturn
		}()

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
				UIView.animate(withDuration: 1, animations: {
					textField.backgroundColor = .GreenWebColor()
					textField.borderColor = UIColor(named: "sativaColor")
				})
				textField.isEnabled = true
				textField.isUserInteractionEnabled = true
				textField.clearButtonMode = .whileEditing
			} else {
				UIView.animate(withDuration: 1, animations: {
					textField.backgroundColor = UIColor(named: "sativaColor")
					textField.borderColor = .clear
				})
				textField.isEnabled = false
				textField.isUserInteractionEnabled = false
				textField.clearButtonMode = .never
			}
			return textField
		}

	}



}


//MARK: -- Helper methods
extension DoseDetailViewController {

	fileprivate func setupDateFormatter() {
		dateFormatter.dateFormat = "MMMM dd yyy"
		dateFormatter.timeZone = Calendar.current.timeZone
		dateFormatter.calendar = .current
		dateFormatter.locale = .current
	}

	fileprivate func setupTextFieldPickerViews() {
		//prepare for the text fields that need picker views
		productTextField.tag = 1
		massTextField.tag = 2
		administrationRouteTextField.tag = 3

		let productPickerView = UIPickerView()
		productPickerView.tag = 1
		productPickerView.delegate = self
		productPickerView.dataSource = self
		productPickerView.showsSelectionIndicator = true

		productTextField.inputView = productPickerView

		massTextField.keyboardType = .decimalPad

		let administrationRoutePickerView = UIPickerView()
		administrationRoutePickerView.tag = 2
		administrationRoutePickerView.delegate = self
		administrationRoutePickerView.dataSource = self
		administrationRoutePickerView.showsSelectionIndicator = true
		administrationRouteTextField.inputView = administrationRoutePickerView
	}


}


//MARK: -- Text Field Delegate conformance
extension DoseDetailViewController: UITextFieldDelegate {

	func textFieldDidEndEditing(_ textField: UITextField) {

	}
}


//MARK: -- PickerView Delegate and Data Source
extension DoseDetailViewController: UIPickerViewDataSource, UIPickerViewDelegate {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		switch pickerView.tag {
		case 1:
			return 2
		case 2:
			return 1
//		case 3:
		default:
			return 0
			print("tag switch not implemented on this picker view")
		}
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		switch pickerView.tag {
		case 1:
			switch component {
			case 0:
				return 1
			case 1:
				return Product.ProductType.allCases.count
			default:
				return 0
				print("other components not implemented")
			}
		case 2:
			return Dose.AdministrationRoute.allCases.count
		default:
			return 0
			print("other pickerView not implemented")
		}
	}

	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		switch pickerView.tag {
		case 1:
			switch component {
			case 0:
				return "Nothing yet"
			case 1:
				return Product.ProductType.allCases[row].rawValue
			default:
				return "Nothing"
			}
		case 2:
			return Dose.AdministrationRoute.allCases[row].rawValue
		default:
			return "Nothing nothing"
		}
	}

}
