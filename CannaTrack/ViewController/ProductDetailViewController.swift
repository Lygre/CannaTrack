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
//	var recordForProduct: CKRecord?

	var dateFormatter: DateFormatter = DateFormatter()

	@IBOutlet var productDoseLogTableView: UITableView!

	@IBOutlet var productInfoSubview: UIView!

	let tableCellIdentifier = "DoseCell"

	var doseArray: [Dose] = []

	unowned var editMassDelegate: EditMassDelegate!
	var inventoryManagerDelegate: InventoryManagerDelegate!

	var doseCKRecords = [CKRecord]()


	let typeCases: [Product.ProductType] = [.capsuleBottle, .co2VapePenCartridge, .nasalSpray, .oralSyringe, .rsoSyringe, .tinctureDropletBottle, .topicalCream, .topicalLotion, .topicalSunscreen, .truClear, .truCrmbl, .truFlower, .truPod, .truShatter, .vapePenCartridge]

	@IBOutlet var productTypeLabel: UITextField!
	@IBOutlet var strainButton: UIButton!
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
		productInfoSubview.backgroundColor = {
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
		strainButton.setTitle(activeDetailProduct.strain.name, for: .normal)
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

		productDoseLogTableView.reloadData()
	}


	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

		if segue.destination is DoseViewController {
			guard let doseViewController = segue.destination as? DoseViewController else { return }
			doseViewController.productForDose = activeDetailProduct
		} else if segue.destination is StrainDetailViewController {
			guard let strainDetailVC = segue.destination as? StrainDetailViewController else { return }
			strainDetailVC.activeDetailStrain = self.activeDetailProduct.strain
		}
	}


	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		self.view.endEditing(true)

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

//			masterInventory.removeProductFromInventoryMaster(product: product)
			/*
			//Need to re-implement new cloud delete method here, once I make it
			if let record = self.recordForProduct {
				self.deleteProductFromCloud(with: record)
			}
			*/
			/*
			CloudKitManager.shared.deleteProduct(product: product, completion: { (_, error) in
				DispatchQueue.main.async {
					if let error = error {
						print(error)
					} else {
						print("\(product) deleted from inventory")

					}
				}
			})
			*/
			CloudKitManager.shared.deleteProductUsingModifyRecords(product: product, completion: { (success, error) in
				DispatchQueue.main.async {
					if let error = error {
						print(error)
					} else {
						self.inventoryManagerDelegate.deleteProductFromLocalInventory(product: product)
						print(success, "Was a success deleting product")
					}
				}
			})
		}

		let editMassAction = UIPreviewAction(title: "Edit Mass", style: .default) { [unowned self] (_, _) in
			guard let product = self.activeDetailProduct else { preconditionFailure("Expected a reference to the product data container") }
//			guard let recordForProduct = self.recordForProduct else { preconditionFailure("Expected reference to record for product") }
			//implement presenting place to edit the mass
			guard let productRecordID = product.recordID else {
				print("got product's record ID")
				return
			}
			self.editMassDelegate.editMassForProduct(product: product, with: productRecordID)




		}

		//add edit dose mass quick action here
		
		if let _ = self.activeDetailProduct.dateOpened {
			return [ doseAction, editMassAction, deleteAction ]
		} else {
			return [ openProductAction, editMassAction, deleteAction ]
		}
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



}


extension ProductDetailViewController {

	func openDetailProduct() {
		activeDetailProduct.openProduct()
		saveChangesToProduct()
	}


	func deleteAction(at indexPath: IndexPath) -> UIContextualAction {

		let doseRecord = doseCKRecords[indexPath.row]

		let action2 = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
			let indexInRecords = self.doseCKRecords.firstIndex(of: doseRecord)
			guard let indexToRemove = indexInRecords else { return }
			self.doseCKRecords.remove(at: indexToRemove)
			self.deleteDoseRecordFromCloud(with: doseRecord)
			self.productDoseLogTableView.deleteRows(at: [indexPath], with: .automatic)
		}

		action2.backgroundColor = .red

		return action2


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
						let match = (dose?.product.productType == self.activeDetailProduct.productType) && (dose?.product.dateOpened == self.activeDetailProduct.dateOpened) && (dose?.product.strain.name == self.activeDetailProduct.strain.name)
						return match
					})
					if self.doseCKRecords.count > self.activeDetailProduct.numberOfDosesTakenFromProduct {
						self.activeDetailProduct.numberOfDosesTakenFromProduct = self.doseCKRecords.count
						self.saveChangesToProduct()
					}
					self.productDoseLogTableView.reloadData()
					print("dose records loaded: # \(recordsRetrieved?.count ?? 0) | Filtered: \(self.doseCKRecords.count)")
				}



			}
		}

	}

	fileprivate func saveChangesToProduct() {
		/*
		var record: CKRecord!
		if let productRecordID = self.activeDetailProduct.recordID {
			record = CKRecord(recordType: "Product", recordID: productRecordID)
		} else {
			record = CKRecord(recordType: "Product")
		}
//		let record = self.recordForProduct ?? CKRecord(recordType: "Product")
		guard let recordValue = self.activeDetailProduct.encodeProductAsCKRecordValue() else { return }


		let manager = FileManager.default
		let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
		let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask

		let paths = manager.urls(for: nsDocumentDirectory, in: nsUserDomainMask)

		if paths.count > 0 {
			let dirPath = paths[0]
			let writePath = dirPath.appendingPathComponent(self.activeDetailProduct.productType.rawValue + self.activeDetailProduct.strain.name + (self.activeDetailProduct.dateOpened?.description(with: .current) ?? "Unopened"))
			let productImage: UIImage = {
				let imageToReturn: UIImage = UIImage(imageLiteralResourceName: "cannaleaf.png")
				guard let image = self.activeDetailProduct.productLabelImage else { return imageToReturn }
				return image
			}()

			try? productImage.pngData()?.write(to: writePath)
			let productImageData: CKAsset? = CKAsset(fileURL: NSURL(fileURLWithPath: writePath.path) as URL)
			record.setObject(productImageData, forKey: "ProductImageData")
		}
		record.setObject(recordValue, forKey: "ProductData")


		self.navigationItem.backBarButtonItem?.isEnabled = false

		let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
		let configuration = CKModifyRecordsOperation.Configuration()
		configuration.timeoutIntervalForResource = 20
		configuration.timeoutIntervalForRequest = 20
		operation.savePolicy = .allKeys
		operation.configuration = configuration

		operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
			DispatchQueue.main.async {
				self.navigationItem.backBarButtonItem?.isEnabled = true
				if let error = error {
					print(error)
				} else {

					if self.activeDetailProduct.recordID != nil {
						print("Record was updated")
					} else if let savedRecords = savedRecords {
						print("\(savedRecords) Records were saved")
					}
					self.navigationController?.popViewController(animated: true)
				}
			}

		}
*/
		CloudKitManager.shared.updateProduct(product: self.activeDetailProduct) { (success, productUpdated, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					if success == true {
						self.navigationController?.popViewController(animated: true)
						print(productUpdated.debugDescription)
					}
				}
			}
		}

	}


	fileprivate func deleteProductFromCloud(with record: CKRecord) {
		let recordID = record.recordID

		privateDatabase.delete(withRecordID: recordID) { (deletedRecordID, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					print("Product Record was deleted from ProductDetailViewController.swift method")

				}
			}
		}
	}


	fileprivate func deleteDoseRecordFromCloud(with record: CKRecord) {
		let recordID = record.recordID

		privateDatabase.delete(withRecordID: recordID) { (deletedRecordID, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					print("Dose Record was deleted from ProductDetailViewController.swift method")
					self.productDoseLogTableView?.reloadData()

				}
			}

		}
	}

}
