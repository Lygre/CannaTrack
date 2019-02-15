//
//  ViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DetailViewConstroller: UIViewController {

	var activeDetailStrain: Strain?


	@IBOutlet var idLabel: UILabel!

	@IBOutlet var strainNameLabel: UILabel!

	@IBOutlet var strainRaceLabel: UILabel!

	@IBOutlet var strainDescriptionLabel: UILabel!


	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view.
	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		guard let activeStrain = activeDetailStrain else { fatalError("no strain set to active")}
		refreshUI()

	}



	func refreshUI() {
		loadViewIfNeeded()
		guard let currentStrain = activeDetailStrain else { fatalError("no current strain") }
		idLabel.text = "\(currentStrain.id)"
		strainNameLabel.text = currentStrain.name
		strainRaceLabel.text = currentStrain.race
		strainDescriptionLabel.text = currentStrain.desc ?? "No Description Available"
	}




}

class SearchViewController: UIViewController {
	//normal properties and constants

	let cellIdentifier = "StrainsTableViewCell"
	let segueIdentifierForDetail = "showStrainDetailSegue"

	var strainsArray: [Strain] = []
	var effectsArray: [Effects]?

	var url = "https://strainapi.evanbusse.com/oJ5GvWc/strains/search/name/"
	let urlForEffectsSearch = "https://strainapi.evanbusse.com/oJ5GvWc/searchdata/effects/"

	var selectedDetailStrain: Strain?

	//IBOutlets

	@IBOutlet var searchTextField: UITextField!

	@IBOutlet var strainSearchTableView: UITableView!


	override func viewDidLoad() {
		super.viewDidLoad()

		let tap = UITapGestureRecognizer(target: self.view, action: #selector(UIView.endEditing(_:)))
		tap.cancelsTouchesInView = false
		self.view.addGestureRecognizer(tap)

		self.strainSearchTableView.delegate = self
		self.strainSearchTableView.dataSource = self



	}

	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.destination is DetailViewConstroller {
			guard let detailVC = segue.destination as? DetailViewConstroller else { return }
			detailVC.activeDetailStrain = selectedDetailStrain
		}
	}

	func unwindToSearchViewController(unwindSegue: UIStoryboardSegue) {

	}

	func searchWeed(using strainString: String) -> [Strain] {
		var strainMatches: [Strain]?



		return strainMatches!
	}

	func segueToDetailControllerWithStrain(strainToPass: Strain) {
		performSegue(withIdentifier: "showStrainDetailSegue", sender: nil)

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
		refreshUI()
	}

	func refreshUI() {
		loadViewIfNeeded()
//		print(strainsArray)
		strainSearchTableView.reloadData()
	}

	@IBAction func searchClicked(_ sender: UIButton) {
		guard let strainSearchString = searchTextField.text else { return }
		searchStrains(using: strainSearchString)
	}

	@IBAction func reloadView(_ sender: Any) {
		refreshUI()
	}



}



extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return strainsArray.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! StrainsTableViewCell

		let strainForIndex = strainsArray[indexPath.row]

		cell.strainNameLabel.text = strainForIndex.name


		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let strainForIndex = strainsArray[indexPath.row]

		selectedDetailStrain = strainForIndex
		segueToDetailControllerWithStrain(strainToPass: strainForIndex)
		//call segue method
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

