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

	var strainsArray: [Strain]?
	var effectsArray: [Effects]?
	var url = "https://strainapi.evanbusse.com/oJ5GvWc/strains/search/name/"
	let urlForEffectsSearch = "https://strainapi.evanbusse.com/oJ5GvWc/searchdata/effects/"

	@IBOutlet var searchTextField: UITextField!

	override func viewDidLoad() {
		super.viewDidLoad()





	}

	func searchWeed(using strainString: String) -> [Strain] {
		var strainMatches: [Strain]?



		return strainMatches!
	}

	func searchStrains(using effect: String) {
		url = "https://strainapi.evanbusse.com/oJ5GvWc/strains/search/name/" + String("\(effect)").trimmingCharacters(in: .whitespaces)
		guard let urlObj = URL(string: url) else { return }

		URLSession.shared.dataTask(with: urlObj) {(data, response, error) in

			guard let data = data else { return }

			do {
				self.strainsArray = try JSONDecoder().decode([Strain].self, from: data)
				print("data parsed from strain database")
			} catch let jsonError {
				print("Error serializing json: ", jsonError)
			}

			}.resume()
	}

	func refreshUI() {
		loadViewIfNeeded()
		print(strainsArray)
	}

	@IBAction func searchClicked(_ sender: UIButton) {
		guard let strainSearchString = searchTextField.text else { return }
		searchStrains(using: strainSearchString)
	}

	@IBAction func reloadView(_ sender: Any) {
		refreshUI()
	}



}

struct Strain: Decodable {

	let id: Int
	let name: String
	let race: String
	let desc: String?
//	let flavors: String?
//	let effects: [String: [String]]?

//	let strain: [String]

}



struct Effects: Decodable {
	let effect: String
	let type: String
}

