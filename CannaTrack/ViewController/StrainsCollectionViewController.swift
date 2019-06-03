//
//  StrainsCollectionViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/18/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

private let reuseIdentifier = "StrainCell"

class StrainsCollectionViewController: UICollectionViewController, StrainCollectionDelegate {

	func updateItems() {
		guard let indexPaths = self.selectedIndexPaths else {
			print("no indexPaths to update")
			return
		}
		print("updating item in strains collection from delegate method for preview action")
		self.collectionView.reloadItems(at: indexPaths)
	}

	var selectedIndexPaths: [IndexPath]?

	let detailSegueIdentifier = "strainDetailSegue"

	let searchController = UISearchController(searchResultsController: nil)
	var searchActive: Bool = false

	var networkManager: NetworkController!

	var allStrains: [String: StrainInformation] {
		get {
			var strainsDict: [String: StrainInformation] = [:]
			sendRequestForAllStrains(completion: { strainsDictionary in
				strainsDict = strainsDictionary
			})
			return strainsDict
		}
		set {
			for (strainName, strainInformation) in newValue {
				let strainToAppend = Strain(id: strainInformation.id, name: strainName, race: StrainVariety.init(rawValue: strainInformation.race)!, description: nil)
				strainToAppend.flavors = strainInformation.flavors
				//				strainToAppend.effects = strainInformation.effects
				StrainController.shared.add(toDatabase: [strainToAppend]) { strainsAdded in
					if let strainsForViewControllerToAdd = strainsAdded {
						DispatchQueue.main.async {
							print("appended strain to database from StrainsCollection: 'allStrains' setter")
							self.strainsToDisplay.append(contentsOf: strainsForViewControllerToAdd)

							self.loadViewIfNeeded()
							self.collectionViewLayout.invalidateLayout()
							self.collectionView.reloadData()
						}
					}
				}
//				strainsToDisplay.append(strainToAppend)

			}
//			masterStrainDatabase = strainsToDisplay
			DispatchQueue.main.async {
				self.loadViewIfNeeded()
				self.collectionViewLayout.invalidateLayout()
				self.collectionView.reloadData()
			}
		}
	}
	var strainsToDisplay: [Strain] = StrainController.strains
		/*
		{
		willSet(newStrainArray) {
			if newStrainArray != StrainController.strains {
				let strainsToWriteLocally: [Strain] = newStrainArray.filter({ return !StrainController.strains.contains($0) })
				if !strainsToWriteLocally.isEmpty {
					StrainController.shared.add(toDatabase: strainsToWriteLocally) { _ in
						print("added new strains: \(strainsToWriteLocally) to database locally from StrainsVC: 'strainsToDisplay' willSet")

					}
				}
			}
		}
	}

		*/

		/*
		UserDefaults.standard.object([Strain].self, with: "localStrains") ?? [] {
		willSet(newStrainArray) {
			print("setting new local strain array")
			UserDefaults.standard.set(object: newStrainArray, forKey: "localStrains")
			masterStrainDatabase = newStrainArray

		}
	}
		*/

	var strainToPassToDetail: Strain?

	init() {
		self.networkManager = NetworkController()
		super.init(nibName: nil, bundle: nil)
	}
	required init?(coder aDecoder: NSCoder) {
		self.networkManager = NetworkController()
		super.init(coder: aDecoder)
	}

    override func viewDidLoad() {
        super.viewDidLoad()
		if strainsToDisplay.isEmpty {
			networkManager.getNewStrains { (allStrainsDict, error) in
				if let error = error {
					print(error)
				}
				if let strainsDict = allStrainsDict {
					print(strainsDict)
					self.allStrains = strainsDict
				}
			}

//			strainsToDisplay = masterStrainDatabase
		}

		self.searchController.searchResultsUpdater = self
		self.searchController.delegate = self
		self.searchController.searchBar.delegate = self

		self.searchController.hidesNavigationBarDuringPresentation = false
		self.searchController.dimsBackgroundDuringPresentation = false
		self.searchController.obscuresBackgroundDuringPresentation = false

		searchController.searchBar.placeholder = "Can search strain name"
		searchController.searchBar.sizeToFit()
		searchController.searchBar.becomeFirstResponder()
		searchController.searchBar.showsCancelButton = true

		self.navigationItem.titleView = searchController.searchBar

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes

        // Do any additional setup after loading the view.
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		if strainsToDisplay.isEmpty {
//			strainsToDisplay = StrainController.strains
			StrainController.shared.fetchLocalStrains(using: strainsToDisplay, completion: { (fetchedLocalStrains) in
				DispatchQueue.main.async {
					self.strainsToDisplay.append(contentsOf: fetchedLocalStrains)
					self.loadViewIfNeeded()
					self.collectionViewLayout.invalidateLayout()
					self.collectionView.reloadData()
				}
			})
		} else {
			print("strain db isn't empty")
			refreshUI()
		}
	}

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
		guard let selectedCollectionViewCell = sender as? StrainCollectionViewCell, let indexPath = collectionView.indexPath(for: selectedCollectionViewCell) else { preconditionFailure("could not get selected cell and indexPath")}
		guard let detailVC = segue.destination as? StrainDetailViewController else { preconditionFailure("could not get segue destination as StrainDetailVC")}
		self.selectedIndexPaths = [indexPath]
		detailVC.strainCollectionDelegate = self
		detailVC.networkManager = self.networkManager
		detailVC.activeDetailStrain = strainsToDisplay[indexPath.item]

	}



    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
		return strainsToDisplay.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? StrainCollectionViewCell else { fatalError("could not cast cell as StrainCollectionViewCell") }

		guard let strainForIndexPath = strainsToDisplay[indexPath.item] as? Strain else { fatalError("something went terribly wrong getting the strain for specified indexPath")}
		guard let abbr = strainForIndexPath.name.firstCharacterAsString else { fatalError("could not get abbreviation for strain cell ") }
		cell.strainAbbreviation.text = abbr
		cell.strainName.text = strainForIndexPath.name
		cell.varietyLabel.text = strainForIndexPath.race.rawValue
        // Configure the cell

		cell.layer.cornerRadius = 12
		cell.backgroundColor = {
			switch strainForIndexPath.race {
			case .indica:
				return UIColor(named: "indicaColor")
			case .sativa:
				return UIColor(named: "sativaColor")
			case .hybrid:
				return UIColor(named: "hybridColor")
			}
		}()

		cell.isFavorite = strainForIndexPath.favorite ? true : false

        return cell
    }

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let strainForIndexPath = strainsToDisplay[indexPath.item] as? Strain else { fatalError("something went terribly wrong getting the strain for specified indexPath; this should never ever fail")}
		strainToPassToDetail = getStrainForIndexPath(indexPath: indexPath)

	}

    // MARK: UICollectionViewDelegate

    /*
    // Uncomment this method to specify if the specified item should be highlighted during tracking
    override func collectionView(_ collectionView: UICollectionView, shouldHighlightItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment this method to specify if the specified item should be selected
    override func collectionView(_ collectionView: UICollectionView, shouldSelectItemAt indexPath: IndexPath) -> Bool {
        return true
    }
    */

    /*
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
    override func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return false
    }

    override func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
    
    }
    */


	func getStrainForIndexPath(indexPath: IndexPath) -> Strain {
		guard let strain = strainsToDisplay[indexPath.item] as? Strain else { return Strain(id: 0, name: "Null Placeholder", race: .hybrid, description: "Placeholder Strain") }

		return strain
	}

	func refreshUI() {
		loadViewIfNeeded()
		self.collectionView.collectionViewLayout.invalidateLayout()
		self.collectionView.reloadData()
	}






}


extension StrainsCollectionViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {

//		guard let searchString = searchController.searchBar.text else {
//			print("there is no search string in search bar")
//			return
//		}
		let stringInSearchBar = searchController.searchBar.text

		guard let searchString = stringInSearchBar else {
			print("string in search bar was nil; returning")
			strainsToDisplay = StrainController.strains
			self.collectionView?.reloadData()
			return
		}

		let searchResults = StrainController.shared.searchStrains(using: searchString)

		strainsToDisplay = searchResults

		if (searchString == "") {
			strainsToDisplay = StrainController.strains
		}
		self.collectionView?.reloadData()
		print(stringInSearchBar ?? "No search string established, or is empty.")
	}

	func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
		searchController.searchBar.showsCancelButton = true
		searchActive = true
	}

	func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
//		searchController.searchBar.showsCancelButton = false
		searchActive = false
	}

	/*
	func searchBarShouldEndEditing(_ searchBar: UISearchBar) -> Bool {
		if searchActive { return true }
	}
	*/

	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		searchBar.endEditing(true)
		print("end search bar editing")
	}

}


extension StrainsCollectionViewController {

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
