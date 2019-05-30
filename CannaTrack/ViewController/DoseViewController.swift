//
//  DoseViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/11/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DoseViewController: UIViewController {

	unowned var delegate: SaveDoseDelegate?

	var productForDose: Product!

	var doseMassToUpdate: Double?


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
				return UIColor(named: "hybridColor")
			case .indica:
				return UIColor(named: "indicaColor")
			case .sativa:
				return UIColor(named: "sativaColor")
			}
		}()

		productTypeLabel.text = productForDose.productType.rawValue
		productStrainLabel.text = productForDose.strain.name
		productMassLabel.text = "\(productForDose.mass)g"
		productDateOpenedLabel.text = {
			var dateOpened: String?
			if let date = self.productForDose.dateOpened {
				dateOpened = dateFormatter?.string(from: date)
			} else { dateOpened = "Unopened" }
			return dateOpened
		}()
		productDoseCountLabel.text = "\(productForDose.numberOfDosesTakenFromProduct)"
//		lastDoseLabel.text =
//		productDoseImage.image =

		updateMassButton.layer.cornerRadius = updateMassButton.frame.width / 2
		updateMassButton.layer.masksToBounds = true
		productDoseImage.clipsToBounds = true

	}


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
		if segue.destination is ProductDetailViewController {
			guard let productVC = segue.destination as? ProductDetailViewController else { fatalError("bad") }
			print(productVC.debugDescription)

		}

    }



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

//		saveDoseInformation(product: productForDose, doseDate: Date(), updatedMass: doseMassToUpdate, updatedProductImage: productDoseImage.image)
		let dose = Dose(timestamp: Date(), product: productForDose, mass: doseMassToUpdate ?? 0.0, route: .inhalation, otherProductDictionary: [:])
		CloudKitManager.shared.createCKRecord(for: dose) { (success, doseCreated, error) in
			DispatchQueue.main.async {
				if let error = error {
					let alertView = UIAlertController(title: "Dose Creation Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
					DispatchQueue.main.async {
						self.present(alertView, animated: true, completion:nil)
					}

					print(error)
				} else {
					guard let doseCreated = doseCreated else { return }
					DoseController.shared.log(dose: doseCreated)
					print(success, doseCreated, "dose saved by CKManager")
				}
			}
		}
//		dose.logDoseToCalendar(dose)
		productForDose.numberOfDosesTakenFromProduct += 1
//		CloudKitManager.shared.updateProduct(product: productForDose) { (success, updatedProduct, error) in
//			DispatchQueue.main.async {
//				if let error = error {
//					let alertView = UIAlertController(title: "Product Update Failed", error: error, defaultActionButtonTitle: "Dismiss", preferredStyle: .alert, tintColor: .GreenWebColor())
//					DispatchQueue.main.async {
//						self.present(alertView, animated: true, completion:nil)
//					}
//				} else {
//
//				}
//			}
//		}
		print("dose saved")

		self.navigationController?.popViewController(animated: true)
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

		globalMasterInventory[indexForProductInGlobalDB].currentProductImage = productDoseImage.image ?? productInGlobal.currentProductImage
		globalMasterInventory[indexForProductInGlobalDB].mass = updatedMass ?? productInGlobal.mass
		globalMasterInventory[indexForProductInGlobalDB].numberOfDosesTakenFromProduct += 1

		let dose = Dose(timestamp: doseDate, product: product, mass: updatedMass ?? 0.0, route: .inhalation)
		dose.logDoseToCalendar(dose)

	}


	

}
