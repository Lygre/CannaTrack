//
//  ProductDetailViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class ProductDetailViewController: UIViewController {

	var activeDetailProduct: Product!
	var dateFormatter: DateFormatter?

	@IBOutlet var productDoseLogTableView: UITableView!

	let tableCellIdentifier = "DoseCell"

	var doseArray: [Dose] = []

	@IBOutlet var productTypeLabel: UILabel!
	@IBOutlet var massRemainingLabel: UILabel!
	@IBOutlet var dateOpenedLabel: UILabel!
	@IBOutlet var doseCountLabel: UILabel!

	@IBOutlet var productLabelImageView: UIImageView!

	@IBOutlet var currentProductImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
		loadDoseCalendarInfo()
		doseArray = doseLogDictionaryGLOBAL.filter({ (someDose) -> Bool in
			return someDose.product == activeDetailProduct
		})
		dateFormatter = DateFormatter()
		guard let dateFormatter = dateFormatter else { return }
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .short
		dateFormatter.locale = Locale(identifier: "en_US")
        // Do any additional setup after loading the view.

		productDoseLogTableView.delegate = self
		productDoseLogTableView.dataSource = self
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

		dateOpenedLabel.text = {
			var dateOpened: String?
			if let date = self.activeDetailProduct.dateOpened {
				dateOpened = dateFormatter?.string(from: date)
			} else { dateOpened = "Unopened" }
			return dateOpened
		}()
		doseCountLabel.text = "\(activeDetailProduct.numberOfDosesTakenFromProduct)"
		productLabelImageView.image = activeDetailProduct.productLabelImage
		currentProductImageView.image = activeDetailProduct.currentProductImage

		productDoseLogTableView.reloadData()
	}


	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.destination is DoseViewController {
			guard let doseViewController = segue.destination as? DoseViewController else { return }
			doseViewController.productForDose = activeDetailProduct
		}
	}



	// MARK: - Supporting Peek Quick Actions

	/// - Tag: PreviewActionItems
	override var previewActionItems: [UIPreviewActionItem] {
		let doseAction = UIPreviewAction(title: "Dose with Product", style: .default, handler: { [unowned self] (_, _) in
			guard let product = self.activeDetailProduct
				else { preconditionFailure("Expected a product item") }
			let dose = Dose(timestamp: Date(), product: product, mass: 0.0, route: .inhalation)
			dose.logDoseToCalendar(dose)
			//perform action to detail item in quick action
			product.numberOfDosesTakenFromProduct += 1
			masterInventory.writeInventoryToUserData()
		})

		let openProductAction = UIPreviewAction(title: "Open Product", style: .default, handler: { [unowned self] (_, _) in
			guard let product = self.activeDetailProduct
				else { preconditionFailure("Expected a product item") }

			//perform action to detail item in quick action
			product.openProduct()
			print("product opened via quick preview action")
		})


		let deleteAction = UIPreviewAction(title: "Delete", style: .destructive) { [unowned self] (_, _) in
			guard let product = self.activeDetailProduct
				else { preconditionFailure("Expected a reference to the product data container") }

			masterInventory.removeProductFromInventoryMaster(product: product)

		}

		return [ doseAction, openProductAction, deleteAction ]
	}


	@IBAction func unwindToProduct(unwindSegue: UIStoryboardSegue) {

	}



	@IBAction func openProductTapped(_ sender: Any) {
		openDetailProduct()
	}


	@IBAction func editProductTapped(_ sender: Any) {
		editProduct()
	}


}


extension ProductDetailViewController {

	func openDetailProduct() {
		activeDetailProduct.openProduct()
		print(activeDetailProduct.dateOpened)
	}

	func editProduct() {

	}

}

extension ProductDetailViewController: UITableViewDataSource, UITableViewDelegate {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return doseArray.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier, for: indexPath) as? DoseCalendarTableViewCell else { fatalError("could not cast correctly") }

		let formatter = DateFormatter()
		formatter.dateStyle = .short
		formatter.timeStyle = .short
		cell.timeLabel.text = formatter.string(from: doseArray[indexPath.row].timestamp)

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



}
