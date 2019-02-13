//
//  ViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DetailViewConstroller: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}


}

class SearchViewController: UIViewController {

	@IBOutlet var searchTextField: UITextField!



	override func viewDidLoad() {
		super.viewDidLoad()

	}
}

struct Strain {
	var id: Int
	var race: String
	var flavors: [String]
	var effects: [String: [String]]

}

