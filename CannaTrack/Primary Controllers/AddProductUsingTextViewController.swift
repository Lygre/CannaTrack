//
//  AddProductUsingTextViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/2/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class AddProductUsingTextViewController: UIViewController {

	@IBOutlet var strainVarietyControl: UISegmentedControl!

	@IBOutlet var strainNameTextField: UITextField!

	@IBOutlet var productTypeTextField: UITextField!

	@IBOutlet var productMassTextField: UITextField!


	var productToAdd: Product?

	var productComponentsDictionary: [String: AnyObject] = [:]

	let typeCases: [Product.ProductType] = [.capsuleBottle, .co2VapePenCartridge, .nasalSpray, .oralSyringe, .rsoSyringe, .tinctureDropletBottle, .topicalCream, .topicalLotion, .topicalSunscreen, .truClear, .truCrmbl, .truFlower, .truPod, .truShatter, .vapePenCartridge]


	//view related things
	var location = CGPoint(x: 0, y: 0)

    override func viewDidLoad() {
        super.viewDidLoad()

		let productTypePickerView = UIPickerView()

		productTypePickerView.delegate = self
		productTypeTextField.inputView = productTypePickerView
		productTypePickerView.dataSource = self

		//setup strain text field
		self.strainNameTextField.delegate = self

        // Do any additional setup after loading the view.
    }


	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {

		view.endEditing(true)
		print(productComponentsDictionary)
	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */


	@IBAction func strainVarietyControlChanged(_ sender: UISegmentedControl) {
		guard let strainVarietyTitle = sender.titleForSegment(at: sender.selectedSegmentIndex)?.lowercased() else { return }
		print(strainVarietyTitle)
		let strainVariety = StrainVariety(rawValue: strainVarietyTitle)!
		productComponentsDictionary["strainVariety"] = strainVariety as AnyObject
		switch strainVariety {
		case .hybrid:
			view.backgroundColor = .green
		case .indica:
			view.backgroundColor = .purple
		case .sativa:
			view.backgroundColor = .yellow
		}
	}


	@IBAction func saveProductTapped(_ sender: UIBarButtonItem) {
		guard let globalStrainCount = masterStrainDatabase?.count else { return }
		let strain = Strain(id: (globalStrainCount + 1), name: productComponentsDictionary["strain"] as! String, race: productComponentsDictionary["strainVariety"] as! StrainVariety, description: nil)

		let product = Product(typeOfProduct: productComponentsDictionary["productType"] as! Product.ProductType, strainForProduct: strain, inGrams: productComponentsDictionary["productMass"] as? Double ?? 0.0)
		saveProductToInventory(product: product)
		print(globalMasterInventory)

	}




}


extension AddProductUsingTextViewController {



}

extension AddProductUsingTextViewController: UIPickerViewDelegate, UIPickerViewDataSource {
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
		productComponentsDictionary["productType"] = typeCases[row] as AnyObject
		productTypeTextField.text = typeCases[row].rawValue


	}

}

extension AddProductUsingTextViewController: UITextFieldDelegate {

	func textFieldDidEndEditing(_ textField: UITextField) {
		if textField == strainNameTextField {
			guard let strainText = strainNameTextField.text else { return }
			productComponentsDictionary["strain"] = strainText as AnyObject
		} else if textField == productMassTextField {

			guard let massDouble = textField.text else { return }
			productComponentsDictionary["productMass"] = massDouble as AnyObject

		}
	}

}
