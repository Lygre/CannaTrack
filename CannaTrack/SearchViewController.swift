//
//  ViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit


class SearchViewController: UIViewController {
	//normal properties and constants

	let cellIdentifier = "StrainsTableViewCell"
	let segueIdentifierForDetail = "showStrainDetailSegue"

	var strainsArray: [BaseStrain] = []
	var effectsArray: [Effects]?
	var effectArrayEnumeration: [Effect]?

	var strainDatabase: [Strain] = []

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
		} else if segue.destination is StrainsCollectionViewController {
			guard let collectionVC = segue.destination as? StrainsCollectionViewController else { return }

			if self.strainDatabase.isEmpty {
				strainDatabase = convertStrainDatabaseToClass(using: finalStrainDatabase)
			} else {
				collectionVC.strainDatabase = strainDatabase
			}
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


	func generateEffectsSet(completion: @escaping (([Effect])->Void)) -> [Effect] {
		var effectsArray: [Effect] = []

		guard let urlObj = URL(string: urlForEffectsSearch) else { return effectsArray }

		URLSession.shared.dataTask(with: urlObj) { (data, response, error) in
			guard let data = data else { return }

			do {
				let tempEffectArrayParsed = try JSONDecoder().decode([Effect].self, from: data)
				effectsArray = tempEffectArrayParsed
				completion(effectsArray)
				print(effectsArray)
			} catch let jsonError {
				print("Error serializing json: ", jsonError)
			}
		}.resume()

		return effectsArray
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

	func convertStrainDatabaseToClass(using structStrainDB: [BaseStrain]) -> [Strain] {
		var finalStrainClassDatabase: [Strain] = []

		for structStrain in structStrainDB {
			let strainClassToAddToDB: Strain = Strain(id: structStrain.id, name: structStrain.name, race: structStrain.race, description: structStrain.desc)
			finalStrainClassDatabase.append(strainClassToAddToDB)
		}

		return finalStrainClassDatabase
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
			//this should probably be changed; but the send request is what would need to change.
			sendRequest(using: vowel, completion: {intermediaryBaseStrainArray in self.createStrainSetFromArray(using: intermediaryBaseStrainArray)})
		}

//		makeUnion()

	}

	fileprivate func makeUnion() {
		let union = strainSetsArray[0].union(strainSetsArray[1]).union(strainSetsArray[2]).union(strainSetsArray[3]).union(strainSetsArray[4])
		print(union)
		if finalStrainDatabase.isEmpty {
			for strain in union {
				finalStrainDatabase.append(strain)
			}
		} else { print("final strain db is not empty") }
	}

	@IBAction func unionButtonClicked(_ sender: UIButton) {
		makeUnion()
	}

	@IBAction func generateEffectsClicked(_ sender: UIButton) {
		effectArrayEnumeration = generateEffectsSet(completion: { effects in })
	}



	@IBAction func strainsToClassesClicked(_ sender: UIButton) {
		strainDatabase = convertStrainDatabaseToClass(using: finalStrainDatabase)
		masterStrainDatabase = strainDatabase
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



