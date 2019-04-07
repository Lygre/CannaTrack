//
//  LogDoseFromCalendarViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/5/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class LogDoseFromCalendarViewController: UIViewController {

	let collectionCellIdentifier = "InventoryCollectionViewCell"
	let tableViewCellIdentifier = "ProductTableViewCell"

	@IBOutlet var productsCollectionView: UICollectionView!

	@IBOutlet var nextButton: UIBarButtonItem!

	let sectionInsets = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

	var selectedProductIndexPathArray: [IndexPath] = []
	var selectedProductsForDose: [Product] = []

	var largeProductIndexPath: IndexPath? {
		didSet {
			var indexPaths = [IndexPath]()
			if let largeProductIndexPath = largeProductIndexPath {
				indexPaths.append(largeProductIndexPath)
			}
			if let oldValue = oldValue {
				indexPaths.append(oldValue)
			}
			productsCollectionView.performBatchUpdates({
				self.productsCollectionView.reloadItems(at: indexPaths)
			}) { (completed) in
				if let largeProductIndexPath = self.largeProductIndexPath {
					self.productsCollectionView.scrollToItem(at: largeProductIndexPath, at: .centeredVertically, animated: true)
				}
			}
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		productsCollectionView.allowsMultipleSelection = true
        // Do any additional setup after loading the view.
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		productsCollectionView.collectionViewLayout.invalidateLayout()
		productsCollectionView.reloadData()
	}


    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {

		if segue.destination is ProductsTableViewController {
			guard let productsTableVC = segue.destination as? ProductsTableViewController else { return }
			productsTableVC.selectedProductsForDose = selectedProductsForDose
			productsTableVC.loadViewIfNeeded()
		}

    }



}


extension LogDoseFromCalendarViewController: UICollectionViewDelegate {

	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		let productForDose = globalMasterInventory[indexPath.item]

		selectedProductIndexPathArray.append(indexPath)
		selectedProductsForDose.append(productForDose)
		nextButton.isEnabled = selectedProductsForDose.isEmpty ? false : true
	}

	func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
		let productForDose = globalMasterInventory[indexPath.item]
		guard let index = selectedProductIndexPathArray.firstIndex(of: indexPath) else { return }
		guard let indexOfProduct = selectedProductsForDose.firstIndex(of: productForDose) else { return }
		selectedProductsForDose.remove(at: indexOfProduct)
		selectedProductIndexPathArray.remove(at: index)
		nextButton.isEnabled = selectedProductsForDose.isEmpty ? false : true
	}

//	func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
//		if largeProductIndexPath == indexPath {
//			largeProductIndexPath = nil
//		} else {
//			largeProductIndexPath = indexPath
//		}
//		return false
//	}


}


extension LogDoseFromCalendarViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return globalMasterInventory.count
		//this will probably crash the app one day

	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: collectionCellIdentifier, for: indexPath) as? InventoryCollectionViewCell else { fatalError("could not cast as Inventory Collection View Cell") }

		cell.inventoryProductLabel.text = globalMasterInventory[indexPath.row].productType.rawValue
		cell.productStrainNameLabel.text = globalMasterInventory[indexPath.row].strain.name
		cell.productMassRemainingLabel.text = "\(globalMasterInventory[indexPath.row].mass)"
		cell.doseCountLabel.text = "\(globalMasterInventory[indexPath.row].numberOfDosesTakenFromProduct)"

		for view in cell.subviews {
			view.backgroundColor = .clear
		}

		switch globalMasterInventory[indexPath.row].strain.race {
		case .hybrid:
			cell.backgroundColor = .green
		case .indica:
			cell.backgroundColor = .purple
		case .sativa:
			cell.backgroundColor = .yellow
		}

		cell.layer.cornerRadius = cell.frame.width / 5
		cell.layer.masksToBounds = true

		return cell
	}


}




extension LogDoseFromCalendarViewController: UICollectionViewDelegateFlowLayout {

	fileprivate func handleResizingSelectedCell(_ indexPath: IndexPath) -> CGSize {
		if indexPath == largeProductIndexPath {
			var size = productsCollectionView.bounds.size
			size.height -= (sectionInsets.top + sectionInsets.bottom)
			size.width -= (sectionInsets.left + sectionInsets.right)
			return sizeToFillWidth(of: size)
		} else {
			return CGSize(width: 120, height: 120)
		}
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {


		return CGSize(width: 120, height: 120)
//		return handleResizingSelectedCell(indexPath)

	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
	}

}




extension LogDoseFromCalendarViewController {

	func sizeToFillWidth(of size:CGSize) -> CGSize {


		let imageSize = size
		var returnSize = size

		let aspectRatio = imageSize.width / imageSize.height

		returnSize.height = returnSize.width / aspectRatio

		if returnSize.height > size.height {
			returnSize.height = size.height
			returnSize.width = size.height * aspectRatio
		}

		return returnSize
	}

}



