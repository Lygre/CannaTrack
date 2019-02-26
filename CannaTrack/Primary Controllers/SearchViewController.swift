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

	var allStrainsClasses: [Strain] = []
	var allStrains: [String: StrainInformation] {
		get {
			var strainsDict: [String: StrainInformation] = [:]
			sendRequestForAllStrains(completion: { strainsDictionary in
				strainsDict = strainsDictionary
//				return strainsDict!
			})
			return strainsDict
		}
		set {
			for (strainName, strainInformation) in newValue {
				let strainToAppend = Strain(id: strainInformation.id, name: strainName, race: StrainVariety.init(rawValue: strainInformation.race)!, description: nil)
				strainToAppend.flavors = strainInformation.flavors
//				strainToAppend.effects = strainInformation.effects
				allStrainsClasses.append(strainToAppend)
			}
		}
	}
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


	@IBOutlet var processStatusImage: UIImageView!


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
				collectionVC.strainsToDisplay = strainDatabase
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


	func updateProcessStatusImage() {
		processStatusImage.image = UIImage(imageLiteralResourceName: "greenCheck.png")

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
//				self.intermediaryBaseStrainArray = intermediateBasestrainArray
				self.strainSetsArray.append(self.createStrainSetFromArray(using: intermediateBasestrainArray))
				completion(intermediateBasestrainArray)
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

	func generateUnionOfStrains(setArray: [Set<BaseStrain>]) -> Set<BaseStrain> {
		let unionOfStrains: Set<BaseStrain> = {
			let strainSetOne = setArray[0]
			let strainSetTwo = setArray[1]
			let strainSetThree = setArray[2]
			let strainSetFour =  setArray[3]
			let strainSetFive = setArray[4]
			let babyUnion = strainSetOne.union(strainSetTwo).union(strainSetThree).union(strainSetFour).union(strainSetFive)
			return babyUnion
		}()
		return unionOfStrains
	}

	func generateFinalStrainArray(baseStrainUnion: Set<BaseStrain>) -> [Strain] {
		let finalStrainArray: [Strain] = {
			var basestrainArray: [BaseStrain] = []

			for strain in baseStrainUnion {
				basestrainArray.append(strain)
			}

			let strainArray = convertStrainDatabaseToClass(using: basestrainArray)

			return strainArray
		}()
		return finalStrainArray
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

		var baseStrainSetArray: [Set<BaseStrain>] = [] {
			willSet(newBaseStrainArray) {
//				self.strainDatabase = generateFinalStrainArray(baseStrainUnion: generateUnionOfStrains(setArray: newBaseStrainArray))
				print(newBaseStrainArray)
			}
			didSet {
				print("database set")
			}
		}
		var finalStrainArray: [Strain]?
		var unionOfStrains: Set<BaseStrain>?
		effectArrayEnumeration = generateEffectsSet(completion: { effects in })

//		strainDatabase = {

		func generateBaseStrainSetArray() -> [Set<BaseStrain>] {
			let baseStrainSetArray: [Set<BaseStrain>] = {
				var strainSetArray: [Set<BaseStrain>] = []

				let vowelArray: [String] = ["a", "e", "i", "o", "u"]
				for vowel in vowelArray {
					//this should probably be changed; but the send request is what would need to change.
					sendRequest(using: vowel, completion: {intermediaryBaseStrainArray in strainSetArray.append(self.createStrainSetFromArray(using: intermediaryBaseStrainArray)) })
				}

				return strainSetArray
			}()
			return baseStrainSetArray
		}


		func generateBaseStrainSetArrayAlternate() -> [Strain] {
			var setArrayPassCount = 0
			var baseStrainArray: [BaseStrain] = []
			var baseStrainUnion: Set<BaseStrain>
			let baseStrainSetArray: [Set<BaseStrain>] = {
				var strainSetArray: [Set<BaseStrain>] = []


				let vowelArray: [String] = ["a", "e", "i", "o", "u"]
				for vowel in vowelArray {
					//this should probably be changed; but the send request is what would need to change.
					sendRequest(using: vowel, completion: {intermediaryBaseStrainArray in
						strainSetArray.append(self.createStrainSetFromArray(using: intermediaryBaseStrainArray))
						setArrayPassCount += 1

					})
				}

				return strainSetArray
			}()

			if setArrayPassCount == 5 {
				baseStrainUnion = baseStrainSetArray[0].union(baseStrainSetArray[1]).union(baseStrainSetArray[2]).union(baseStrainSetArray[3]).union(baseStrainSetArray[4])

				for strain in baseStrainUnion {
					baseStrainArray.append(strain)
				}


			}
			return convertStrainDatabaseToClass(using: baseStrainArray)
		}



		baseStrainSetArray = generateBaseStrainSetArray()

//		guard let finalStrainDatabase = finalStrainArray else { return }
//		strainDatabase = finalStrainDatabase
//		masterStrainDatabase = strainDatabase
		print("okay")
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
//		effectArrayEnumeration = generateEffectsSet(completion: { effects in })

		sendRequestForAllStrains(completion: { strainDictionary in
			self.allStrains = strainDictionary
			print("all strains generated", self.allStrains)
		})

	}



	@IBAction func strainsToClassesClicked(_ sender: UIButton) {
		strainDatabase = convertStrainDatabaseToClass(using: finalStrainDatabase)
		masterStrainDatabase = strainDatabase
		updateProcessStatusImage()
	}





}









extension SearchViewController {

	func sendRequestForAllStrains(completion: @escaping (([String: StrainInformation]) -> Void)) {
		var baseStrainsArrayForVowel: [String: StrainInformation] = [:]
		let url = "https://strainapi.evanbusse.com/oJ5GvWc/strains/search/all"
		guard let urlObj = URL(string: url) else { return }

		URLSession.shared.dataTask(with: urlObj) {(data, response, error) in

			guard let data = data else { return }

			do {
				let intermediateBasestrainArray = try JSONDecoder().decode([String: StrainInformation].self, from: data)
				baseStrainsArrayForVowel = intermediateBasestrainArray

				completion(baseStrainsArrayForVowel)
				print("data parsed from strain database")
			} catch let jsonError {
				print("Error serializing json: ", jsonError)
			}

			}.resume()
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



