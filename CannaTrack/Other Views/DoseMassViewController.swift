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


	@IBOutlet var productTypeLabel: UILabel!
	@IBOutlet var strainNameLabel: UILabel!
	@IBOutlet var productMassTextField: UITextField!





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

}


extension DoseMassViewController {

	func refreshUI() {
		productTypeLabel.text = productForDose.productType.rawValue
		strainNameLabel.text = productForDose.strain.name

	}

}

extension DoseMassViewController: UITextFieldDelegate {

	func textFieldDidEndEditing(_ textField: UITextField) {
		print("do nothing when text field ends editing")
	}

}
