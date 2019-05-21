//
//  ProductsTableViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class ProductsTableViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

	let tableCellIdentifier = "ProductTableViewCell"

	var selectedProductsForDose: [Product]!
	var selectedItemIndexPaths: [IndexPath]!

	var dictionaryForProductsInDose: [Product: Double]! = [:]

	@IBOutlet var doseProductsTableView: DoseProductsTableView!

	override func viewDidLoad() {
        super.viewDidLoad()
		dictionaryForProductsInDose = Dictionary(uniqueKeysWithValues: selectedProductsForDose.lazy.map { ($0, 0.0) })

		doseProductsTableView.delegate = self
		doseProductsTableView.dataSource = self
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		doseProductsTableView.reloadData()
	}

    // MARK: - Table view data source

    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return selectedProductsForDose.count
    }


	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier, for: indexPath) as? ProductTableViewCell else { fatalError("could not instantiate ProductTableViewCell")}
		let productForCell = selectedProductsForDose[indexPath.row]
		cell.productDoseCountLabel.text = "\(productForCell.numberOfDosesTakenFromProduct)"
		cell.productStrainLabel.text = productForCell.strain.name
		cell.productTypeLabel.text = productForCell.productType.rawValue
		cell.massForProductInDoseLabel.text = String(dictionaryForProductsInDose[productForCell] ?? 0.0)
		return cell
	}

	func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
		return 50
	}

    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

	func saveCompositeDose() {
		guard let firstProductEntry = dictionaryForProductsInDose.popFirst() else { return }
		let compositeDose = Dose(timestamp: Date(), product: firstProductEntry.key, mass: firstProductEntry.value, route: .inhalation, otherProductDictionary: dictionaryForProductsInDose)

		CloudKitManager.shared.createCKRecord(for: compositeDose) { [unowned self] (success, createdDose, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					print(success, createdDose,
						  "composite dose saved to cloud")
					if success {
						self.dismiss(animated: true, completion: nil)
					}
				}
			}
		}
		
//		compositeDose.saveDoseLogToCloud()
	}

	// MARK - DO THIS NEXT

	@IBAction func saveCompositeDoseTapped(_ sender: Any) {
		//need to implement this
		saveCompositeDose()
		print("save composite dose method executed")
//		dismiss(animated: true, completion: nil)
	}


	// MARK: - Navigation

	// In a storyboard-based application, you will often want to do a little preparation before navigation

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
		let destinationVC = segue.destination
		if destinationVC is DoseMassViewController {
			guard let productTableCell = sender as? ProductTableViewCell, let indexPath = doseProductsTableView.indexPath(for: productTableCell) else { preconditionFailure("Expected sender to be a valid tableview cell") }
			guard let doseMassVC = destinationVC as? DoseMassViewController else { preconditionFailure("Expected Destination to be DoseMassVC") }


			doseMassVC.productForDose = selectedProductsForDose[indexPath.row]
			doseMassVC.massForOtherProductInDose = dictionaryForProductsInDose[selectedProductsForDose[indexPath.row]] ?? 0.0
			doseMassVC.multipleDoseDelegate = self

		} else if destinationVC is LogDoseFromCalendarViewController {
			guard let selectProductsForDoseVC = destinationVC as? LogDoseFromCalendarViewController else { return }
			selectProductsForDoseVC.selectedProductIndexPathArray = selectedItemIndexPaths
			selectProductsForDoseVC.selectedProductsForDose = selectedProductsForDose
			selectProductsForDoseVC.loadViewIfNeeded()
			//			selectProductsForDoseVC.
		}
    }


}


extension ProductsTableViewController: MultipleDoseDelegate {
	func saveCompositeDoseProductEntry(product: Product, mass: Double) {
		dictionaryForProductsInDose[product] = mass
		print("Composite entry into dict saved: \(product.strain.name) \(product.productType.rawValue) \(mass)")
	}



}
