//
//  InventoryViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/20/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit



class InventoryViewController: UIViewController {

	let productCategoryCellIdentifier = "ProductCategoryCollectionViewCell"
	let inventoryCellIdentifier = "InventoryCollectionViewCell"
	let headerIdentifier = "ProductSectionHeaderView"

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
	var masterInventory: [Product]?

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

//		categoriesInInventory = [.truShatter, .truCrmbl]
		for product in globalMasterInventory {
//			if product.productLabelImage
			switch product.productType {
			case .truShatter:
				product.productLabelImage = UIImage(named: "shatter1.jpeg")
			case .truCrmbl:
				product.productLabelImage = UIImage(named: "crmbl1.jpeg")
			default:
				product.productLabelImage = UIImage(named: "cannaleaf.png")
			}

		}
		masterInventory = globalMasterInventory
		currentInventory = masterInventory
        // Do any additional setup after loading the view.
    }

	fileprivate func updateInventoryCollectionView() {
		self.productsCollectionView.performBatchUpdates({
			self.categoriesInInventory = updateCurrentInventory()
			self.productsCollectionView.reloadData()
			self.productsCollectionView.reloadSections(NSIndexSet(index: 0) as IndexSet)
		}, completion: nil)
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)


		updateInventoryCollectionView()
//		refreshUI()
		print(categoriesInInventory)
		print(currentInventory)
	}

	func updateCurrentInventory() -> [Product.ProductType] {
		self.masterInventory = globalMasterInventory
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
		guard let selectedCollectionViewCell = sender as? InventoryCollectionViewCell,
			let indexPath = productsCollectionView.indexPath(for: selectedCollectionViewCell)
			else { preconditionFailure("Expected sender to be a valid table view cell") }

		guard let productDetailViewController = segue.destination as? ProductDetailViewController
			else { preconditionFailure("Expected a ColorItemViewController") }

		// Pass over a reference to the ColorData object and the specific ColorItem being viewed.

		productDetailViewController.activeDetailProduct = currentInventory?[indexPath.row]

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

			guard let inventoryItem = currentInventory?[indexPath.row] else {
//				cell.inventoryProductLabel.text = "No Inventory"
				return cell
			}
			cell.inventoryProductLabel.text = inventoryItem.productType.rawValue
			cell.productStrainNameLabel.text = inventoryItem.strain.name
			cell.productMassRemainingLabel.text = "\(inventoryItem.mass)"
			cell.doseCountLabel.text = "\(inventoryItem.numberOfDosesTakenFromProduct)"

			//!MARK: - Generalized Cell Setup perform here
			cell.backgroundColor = .lightGray
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
			guard let masterInventory = masterInventory else { return }

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

//	func filterVisibleInventoryByCategory(completion: ([Product],Product.ProductType)->[Product]) -> [Product] {
////		var filteredProductArray: [Product] = []
//		return completion(self.currentInventory, Product.ProductType(rawValue: "truShatter"))
////		return filteredProductArray
//	}

}


extension InventoryViewController: UICollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		let sectionForCell = InventoryCollectionSection(indexPathSection: indexPath.section)

		switch sectionForCell {
		case .category:
			return CGSize(width: 100, height: 50)
		case .product:
			return CGSize(width: 120, height: 110)
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

//	override public func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//		self.productsCollectionView.collectionViewLayout.invalidateLayout()
//		super.viewWillTransition(to: size, with: coordinator)
//	}
}


/*
extension InventoryViewController: UIViewControllerPreviewingDelegate {
	func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
		<#code#>
	}

	func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
		<#code#>
	}


}
*/
