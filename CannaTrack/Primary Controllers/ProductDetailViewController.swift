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



	@IBOutlet var productTypeLabel: UILabel!
	@IBOutlet var massRemainingLabel: UILabel!
	@IBOutlet var dateOpenedLabel: UILabel!
	@IBOutlet var doseCountLabel: UILabel!

	@IBOutlet var productLabelImageView: UIImageView!


    override func viewDidLoad() {
        super.viewDidLoad()
		dateFormatter = DateFormatter()
		guard let dateFormatter = dateFormatter else { return }
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .short
		dateFormatter.locale = Locale(identifier: "en_US")
        // Do any additional setup after loading the view.
    }
    

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		view.backgroundColor = {
			switch self.activeDetailProduct.strain.race {
			case .hybrid:
				return .green
			case .indica:
				return .purple
			case .sativa:
				return .yellow
			}
		}()
		navigationItem.titleView?.backgroundColor = {
			switch self.activeDetailProduct.strain.race {
			case .hybrid:
				return .green
			case .indica:
				return .purple
			case .sativa:
				return .yellow
			}
		}()

		productTypeLabel.text = activeDetailProduct.productType.rawValue
		massRemainingLabel.text = "\(activeDetailProduct.mass)"

		dateOpenedLabel.text = dateFormatter?.string(from: activeDetailProduct.dateOpened ?? Date())
		doseCountLabel.text = "\(activeDetailProduct.numberOfDosesTakenFromProduct)"
		productLabelImageView.image = activeDetailProduct.productLabelImage

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

			//perform action to detail item in quick action
			product.numberOfDosesTakenFromProduct += 1
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
			guard let productToDeleteIndex = globalMasterInventory.firstIndex(of: product) else { preconditionFailure("Expected a reference to the product data container") }
			globalMasterInventory.remove(at: productToDeleteIndex)

		}

		return [ doseAction, openProductAction, deleteAction ]
	}


	@IBAction func unwindToProduct(unwindSegue: UIStoryboardSegue) {

	}



}
