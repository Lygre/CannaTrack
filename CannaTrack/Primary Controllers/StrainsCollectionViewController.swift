//
//  StrainsCollectionViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/18/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

private let reuseIdentifier = "StrainCell"

class StrainsCollectionViewController: UICollectionViewController {

	let detailSegueIdentifier = "strainDetailSegue"

	let searchController = UISearchController(searchResultsController: nil)
	var searchActive: Bool = false


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

				strainsToDisplay.append(strainToAppend)

			}
			masterStrainDatabase = strainsToDisplay
		}
	}
	var strainsToDisplay: [Strain] = [] {
		didSet {
			refreshUI()
		}
	}

	var strainToPassToDetail: Strain?

    override func viewDidLoad() {
        super.viewDidLoad()
		if strainsToDisplay.isEmpty {
			sendRequestForAllStrains(completion: {allstrainsDict in
				self.allStrains = allstrainsDict
		})
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
			strainsToDisplay = masterStrainDatabase ?? []
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

		if segue.destination is StrainDetailViewController {
			let detailVC = segue.destination as! StrainDetailViewController
			detailVC.activeDetailStrain = strainToPassToDetail
		}
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

		cell.strainAbbreviation.text = String(strainForIndexPath.name.first!)
		cell.strainName.text = strainForIndexPath.name
		cell.varietyLabel.text = strainForIndexPath.race.rawValue
        // Configure the cell

		cell.layer.cornerRadius = 12
		cell.backgroundColor = {
			switch strainForIndexPath.race {
			case .indica:
				return UIColor.purple
			case .sativa:
				return UIColor.yellow
			case .hybrid:
				return UIColor.green
			}
		}()

        return cell
    }

	override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		guard let strainForIndexPath = strainsToDisplay[indexPath.item] as? Strain else { fatalError("something went terribly wrong getting the strain for specified indexPath")}
		strainToPassToDetail = getStrainForIndexPath(indexPath: indexPath)
		performSegue(withIdentifier: detailSegueIdentifier, sender: nil)

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
		self.collectionView.reloadData()
	}






}


extension StrainsCollectionViewController: UISearchControllerDelegate, UISearchBarDelegate, UISearchResultsUpdating {
	func updateSearchResults(for searchController: UISearchController) {

//		guard let searchString = searchController.searchBar.text else { return }
		let searchString = searchController.searchBar.text
		let searchResults = searchStrains(using: searchString!)
//		print(searchResults)
		strainsToDisplay = searchResults
		print(searchString)
		if (searchString == "") {
			strainsToDisplay = masterStrainDatabase ?? []
		}
		print("Updating Search Results")
		self.collectionView?.reloadData()
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
