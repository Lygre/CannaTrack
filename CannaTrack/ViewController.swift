//
//  ViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DetailViewConstroller: UIViewController {

	var activeDetailStrain: BaseStrain?


	@IBOutlet var idLabel: UILabel!

	@IBOutlet var strainNameLabel: UILabel!

	@IBOutlet var strainRaceLabel: UILabel!

	@IBOutlet var strainDescriptionLabel: UILabel!


	override func viewDidLoad() {
		super.viewDidLoad()

		strainDescriptionLabel.numberOfLines = 0
		strainDescriptionLabel.lineBreakMode = .byWordWrapping

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


	@IBAction func loadEffects(_ sender: UIButton) {

		guard let strain = activeDetailStrain else { fatalError("No strain set") }

		var strainMutable: BaseStrain = strain
		strainMutable.getDetails()


	}


}

class SearchViewController: UIViewController {
	//normal properties and constants

	let cellIdentifier = "StrainsTableViewCell"
	let segueIdentifierForDetail = "showStrainDetailSegue"

	var strainsArray: [BaseStrain] = []
	var effectsArray: [Effects]?

	var url = "https://strainapi.evanbusse.com/oJ5GvWc/strains/search/name/"
	let urlForEffectsSearch = "https://strainapi.evanbusse.com/oJ5GvWc/searchdata/effects/"

	var selectedDetailStrain: BaseStrain?
	var strainSetsArray: [Set<BaseStrain>] = []
	var baseStrainArray: [[BaseStrain]] = []
	var intermediaryBaseStrainArray: [BaseStrain] = []

	var finalStrainDatabase: [BaseStrain] = []


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

	func searchWeed(using strainString: String) -> [BaseStrain] {
		var strainMatches: [BaseStrain]?



		return strainMatches!
	}

	func segueToDetailControllerWithStrain(strainToPass: BaseStrain) {
		performSegue(withIdentifier: "showStrainDetailSegue", sender: nil)

	}



	func searchStrains(using effect: String) {
		url = "https://strainapi.evanbusse.com/oJ5GvWc/strains/search/name/" + String("\(effect)").trimmingCharacters(in: .whitespaces)
		guard let urlObj = URL(string: url) else { return }

		URLSession.shared.dataTask(with: urlObj) {(data, response, error) in

			guard let data = data else { return }

			do {
				self.strainsArray = try JSONDecoder().decode([BaseStrain].self, from: data)
				print("data parsed from strain database")
			} catch let jsonError {
				print("Error serializing json: ", jsonError)
			}

			}.resume()
		refreshUI()
	}

	func sendRequest(using vowel: String, completion: @escaping (([BaseStrain]) -> Void)) {
		var baseStrainsArrayForVowel: [BaseStrain] = []
		let urlForVowel = "https://strainapi.evanbusse.com/oJ5GvWc/strains/search/name/" + String("\(vowel)").trimmingCharacters(in: .whitespaces)
		guard let urlObj = URL(string: urlForVowel) else { return }

		URLSession.shared.dataTask(with: urlObj) {(data, response, error) in

			guard let data = data else { return }

			do {
				let intermediateBasestrainArray = try JSONDecoder().decode([BaseStrain].self, from: data)
				baseStrainsArrayForVowel = intermediateBasestrainArray
				self.intermediaryBaseStrainArray = intermediateBasestrainArray
				self.strainSetsArray.append(self.createStrainSetFromArray(using: intermediateBasestrainArray))
				completion(self.intermediaryBaseStrainArray)
				print("data parsed from strain database")
			} catch let jsonError {
				print("Error serializing json: ", jsonError)
			}

			}.resume()
	}


	func searchStrainsByVowel(using vowel: String) -> [BaseStrain] {
		var baseStrainsArrayForVowel: [BaseStrain] = []
		let urlForVowel = "https://strainapi.evanbusse.com/oJ5GvWc/strains/search/name/" + String("\(vowel)").trimmingCharacters(in: .whitespaces)
		guard let urlObj = URL(string: urlForVowel) else { return baseStrainsArrayForVowel}

		URLSession.shared.dataTask(with: urlObj) {(data, response, error) in

			guard let data = data else { return }

			do {
				let intermediateBasestrainArray = try JSONDecoder().decode([BaseStrain].self, from: data)
				baseStrainsArrayForVowel = intermediateBasestrainArray
				print("data parsed from strain database")
			} catch let jsonError {
				print("Error serializing json: ", jsonError)
			}

			}.resume()
		return baseStrainsArrayForVowel
	}

	func createStrainSetFromArray(using strainArray: [BaseStrain]) -> Set<BaseStrain> {
		var baseStrainSet: Set<BaseStrain> = []
		for strain in strainArray {
			baseStrainSet.insert(strain)
		}
		return baseStrainSet
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

	@IBAction func generateSetFromArray(_ sender: UIButton) {

//		strainSetsArray.append(createStrainSetFromArray(using: strainsArray))
		let vowelArray: [String] = ["a", "e", "i", "o", "u"]

		for vowel in vowelArray {
			sendRequest(using: vowel, completion: {intermediaryBaseStrainArray in self.createStrainSetFromArray(using: intermediaryBaseStrainArray)})
		}

	}

	@IBAction func unionButtonClicked(_ sender: UIButton) {
		let union = strainSetsArray[0].union(strainSetsArray[1]).union(strainSetsArray[2]).union(strainSetsArray[3]).union(strainSetsArray[4])
		print(union)
		if finalStrainDatabase.isEmpty {
			for strain in union {
				finalStrainDatabase.append(strain)
			}
		}
	}


}



extension SearchViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//		return strainsArray.count
		return finalStrainDatabase.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier, for: indexPath) as! StrainsTableViewCell

//		let strainForIndex = strainsArray[indexPath.row]
		let strainForIndex = finalStrainDatabase[indexPath.row]

		cell.strainNameLabel.text = strainForIndex.name


		return cell
	}

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//		let strainForIndex = strainsArray[indexPath.row]
		let strainForIndex = finalStrainDatabase[indexPath.row]
		selectedDetailStrain = strainForIndex
		segueToDetailControllerWithStrain(strainToPass: strainForIndex)
		//call segue method
	}


}





struct BaseStrain: Decodable, Hashable {

	let id: Int
	let name: String
	let race: String
	let desc: String?
	var flavors: String?
	var effects: Effects?


	func sendRequestForEffects(forStrain id: Int, completion: @escaping ((Effects) ->Void)) {
		let urlForId = "https://strainapi.evanbusse.com/oJ5GvWc/strains/data/effects/" + String("\(id)").trimmingCharacters(in: .whitespaces)
		guard let urlObj = URL(string: urlForId) else { return }

		URLSession.shared.dataTask(with: urlObj) {(data, response, error) in

			guard let data = data else { return }

			do {
				let effectsDictionary = try JSONDecoder().decode(Effects.self, from: data)
//				self.effects = intermediateBasestrainArray.effects
				completion(effectsDictionary)
				print("effect parsed from strain database")
			} catch let jsonError {
				print("Error serializing json: ", jsonError)
			}

			}.resume()
	}

	mutating func getDetails() {
		let strainID = self.id
		var effectsToSet: Effects?
		if self.effects == nil {
			sendRequestForEffects(forStrain: strainID, completion: { effectsToSet in

			})

		}
	}
}




struct Effects: Decodable, Hashable {
	var positive: [String]?
	var negative: [String]?
	var medical: [String]?

}

class Strain {
	let id: Int
	let name: String
	let race: String
	let desc: String?
//	var flavors: ???
	var effects: Effects?

	init(id: Int, name: String, race: String) {
		self.id = id
		self.name = name
		self.race = race
		self.desc = nil
		self.effects = nil
	}

}
