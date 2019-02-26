//
//  AddProductViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/25/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class AddProductViewController: UIViewController {

	@IBOutlet var strainNameTextField: UITextField!

	@IBOutlet var productImageToAdd: UIImageView!

	var productToAdd: Product?

	override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

	@IBAction func unwindToInventoryCollection(unwindSegue: UIStoryboardSegue) {

	}

	@IBAction func scanToAddProductTapped(_ sender: Any) {
		let vc = UIImagePickerController()
		vc.sourceType = .camera
		vc.allowsEditing = true
		vc.delegate = self
		present(vc, animated: true)

	}



	@IBAction func saveNewProductTapped(_ sender: UIBarButtonItem) {
		guard let product = productToAdd else { return }
		saveNewProductToInventory(newProduct: product)

	}

}


extension AddProductViewController {

	func refreshUI() {
		guard let image = productToAdd?.currentProductImage else { return }
		productImageToAdd.image = image
	}

	func saveNewProductToInventory(newProduct: Product) {
		guard let inventoryViewController = self.presentingViewController as? InventoryViewController else { fatalError("could not get presenting view controller as inventory view controller") }
		inventoryViewController.currentInventory?.append(newProduct)
		
	}

}

extension AddProductViewController: UINavigationControllerDelegate, UIImagePickerControllerDelegate {

	func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
		picker.dismiss(animated: true)

		guard let image = info[.editedImage] as? UIImage else {
			print("No image found")
			return
		}

		self.productToAdd = Product(typeOfProduct: .truShatter, strainForProduct: Strain(id: 2, name: "no", race: .hybrid, description: "no"), inGrams: 1.0)
		self.productToAdd?.currentProductImage = image
		self.productImageToAdd.image = image
	}

}
