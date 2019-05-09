//
//  InventoryViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/20/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import CloudKit
import Foundation




class InventoryViewController: UIViewController {

	let productCategoryCellIdentifier = "ProductCategoryCollectionViewCell"
	let inventoryCellIdentifier = "InventoryCollectionViewCell"
	let headerIdentifier = "ProductSectionHeaderView"

	var viewPropertyAnimator: UIViewPropertyAnimator!

	var animator: UIDynamicAnimator!
	var snapBehavior: UISnapBehavior!
	var itemBehavior: UIDynamicItemBehavior!


	var originalAddButtonPosition: CGPoint!

	var dateFormatter = DateFormatter()
	var activityView = UIActivityIndicatorView()

	var productCKRecords = [CKRecord]()

	var inventoryFilterOption: FilterOption = .none


	var activeCategoryDisplayed: Product.ProductType? {
		didSet {
			self.productsCollectionView.performBatchUpdates({
				self.productsCollectionView.reloadSections(NSIndexSet(index: 1) as IndexSet)
			}, completion: nil)
		}
	}


	var currentInventory: [Product]? {
		didSet {
			self.productsCollectionView.performBatchUpdates({
				self.productsCollectionView.reloadSections(NSIndexSet(index: 1) as IndexSet)
			}, completion: nil)
		}
	}

	var masterProductArray: [Product]?


	var categoriesInInventory: [Product.ProductType] = {

			let inventory = globalMasterInventory
			var categories: Set<Product.ProductType> = []
			for product in inventory {
				categories.insert(product.productType)
			}
		return Array(categories).sorted(by: { $0.rawValue < $1.rawValue })
		}()



	@IBOutlet var productsCollectionView: UICollectionView!

	@IBOutlet var filterButton: UIBarButtonItem!

	@IBOutlet var addProductButton: AddProductFloatingButton!


	fileprivate func setupActivityView() {
		activityView.center = self.view.center
		activityView.hidesWhenStopped = true
		activityView.style = .gray

		self.view.addSubview(activityView)
	}

	fileprivate func setupAddButtonPanGesture() {
		let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanForAddButton(recognizer:)))
		addProductButton.addGestureRecognizer(pan)
		addProductButton.isUserInteractionEnabled = true
	}

	fileprivate func setupDynamicItemBehavior() {
		itemBehavior = UIDynamicItemBehavior(items: [addProductButton])
		itemBehavior.resistance = 0.5
		itemBehavior.allowsRotation = true
		animator.addBehavior(itemBehavior)
	}

	override func viewDidLoad() {
        super.viewDidLoad()

		//obligatory random setup of view
		self.definesPresentationContext = true
		self.inventoryFilterOption = .none

		//assign collection delegates and datasource
		self.productsCollectionView.delegate = self
		self.productsCollectionView.dataSource = self

		//add button work here
		self.addProductButton.addButtonDelegate = self

		//haptic setup for button here
		self.addProductButton.addTarget(self, action: #selector(handleHapticsForAddButton(sender:)), for: [.backToAnchorPoint, .overEligibleContainerRegion])


		self.viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
			self.addProductButton.transform = .init(scaleX: 2.0, y: 2.0)
		})



		originalAddButtonPosition = CGPoint(x: view.frame.width - 25 - ((view.frame.width * 0.145) / 2.0), y: view.frame.height - 60 - ((view.frame.height * 0.067) / 2.0))

		setupAddButtonPanGesture()

		//dynamic animator work
		animator = UIDynamicAnimator(referenceView: self.view)
		animator.delegate = self
		snapBehavior = UISnapBehavior(item: addProductButton, snapTo: originalAddButtonPosition)
		snapBehavior.damping = 0.8
		animator.addBehavior(snapBehavior)
		
//		setupDynamicItemBehavior()


		//activity view setup and CKQuery, other
		setupActivityView()

		fetchProductCKQuerySubscriptions()

		masterProductArray = globalMasterInventory
    }

	fileprivate func stopAndFinishCurrentAnimations() {
		viewPropertyAnimator.stopAnimation(false)
		viewPropertyAnimator.finishAnimation(at: .end)
	}

	@objc func handlePanForAddButton(recognizer: UIPanGestureRecognizer) {
		let location = recognizer.location(in: self.view)
		let translation = recognizer.translation(in: self.view)

		switch recognizer.state {
		case .changed:
			addProductButton.center = CGPoint(x: addProductButton.center.x + translation.x, y: addProductButton.center.y + translation.y)
			recognizer.setTranslation(.zero, in: view)
			guard let indexPath = self.productsCollectionView.indexPathForItem(at: location), let cell = self.productsCollectionView.cellForItem(at: indexPath) else {
				print("no cell)")
				return
			}
			addProductButton.sendActions(for: .overEligibleContainerRegion)
			print("collision with \(cell.debugDescription)")
		case .began:
			stopAndFinishCurrentAnimations()
			recognizer.setTranslation(.zero, in: view)

			animator.removeBehavior(snapBehavior)

			addProductButton.center = location

		case .ended:
			recognizer.setTranslation(.zero, in: view)
			viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
				self.addProductButton.transform = .identity
			})
			viewPropertyAnimator.startAnimation()

			animator.addBehavior(snapBehavior)
			//whole lot has to be implemented here
			//have to handle checking to see if the location passes a hit test for any appropriate views in the view hierarchy

		case .cancelled, .failed:
			recognizer.setTranslation(.zero, in: view)
			viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
				self.addProductButton.transform = .identity
			})
			viewPropertyAnimator.startAnimation()
			animator.addBehavior(snapBehavior)


		case .possible:
			print("possible pan gesture state case. No implementation")
		@unknown default:
			fatalError("unknown default handling of unknown case in switch: InventoryViewController.swift")
		}

	}

	@objc func handleHapticsForAddButton(sender: AddProductFloatingButton) {
//		let selectionFeedbackGenerator: UISelectionFeedbackGenerator = .init()
//		selectionFeedbackGenerator.selectionChanged()

		let generator = UIImpactFeedbackGenerator(style: .medium)


		let targets = sender.allControlEvents
		switch targets {
		case .backToAnchorPoint:
			print("back to anchor point haptic action triggered")
			generator.impactOccurred()
		case .overEligibleContainerRegion:
			print("over eligible container region haptic action")
			generator.impactOccurred()
		default:
			generator.impactOccurred()
			print("do nothing")
		}


	}

	fileprivate func updateInventoryCollectionView() {
		self.productsCollectionView.collectionViewLayout.invalidateLayout()
		self.productsCollectionView.performBatchUpdates({
			self.categoriesInInventory = updateCurrentInventory()
			self.productsCollectionView.reloadSections(NSIndexSet(index: 0) as IndexSet)
		}, completion: nil)
	}




	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		viewPropertyAnimator.startAnimation()
		queryCloudForProductRecords()
		print(categoriesInInventory)

	}

	func updateCurrentInventory() -> [Product.ProductType] {
		if inventoryFilterOption == .none {
			self.masterProductArray = globalMasterInventory
			self.currentInventory = globalMasterInventory
		}
		let inventory = globalMasterInventory
		var categories: Set<Product.ProductType> = []
		for product in inventory {
			categories.insert(product.productType)
		}
		return Array(categories).sorted(by: { $0.rawValue < $1.rawValue })
	}









    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.destination is ProductDetailViewController {
			guard let selectedCollectionViewCell = sender as? InventoryCollectionViewCell,
				let indexPath = productsCollectionView.indexPath(for: selectedCollectionViewCell)
				else { preconditionFailure("Expected sender to be a valid table view cell") }

			guard let productDetailViewController = segue.destination as? ProductDetailViewController
				else { preconditionFailure("Expected a ColorItemViewController") }

			// Pass over a reference to the CKRecord object, Product object, and assign self as the editMassDelegate object of the productDetailVC

			let recordToPass = productCKRecords[indexPath.item]

			productDetailViewController.recordForProduct = recordToPass
			productDetailViewController.editMassDelegate = self
			productDetailViewController.activeDetailProduct = currentInventory?[indexPath.item]
		}

	}




	@IBAction func filterInventoryButtonTapped(_ sender: Any) {
		let storyboard = UIStoryboard(name: "Main", bundle: nil)
		let filterOptionsVC = storyboard.instantiateViewController(withIdentifier: filterOptionsTableViewIdentifier) as! FilterOptionsTableViewController
		filterOptionsVC.modalPresentationStyle = .popover
		filterOptionsVC.popoverPresentationController?.barButtonItem = filterButton
		filterOptionsVC.filterDelegate = self

		self.present(filterOptionsVC, animated: true) {
			print("do nothing for now")
		}

	}




}




extension InventoryViewController: UICollectionViewDelegate, UICollectionViewDataSource {


	func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 2
	}

	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard let inventory = currentInventory else { return 0 }
		return (section == 0) ? categoriesInInventory.count : inventory.count
	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)

		switch sectionForCell {
		case .category:
			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: productCategoryCellIdentifier, for: indexPath) as? ProductCategoryCollectionViewCell else { fatalError("could not instantiate category collection view cell") }

			let categoriesPresent = categoriesInInventory[indexPath.row].rawValue

			cell.categoryLabel.text = categoriesPresent

			//!MARK: - Generalized Cell Setup perform here
			cell.backgroundColor = .lightGray
			cell.layer.cornerRadius = 12
			cell.layer.masksToBounds = true

			return cell

		case .product:
			guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: inventoryCellIdentifier, for: indexPath) as? InventoryCollectionViewCell else { fatalError("could not instantiate inventory collection view cell") }

			guard let productForIndex = currentInventory?[indexPath.item] else {
//				cell.inventoryProductLabel.text = "No Inventory"
				return cell
			}
			cell.inventoryProductLabel.text = productForIndex.productType.rawValue
			cell.productStrainNameLabel.text = productForIndex.strain.name
			cell.productMassRemainingLabel.text = "\(productForIndex.mass)"
			cell.doseCountLabel.text = "\(productForIndex.numberOfDosesTakenFromProduct)"

			let dateString: String = {
				dateFormatter.timeStyle = .none
				dateFormatter.dateStyle = .short
				guard let openedProductDate = productForIndex.dateOpened else {
					return "Unopened"
				}
				return dateFormatter.string(from: openedProductDate)
			}()
			cell.dateOpenedLabel.text = dateString

			//!MARK: - Generalized Cell Setup perform here
			switch productForIndex.strain.race {
			case .hybrid:
				cell.backgroundColor = UIColor(named: "hybridColor")
			case .sativa:
				cell.backgroundColor = UIColor(named: "sativaColor")
			case .indica:
				cell.backgroundColor = UIColor(named: "indicaColor")
			}
			cell.layer.cornerRadius = 12
			cell.layer.masksToBounds = true

			return cell

		}
	}

	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		guard let supplementaryView = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerIdentifier, for: indexPath) as? ProductHeaderCollectionReusableView else { fatalError("could not cast header as ProductHeaderCollectionReusableView")}

		//!MARK: - Generalized Cell Setup perform here
		supplementaryView.backgroundColor = .cyan
		supplementaryView.layer.cornerRadius = 12
		supplementaryView.layer.masksToBounds = true

		//!MARK: - Specific view element Setup perform here
		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)
		switch sectionForCell {
		case .category:
			supplementaryView.sectionHeaderLabel.text = "Product Types in Inventory"
		case .product:
			guard let _ = activeCategoryDisplayed else {
				supplementaryView.sectionHeaderLabel.text = "No Category Selected"
				return supplementaryView
			}
			//set filtered text label option here
			supplementaryView.sectionHeaderLabel.text = activeCategoryDisplayed.map { $0.rawValue }
		}
		return supplementaryView
	}


	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)
		switch sectionForCell {
		case .category:
			activeCategoryDisplayed = categoriesInInventory[indexPath.row]
			//reuse this following code to filter
			let masterInventory = globalMasterInventory

			currentInventory = masterInventory.filter({ (productType) -> Bool in
					productType.productType == activeCategoryDisplayed
				})
		case .product:
			print("do nothing")
		}

	}


	enum InventoryCollectionSection: Int {
		case category = 0
		case product = 1
		init(indexPathSection: Int) {
			switch indexPathSection {
			case 0:
				self = .category
			case 1:
				self = .product
			default:
				self = .category
			}
		}
	}

}


extension InventoryViewController {

	func refreshUI() {
		loadViewIfNeeded()
		productsCollectionView.reloadData()
	}





	fileprivate func queryCloudForProductRecords() {
		let query = CKQuery(recordType: "Product", predicate: NSPredicate(value: true))
		self.activityView.startAnimating()
		privateDatabase.perform(query, inZoneWith: nil) { (recordsRetrieved, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					self.productCKRecords = recordsRetrieved ?? []
					var productObjectsArray: [Product] = []
					for record in self.productCKRecords {
						let propertyListDecoder = PropertyListDecoder()
						do {
							let data = record["ProductData"] as! Data
							let productToAdd = try propertyListDecoder.decode(Product.self, from: data)

							guard let asset = record["ProductImageData"] as? CKAsset else {
								print("Image Missing from Record")
								return
							}
							guard let imageData = NSData(contentsOf: asset.fileURL!) else {
								print("Invalid Image")
								return
							}
							let image = UIImage(data: imageData as Data)
							productToAdd.productLabelImage = image
							productObjectsArray.append(productToAdd)
						}
						catch { print(error) }
					}
					globalMasterInventory = productObjectsArray
					self.updateInventoryCollectionView()
					self.activityView.stopAnimating()
					print("product records loaded: # \(recordsRetrieved?.count ?? 0)")
				}
			}
		}

	}

	func deleteProductFromCloud(product: Product) {
		guard let recordID = product.recordID else { return }

		privateDatabase.delete(withRecordID: recordID) { (deletedRecordID, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					print("Record was deleted from InventoryViewController.swift method")
					guard let indexPathForRecordToRemove = self.productCKRecords.firstIndex(of: CKRecord(recordType: "Product", recordID: recordID)) else { return }
					self.productCKRecords.remove(at: indexPathForRecordToRemove)
					self.updateInventoryCollectionView()
				}
			}
		}
	}

	//!!MARK -- CKSubscription work

	func fetchProductCKQuerySubscriptions() {

		let _: [CKSubscription.ID] = ["product-changes"]

		privateDatabase.fetchAllSubscriptions { (subscriptions, error) in
			DispatchQueue.main.async {
				if error == nil {
					if let subscriptions = subscriptions {
						if subscriptions.isEmpty {
							self.setupProductCKQuerySubscription()
						} else {
							print("\(subscriptions.debugDescription) retrieved")
						}
						//more code to come!

					}
				} else {
					print(error!.localizedDescription)
				}
			}
		}

	}

	func setupProductCKQuerySubscription() {
		let predicate = NSPredicate(value: true)
		let subscription = CKQuerySubscription(recordType: "Product", predicate: predicate, subscriptionID: "product-changes", options: [CKQuerySubscription.Options.firesOnRecordCreation, CKQuerySubscription.Options.firesOnRecordUpdate, CKQuerySubscription.Options.firesOnRecordDeletion])


		let config = CKModifySubscriptionsOperation.Configuration()
		config.timeoutIntervalForRequest = 20
		config.timeoutIntervalForResource = 20


		let notification = CKSubscription.NotificationInfo()
		notification.alertBody = "There's a new product in Inventory"
		notification.soundName = "default"
		notification.shouldSendContentAvailable = true

		subscription.notificationInfo = notification
		config.qualityOfService = .utility

		privateDatabase.save(subscription) { (subscription, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error.localizedDescription)
				} else {
					print("Subscription Saved to Server from InventoryViewController.swift!")
				}
			}
		}


	}
}


extension InventoryViewController: UICollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)

		switch sectionForCell {
		case .category:
			return CGSize(width: 100, height: 50)
		case .product:
			return CGSize(width: 120, height: 120)
		}
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
	}

}

extension InventoryViewController: InventoryFilterDelegate {
	func filterInventory(using filterOption: FilterOption) {
		//not implemented

		var masterInventory = globalMasterInventory
		self.inventoryFilterOption = filterOption
		switch filterOption {

		case .dateOpened:
			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				return someProduct.dateOpened != nil
			})
			self.currentInventory?.sort(by: { (productOne, productTwo) -> Bool in
				return productOne.dateOpened! < productTwo.dateOpened!
			})
			filterButton?.tintColor = .red
			print("sorting by date Opened")
		case .lastDoseTime:
			//				self.currentInventory?.filter(<#T##isIncluded: (Product) throws -> Bool##(Product) throws -> Bool#>)
			print("not implemented")
		case .massRemaining:
			masterInventory.sort(by: { (productOne, productTwo) -> Bool in
				return productOne.mass < productTwo.mass
			})
			self.currentInventory = masterInventory

			filterButton?.tintColor = .red
			print("filtering based on remaining mass")
		case .numberOfDoses:
			self.currentInventory = masterInventory.sorted { (productOne, productTwo) -> Bool in
				return productOne.numberOfDosesTakenFromProduct < productTwo.numberOfDosesTakenFromProduct
			}

			filterButton?.tintColor = .red
			print("Sorting based on Number of Doses")
		case .openedStatus:

			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				guard let _ = someProduct.dateOpened else { return false }
				return true
			})

			filterButton?.tintColor = .red
			print("filtered based on open status")
		case .strainVarietyIndica:
			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				return someProduct.strain.race == .indica
			})

			filterButton?.tintColor = .red

			print("filtering to show only indica products")
		case .strainVarietySativa:
			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				return someProduct.strain.race == .sativa
			})

			filterButton?.tintColor = .red

			print("filtering to show only indica products")
		case .strainVarietyHybrid:
			self.currentInventory = masterInventory.filter({ (someProduct) -> Bool in
				return someProduct.strain.race == .hybrid
			})

			filterButton?.tintColor = .red

			print("filtering to show only indica products")
		case .none:
			self.currentInventory = masterInventory

			filterButton?.tintColor = .blue
			print("Filtering with None")

		}


	}



}



extension InventoryViewController: EditMassDelegate {
	func editMassForProduct(product: Product, with record: CKRecord) {
		DispatchQueue.main.async {
			let massEditView = UIAlertController(title: "Edit Mass \(product.productType.rawValue) \(product.strain.name)", message: "Enter updated mass value in grams", preferredStyle: .alert)
			massEditView.addTextField(configurationHandler: nil)
			let confirmMassEditAction = UIAlertAction(title: "Confirm", style: .default, handler: { [unowned self] (_) in
				product.mass = Double(massEditView.textFields?.first!.text ?? "0.0") ?? 0.0
				self.saveChangesToProduct(product: product, record: record)
			})
			let cancelMassEditAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
			massEditView.addAction(confirmMassEditAction)
			massEditView.addAction(cancelMassEditAction)

			self.present(massEditView, animated: true, completion: nil)
		}

	}

	func saveChangesToProduct(product: Product, record: CKRecord) {
		guard let recordValue = product.encodeProductAsCKRecordValue() else { return }

		let manager = FileManager.default
		let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
		let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask

		let paths = manager.urls(for: nsDocumentDirectory, in: nsUserDomainMask)

		if paths.count > 0 {
			let dirPath = paths[0]
			let writePath = dirPath.appendingPathComponent(product.productType.rawValue + product.strain.name + (product.dateOpened?.description(with: .current) ?? "Unopened"))
			let productImage: UIImage = {
				let imageToReturn: UIImage = UIImage(imageLiteralResourceName: "cannaleaf.png")
				guard let image = product.productLabelImage else { return imageToReturn }
				return image
			}()

			try? productImage.pngData()?.write(to: writePath)
			let productImageData: CKAsset? = CKAsset(fileURL: NSURL(fileURLWithPath: writePath.path) as URL)
			record.setObject(productImageData, forKey: "ProductImageData")
		}
		record.setObject(recordValue, forKey: "ProductData")
		let operation = CKModifyRecordsOperation(recordsToSave: [record], recordIDsToDelete: nil)
		let configuration = CKModifyRecordsOperation.Configuration()
		configuration.timeoutIntervalForResource = 20
		configuration.timeoutIntervalForRequest = 20
		operation.configuration = configuration

		operation.modifyRecordsCompletionBlock = { (savedRecords, deletedRecordIDs, error) in
			DispatchQueue.main.async {
				self.navigationItem.backBarButtonItem?.isEnabled = true
				if let error = error {
					print(error)
				} else {
					if let savedRecords = savedRecords {
						self.updateInventoryCollectionView()
						print("\(savedRecords) Records were saved")
					}
				}
			}

		}

		privateDatabase.add(operation)


	}


}








extension InventoryViewController: AddButtonDelegate {
	func animateTouchesBegan(button: AddProductFloatingButton, animator: UIViewPropertyAnimator) {
		viewPropertyAnimator = animator
		viewPropertyAnimator.startAnimation()
//		button.frame = CGRect(x: button.frame.minX, y: button.frame.maxY, width: button.frame.width * 2, height: button.frame.height * 2)
	}



}


extension InventoryViewController: UIDynamicAnimatorDelegate {

	func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {

		guard let button = animator.items(in: self.view.frame).first as? AddProductFloatingButton else {
			print("There is no button; not able to be cast as The Button, anyway")
			return
		}

		button.sendActions(for: .backToAnchorPoint)
	}

}
