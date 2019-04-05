//
//  LogDoseFromCalendarViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/5/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class LogDoseFromCalendarViewController: UIViewController {

	let cellIdentifier = "InventoryCollectionViewCell"


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


extension LogDoseFromCalendarViewController: UICollectionViewDelegate {


}


extension LogDoseFromCalendarViewController: UICollectionViewDataSource {
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return globalMasterInventory.count
		//this will probably crash the app one day

	}

	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as? InventoryCollectionViewCell else { fatalError("could not cast as Inventory Collection View Cell") }

		cell.inventoryProductLabel.text = globalMasterInventory[indexPath.row].productType.rawValue
		cell.productStrainNameLabel.text = globalMasterInventory[indexPath.row].strain.name
		cell.productMassRemainingLabel.text = "\(globalMasterInventory[indexPath.row].mass)"
		cell.doseCountLabel.text = "\(globalMasterInventory[indexPath.row].numberOfDosesTakenFromProduct)"

		for view in cell.subviews {
			view.backgroundColor = .clear
		}

		switch globalMasterInventory[indexPath.row].strain.race {
		case .hybrid:
			cell.backgroundColor = .green
		case .indica:
			cell.backgroundColor = .purple
		case .sativa:
			cell.backgroundColor = .yellow
		}

		cell.layer.cornerRadius = cell.frame.width / 2
		cell.layer.masksToBounds = true

		return cell
	}


}


extension LogDoseFromCalendarViewController {

	

}
