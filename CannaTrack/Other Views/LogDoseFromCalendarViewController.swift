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

	@IBOutlet var productsCollectionView: UICollectionView!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		productsCollectionView.collectionViewLayout.invalidateLayout()
		productsCollectionView.reloadData()
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

		cell.layer.cornerRadius = cell.frame.width / 5
		cell.layer.masksToBounds = true

		return cell
	}


}




extension LogDoseFromCalendarViewController: UICollectionViewDelegateFlowLayout {

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
		return CGSize(width: 120, height: 120)
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
		return 8
	}

	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
		return UIEdgeInsets.init(top: 8, left: 8, bottom: 8, right: 8)
	}

}




extension LogDoseFromCalendarViewController {



}
