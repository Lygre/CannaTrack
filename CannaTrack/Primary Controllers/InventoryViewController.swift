//
//  InventoryViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/20/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import CloudKit


class InventoryViewController: UIViewController {

	let productCategoryCellIdentifier = "ProductCategoryCollectionViewCell"
	let inventoryCellIdentifier = "InventoryCollectionViewCell"
	let headerIdentifier = "ProductSectionHeaderView"


	var dateFormatter = DateFormatter()


	var productCKRecords = [CKRecord]()

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

    override func viewDidLoad() {
        super.viewDidLoad()

		self.productsCollectionView.delegate = self
		self.productsCollectionView.dataSource = self

//		for product in globalMasterInventory {
//			switch product.productType {
//			case .truShatter:
//				product.productLabelImage = UIImage(named: "shatter1.jpeg")
//			case .truCrmbl:
//				product.productLabelImage = UIImage(named: "crmbl1.jpeg")
//			default:
//				product.productLabelImage = UIImage(named: "cannaleaf.png")
//			}
//
//		}
		masterProductArray = globalMasterInventory
		currentInventory = masterProductArray
        // Do any additional setup after loading the view.
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

		queryCloudForProductRecords()
//		updateInventoryCollectionView()
//		refreshUI()
		print(categoriesInInventory)
		print(currentInventory)
	}

	func updateCurrentInventory() -> [Product.ProductType] {
		self.masterProductArray = globalMasterInventory
		self.currentInventory = globalMasterInventory
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

			// Pass over a reference to the ColorData object and the specific ColorItem being viewed.
			let recordToPass = productCKRecords[indexPath.row]

			productDetailViewController.recordForProduct = recordToPass

			productDetailViewController.activeDetailProduct = currentInventory?[indexPath.row]
		}

	}



	@IBAction func saveInventoryToCloudClicked(_ sender: Any) {
		saveInventoryToCloud(inventory: masterInventory)

	}

	@IBAction func loadInventoryFromCloudClicked(_ sender: Any) {
//		queryCloudDatabase()
		fetchInventoryFromCloud()
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

			guard let productForIndex = currentInventory?[indexPath.row] else {
//				cell.inventoryProductLabel.text = "No Inventory"
				return cell
			}
//			let data = productCKRecords[indexPath.row]["ProductData"] as! Data
//			let properyListDecoder = PropertyListDecoder()
//			guard let productForIndex = try? properyListDecoder.decode(Product.self, from: data) else { return cell }

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
			guard let activeCategory = activeCategoryDisplayed else {
				supplementaryView.sectionHeaderLabel.text = "No Category Selected"
				return supplementaryView
			}
			supplementaryView.sectionHeaderLabel.text = activeCategoryDisplayed.map { $0.rawValue }
		}


		return supplementaryView
	}


	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)
		switch sectionForCell {
		case .category:
			activeCategoryDisplayed = categoriesInInventory[indexPath.row]
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
							productObjectsArray.append(productToAdd)
						}
						catch { print(error) }
					}
					globalMasterInventory = productObjectsArray
					self.updateInventoryCollectionView()
					print("product records loaded: # \(recordsRetrieved?.count)")
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


