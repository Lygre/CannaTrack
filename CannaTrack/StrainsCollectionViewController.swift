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

	var strainDatabase: [Strain]? {
		didSet {
			refreshUI()
		}
	}

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Register cell classes

        // Do any additional setup after loading the view.
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

	}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
    }
    */

    // MARK: UICollectionViewDataSource

    override func numberOfSections(in collectionView: UICollectionView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }


    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
		return strainDatabase?.count ?? 0
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as? StrainCollectionViewCell else { fatalError("could not cast cell as StrainCollectionViewCell") }

		guard let strainForIndexPath = strainDatabase?[indexPath.item] else { fatalError("something went terribly wrong getting the strain for specified indexPath")}

		cell.strainAbbreviation.text = String(strainForIndexPath.name.first!)
		cell.strainName.text = strainForIndexPath.name
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


	func refreshUI() {
		loadViewIfNeeded()
		collectionView.reloadData()
	}






}
