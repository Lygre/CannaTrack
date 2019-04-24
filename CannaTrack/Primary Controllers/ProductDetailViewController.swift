//
//  ProductDetailViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import CloudKit

class ProductDetailViewController: UIViewController {

	var activeDetailProduct: Product!
	var recordForProduct: CKRecord?

	var dateFormatter: DateFormatter = DateFormatter()

	@IBOutlet var productDoseLogTableView: UITableView!

	@IBOutlet var productInfoSubview: UIView!

	let tableCellIdentifier = "DoseCell"

	var doseArray: [Dose] = []

	var doseCKRecords = [CKRecord]()


	let typeCases: [Product.ProductType] = [.capsuleBottle, .co2VapePenCartridge, .nasalSpray, .oralSyringe, .rsoSyringe, .tinctureDropletBottle, .topicalCream, .topicalLotion, .topicalSunscreen, .truClear, .truCrmbl, .truFlower, .truPod, .truShatter, .vapePenCartridge]

	@IBOutlet var productTypeLabel: UITextField!
	@IBOutlet var strainTextField: UITextField!
	@IBOutlet var massRemainingLabel: UITextField!
	@IBOutlet var dateOpenedLabel: UITextField!
	@IBOutlet var doseCountLabel: UILabel!

	@IBOutlet var productLabelImageView: UIImageView!

	@IBOutlet var currentProductImageView: UIImageView!

	fileprivate func setupDateFormatter(_ dateFormatter: DateFormatter) {
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .none
		dateFormatter.locale = Locale(identifier: "en_US")
	}

	fileprivate func setupTextFieldDelegates() {
		//setup text field delegates and assign to self
		self.massRemainingLabel.delegate = self
		self.productTypeLabel.delegate = self
		self.dateOpenedLabel.delegate = self
		self.strainTextField.delegate = self
	}

	@objc func handleTapOnProductImage() {
		let imagePicker = UIImagePickerController()
		imagePicker.sourceType = .camera
		imagePicker.allowsEditing = true
		imagePicker.delegate = self

		self.present(imagePicker, animated: true)

	}

	fileprivate func setupProductImageTapRecognizer() {
		let tap = UITapGestureRecognizer(target: self, action: #selector(handleTapOnProductImage))
		productLabelImageView.addGestureRecognizer(tap)
	}

	override func viewDidLoad() {
        super.viewDidLoad()
//		loadDoseCalendarInfo()
		doseArray = doseLogDictionaryGLOBAL.filter({ (someDose) -> Bool in
			return (someDose.product.productType == activeDetailProduct.productType) && (someDose.product.dateOpened == activeDetailProduct.dateOpened) && (someDose.product.strain.name == activeDetailProduct.strain.name)
		})

		queryCloudForDoseRecords()
		setupProductImageTapRecognizer()

		setupDateFormatter(dateFormatter)

		// Do any additional setup after loading the view.

		//Picker view setup
		let pickerView = UIPickerView()
		pickerView.delegate = self
		pickerView.dataSource = self


		let datePickerView = UIDatePicker()
		datePickerView.calendar = .current
		datePickerView.locale = .current
		datePickerView.timeZone = .current
		datePickerView.date = activeDetailProduct.dateOpened ?? Date()
		datePickerView.datePickerMode = .date

		datePickerView.addTarget(self, action: #selector(dateSelectedFromPicker(_:forEvent:)), for: .valueChanged)

		//setup text fields for use with pickerview
		//assign text field tags
		productTypeLabel.tag = 1
		massRemainingLabel.tag = 2
		dateOpenedLabel.tag = 3
		strainTextField.tag = 4
		//setup text field input views and keyboards
		self.productTypeLabel.inputView = pickerView
		self.massRemainingLabel.keyboardType = .numbersAndPunctuation
		self.dateOpenedLabel.inputView = datePickerView
		setupTextFieldDelegates()

		//tableview setup
		self.productDoseLogTableView.delegate = self
		self.productDoseLogTableView.dataSource = self




    }
    

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		view.backgroundColor = {
			switch self.activeDetailProduct.strain.race {
			case .hybrid:
				return UIColor(named: "hybridColor")
			case .indica:
				return UIColor(named: "indicaColor")
			case .sativa:
				return UIColor(named: "sativaColor")
			}
		}()
		navigationItem.titleView?.backgroundColor = {
			switch self.activeDetailProduct.strain.race {
			case .hybrid:
				return UIColor(named: "hybridColor")
			case .indica:
				return UIColor(named: "indicaColor")
			case .sativa:
				return UIColor(named: "sativaColor")
			}
		}()

		productTypeLabel.text = activeDetailProduct.productType.rawValue
		massRemainingLabel.text = "\(activeDetailProduct.mass)"
		strainTextField.text = activeDetailProduct.strain.name
		dateOpenedLabel.text = {
			var dateOpened: String?
			if let date = self.activeDetailProduct.dateOpened {
				dateOpened = dateFormatter.string(from: date)
			} else { dateOpened = "Unopened" }
			return dateOpened
		}()
		doseCountLabel.text = "\(activeDetailProduct.numberOfDosesTakenFromProduct)"
		productLabelImageView.image = {
			var imageToReturn: UIImage?
			if let productImage = self.activeDetailProduct.productLabelImage {
				imageToReturn = productImage
			} else {
				imageToReturn = UIImage(imageLiteralResourceName: "cannaleaf")
			}
			return imageToReturn
		}()
//		currentProductImageView.image = activeDetailProduct.currentProductImage

		productDoseLogTableView.reloadData()
	}


	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.destination is DoseViewController {
			guard let doseViewController = segue.destination as? DoseViewController else { return }
			doseViewController.productForDose = activeDetailProduct
		}
	}


	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.view.endEditing(true)

		self.productInfoSubview.endEditing(true)
		print(activeDetailProduct)
	}

	// MARK: - Supporting Peek Quick Actions

	/// - Tag: PreviewActionItems
	override var previewActionItems: [UIPreviewActionItem] {
		let doseAction = UIPreviewAction(title: "Dose with Product", style: .default, handler: { [unowned self] (_, _) in
			guard let product = self.activeDetailProduct
				else { preconditionFailure("Expected a product item") }
			guard let _ = product.dateOpened else { return }

			let dose = Dose(timestamp: Date(), product: product, mass: 0.0, route: .inhalation)
			dose.saveDoseLogToCloud()
			dose.logDoseToCalendar(dose)
			//perform action to detail item in quick action
			product.numberOfDosesTakenFromProduct += 1
			self.saveChangesToProduct()
//			product.saveProductChangesToCloud(product: product)
			masterInventory.writeInventoryToUserData()
		})

		let openProductAction = UIPreviewAction(title: "Open Product", style: .default, handler: { [unowned self] (_, _) in
			guard let product = self.activeDetailProduct
				else { preconditionFailure("Expected a product item") }

			//perform action to detail item in quick action
			product.openProduct()
			self.saveChangesToProduct()
			print("product opened via quick preview action")
		})


		let deleteAction = UIPreviewAction(title: "Delete", style: .destructive) { [unowned self] (_, _) in
			guard let product = self.activeDetailProduct
				else { preconditionFailure("Expected a reference to the product data container") }

			masterInventory.removeProductFromInventoryMaster(product: product)
			if let record = self.recordForProduct {
				self.deleteProductFromCloud(with: record)
			}
		}

		return [ doseAction, openProductAction, deleteAction ]
	}


	@IBAction func unwindToProduct(unwindSegue: UIStoryboardSegue) {

	}

	@objc func dateSelectedFromPicker(_ sender: UIDatePicker, forEvent event: UIEvent) {
		setupDateFormatter(dateFormatter)

		let dateString: String = dateFormatter.string(from: sender.date)
		dateOpenedLabel.text = dateString

	}


	@IBAction func openProductTapped(_ sender: Any) {
		openDetailProduct()
	}


	@IBAction func editProductTapped(_ sender: Any) {
		editProduct()
	}

	@IBAction func saveProductToCloudClicked(_ sender: Any) {
//		saveProductToCloud(product: activeDetailProduct)
		saveChangesToProduct()
	}



}


extension ProductDetailViewController {

	func openDetailProduct() {
		activeDetailProduct.openProduct()
		print(activeDetailProduct.dateOpened)
	}

	func editProduct() {

	}

	func deleteAction(at indexPath: IndexPath) -> UIContextualAction {

		let dose = doseArray[indexPath.row]
		let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
			let indexInGlobalDoses = doseLogDictionaryGLOBAL.firstIndex(where: { (doseCompletion) -> Bool in
				return doseCompletion === dose })
			self.doseArray.remove(at: indexPath.row)
			doseLogDictionaryGLOBAL.remove(at: indexInGlobalDoses!)
			saveDoseCalendarInfo()
			self.productDoseLogTableView.deleteRows(at: [indexPath], with: .automatic)
		}
		action.backgroundColor = .red
		return action
	}

}

extension ProductDetailViewController: UITextFieldDelegate {
	func textFieldDidEndEditing(_ textField: UITextField) {
		if textField.tag == 2 {
			let formatter = NumberFormatter()
			formatter.locale = .current
			formatter.numberStyle = .decimal
			guard let textToConvertToDouble = textField.text else { return }
			guard let number = formatter.number(from: textToConvertToDouble) else { return }
			activeDetailProduct.mass = Double(truncating: number)
			saveCurrentProductInventoryToUserData()
		} else if textField.tag == 1 {
			saveCurrentProductInventoryToUserData()
		} else if textField.tag == 3 {

			guard let dateTextFieldText = textField.text, let dateToSave = dateFormatter.date(from: dateTextFieldText) else { return }

			activeDetailProduct.dateOpened = dateToSave
			saveCurrentProductInventoryToUserData()
		}
		saveChangesToProduct()
	}

}

extension ProductDetailViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return doseCKRecords.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier, for: indexPath) as? DoseCalendarTableViewCell else { fatalError("could not cast correctly") }

//		let plistDecoder = PropertyListDecoder()
//		let data = doseCKRecords[indexPath.row]["DoseData"] as! Data
//		guard let doseDecoded = try? plistDecoder.decode(Dose.self, from: data) else { return cell }

		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		guard let date = doseCKRecords[indexPath.row].creationDate else { return cell }
		cell.timeLabel.text = formatter.string(from: date)

		cell.productLabel.text = activeDetailProduct.productType.rawValue
		cell.strainLabel.text = activeDetailProduct.strain.name
		switch activeDetailProduct.strain.race {
		case .hybrid:
			cell.backgroundColor = UIColor(named: "hybridColor")
		case .indica:
			cell.backgroundColor = UIColor(named: "indicaColor")
		case .sativa:
			cell.backgroundColor = UIColor(named: "sativaColor")
		}

		return cell
	}

	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let delete = deleteAction(at: indexPath)
		return UISwipeActionsConfiguration(actions: [delete])
	}

}


extension ProductDetailViewController: UIPickerViewDelegate, UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return typeCases.count
	}

	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return typeCases[row].rawValue
	}

	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		productTypeLabel.text = typeCases[row].rawValue
		activeDetailProduct.productType = typeCases[row]
	}

}

extension ProductDetailViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		let originalImage: UIImage = info[UIImagePickerController.InfoKey.originalImage] as! UIImage

//		self.productLabelImageView.image = originalImage
		self.activeDetailProduct.productLabelImage = originalImage

		dismiss(animated: true, completion: {
			self.saveChangesToProduct()
			saveCurrentProductInventoryToUserData()
		})

	}

}


extension ProductDetailViewController {
	fileprivate func queryCloudForDoseRecords() {

		let query = CKQuery(recordType: "Dose", predicate: NSPredicate(value: true))
		privateDatabase.perform(query, inZoneWith: nil) { (recordsRetrieved, error) in

			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					self.doseCKRecords = recordsRetrieved ?? []
					self.doseCKRecords = self.doseCKRecords.filter({ (someRecord) -> Bool in
						let plistDecoder = PropertyListDecoder()
						let data = someRecord["DoseData"] as! Data
						var dose: Dose?
						do {
							dose = try plistDecoder.decode(Dose.self, from: data)
						}
						catch {
							print(error)
						}
//						let match = self.activeDetailProduct == dose?.product
						let match = (dose?.product.productType == self.activeDetailProduct.productType) && (dose?.product.dateOpened == self.activeDetailProduct.dateOpened) && (dose?.product.strain.name == self.activeDetailProduct.strain.name)
						return match
					})
					self.productDoseLogTableView.reloadData()
					print("dose records loaded: # \(recordsRetrieved?.count) | Filtered: \(self.doseCKRecords.count)")
				}



			}
		}

	}

	fileprivate func saveChangesToProduct() {
		let record = self.recordForProduct ?? CKRecord(recordType: "Product")
		guard let recordValue = self.activeDetailProduct.encodeProductAsCKRecordValue() else { return }

		record.setObject(recordValue, forKey: "ProductData")

		let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
		let configuration = CKModifyRecordsOperation.Configuration()
		configuration.timeoutIntervalForResource = 20
		configuration.timeoutIntervalForRequest = 20
		operation.configuration = configuration

		operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {

					if self.recordForProduct != nil {
						print("Record was updated")
//						presentingVC.productsCollectionView.
					} else if let savedRecords = savedRecords {
						print("Record was saved")
					}
					self.navigationController?.popViewController(animated: true)
				}
			}

		}

		privateDatabase.add(operation)

	}


	fileprivate func deleteProductFromCloud(with record: CKRecord) {
		let recordID = record.recordID

		privateDatabase.delete(withRecordID: recordID) { (deletedRecordID, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					print("Record was deleted from ProductDetailViewController.swift method")

				}
			}
		}
	}

}
