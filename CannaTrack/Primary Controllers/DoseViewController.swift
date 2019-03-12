//
//  DoseViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/11/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DoseViewController: UIViewController {

	var delegate: SaveDoseDelegate?

	var productForDose: Product!
	var dateFormatter: DateFormatter?

	@IBOutlet var productTypeLabel: UILabel!
	@IBOutlet var productStrainLabel: UILabel!
	@IBOutlet var productMassLabel: UILabel!
	@IBOutlet var productDateOpenedLabel: UILabel!
	@IBOutlet var productDoseCountLabel: UILabel!
	@IBOutlet var lastDoseLabel: UILabel!
	@IBOutlet var productDoseImage: UIImageView!

	@IBOutlet var updateMassButton: UIButton!



    override func viewDidLoad() {
        super.viewDidLoad()
		dateFormatter = DateFormatter()
		dateFormatter?.dateStyle = .medium
		dateFormatter?.timeStyle = .short
		dateFormatter?.locale = Locale(identifier: "en_US")

		let tap = UITapGestureRecognizer(target: self, action: #selector(photoPrompt2))
		self.productDoseImage.addGestureRecognizer(tap)
        // Do any additional setup after loading the view.

		self.delegate = self

    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		view.backgroundColor = {
			switch self.productForDose.strain.race {
			case .hybrid:
				return .green
			case .indica:
				return .purple
			case .sativa:
				return .yellow
			}
		}()

		productTypeLabel.text = productForDose.productType.rawValue
		productStrainLabel.text = productForDose.strain.name
		productMassLabel.text = "\(productForDose.mass)g"
		productDateOpenedLabel.text = dateFormatter?.string(from: productForDose.dateOpened ?? Date())
		productDoseCountLabel.text = "\(productForDose.numberOfDosesTakenFromProduct)"
//		lastDoseLabel.text =
//		productDoseImage.image =

		updateMassButton.layer.cornerRadius = updateMassButton.frame.width / 2
		updateMassButton.layer.masksToBounds = true


	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


	// MARK: - objc Methods
	@objc func photoPrompt2() {
		let imagePicker = UIImagePickerController()
		imagePicker.sourceType = .camera
//		imagePicker.allowsEditing = true
		imagePicker.delegate = self

		self.present(imagePicker, animated: true)
	}


	//	MARK: - IBActions
	@IBAction func cancelDoseClicked(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}

	@IBAction func saveDoseClicked(_ sender: Any) {



		print("dose saved, but not really")
		dismiss(animated: true, completion: nil)
	}

	@IBAction func updateMassButtonClicked(_ sender: Any) {
		print("update mass clicked")
	}


}


extension DoseViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {

		let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage



		self.productForDose.currentProductImage = originalImage
		self.productDoseImage.image = originalImage

		dismiss(animated: true, completion: nil)

	}
}


extension DoseViewController: SaveDoseDelegate {
	func saveDoseInformation(product: Product, doseDate: Date, updatedMass: Double?, updatedProductImage: UIImage?) {
		guard let indexForProductInGlobalDB = globalMasterInventory.firstIndex(of: product) else { preconditionFailure("Expected a reference to the product data container") }
		let productInGlobal = globalMasterInventory[indexForProductInGlobalDB]
		productInGlobal.currentProductImage = productInGlobal.currentProductImage ?? productDoseImage.image
		productInGlobal.mass = updatedMass ?? productInGlobal.mass
		
	}


	

}