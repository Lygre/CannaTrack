//
//  DoseMassViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/19/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DoseMassViewController: UIViewController {


	var productForDose: Product!
	var massForOtherProductInDose: Double!

	@IBOutlet var productTypeLabel: UILabel!
	@IBOutlet var strainNameLabel: UILabel!
	@IBOutlet var productMassTextField: UITextField!

	var multipleDoseDelegate: MultipleDoseDelegate!



    override func viewDidLoad() {
        super.viewDidLoad()
		self.productMassTextField.delegate = self
        // Do any additional setup after loading the view.
    }


	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		refreshUI()
	}

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
		let destinationVC = segue.destination
		if destinationVC is ProductsTableViewController {
			guard let productsTableVCForDose = destinationVC as? ProductsTableViewController else { return }
			productsTableVCForDose.dictionaryForProductsInDose[productForDose] = massForOtherProductInDose
		}

    }


	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		view.endEditing(true)
	}

}


extension DoseMassViewController {

	func refreshUI() {
		loadViewIfNeeded()
		productTypeLabel.text = productForDose.productType.rawValue
		strainNameLabel.text = productForDose.strain.name
		productMassTextField.text = String(massForOtherProductInDose)

	}

}

extension DoseMassViewController: UITextFieldDelegate {

	func textFieldDidEndEditing(_ textField: UITextField) {
		massForOtherProductInDose = Double(textField.text ?? "0.0") ?? 0.0

		multipleDoseDelegate.saveCompositeDoseProductEntry(product: productForDose, mass: massForOtherProductInDose)
		self.navigationController?.popViewController(animated: true)
//		guard let productTableVC = self.presentingViewController as? ProductsTableViewController else { return }
//		productTableVC.dictionaryForProductsInDose[productForDose] = massForOtherProductInDose
		print("ended editing textfield in DoseMassVC.swift. saving \(massForOtherProductInDose) as dose mass for product")
	}

}





protocol MultipleDoseDelegate {
	func saveCompositeDoseProductEntry(product: Product, mass: Double)
}
