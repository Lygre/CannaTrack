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
	@IBOutlet var administrationRouteSelectorTextField: UITextField!

	unowned var multipleDoseDelegate: MultipleDoseDelegate!



    override func viewDidLoad() {
        super.viewDidLoad()
		self.productMassTextField.delegate = self
        // Do any additional setup after loading the view.

		let pickerView = UIPickerView()
		pickerView.dataSource = self
		pickerView.delegate = self
		administrationRouteSelectorTextField.inputView = pickerView

		productMassTextField.tag = 1
		administrationRouteSelectorTextField.tag = 2

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
		if textField.tag == 1 {
		massForOtherProductInDose = Double(textField.text ?? "0.0") ?? 0.0

		multipleDoseDelegate.saveCompositeDoseProductEntry(product: productForDose, mass: massForOtherProductInDose)
		self.navigationController?.popViewController(animated: true)
		print("ended editing textfield in DoseMassVC.swift. saving \(massForOtherProductInDose ?? 0) as dose mass for product")

		} else if textField.tag == 2 {
			guard let textForAdminRoute = textField.text else { return }

			guard let adminRouteFromRawValue = Dose.AdministrationRoute(rawValue: textForAdminRoute) else { return }
			multipleDoseDelegate.saveAdministrationRouteForCompositeDoseProductEntry(product: productForDose, adminRoute: adminRouteFromRawValue)
		}
	}
}


extension DoseMassViewController: UIPickerViewDelegate, UIPickerViewDataSource {
	func numberOfComponents(in pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return Dose.AdministrationRoute.allCases.count
	}

	func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return Dose.AdministrationRoute.allCases[row].rawValue
	}

	func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		administrationRouteSelectorTextField.text = Dose.AdministrationRoute.allCases[row].rawValue
	}

}



