//
//  FilterOptionsTableViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/28/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

enum FilterOption: String, CaseIterable {
	case openedStatus = "Opened Status"
	case dateOpened = "Date Opened"
	case lastDoseTime = "Time of Last Dose"
	case massRemaining = "Mass Remaining"
	case numberOfDoses = "Number of Doses"
	case strainVarietyIndica = "Strain Variety - Indica"
	case strainVarietySativa = "Strain Variety - Sativa"
	case strainVarietyHybrid = "Strain Variety - Hybrid"
	case none = "No Filter"
}

protocol InventoryFilterDelegate {
	func filterInventory(using filterOption: FilterOption)
}

class FilterOptionsTableViewController: UITableViewController {


	var filterOptions: [FilterOption] = FilterOption.allCases
	
	var filterDelegate: InventoryFilterDelegate!

	var selectedFilterOption: FilterOption = .none

    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return filterOptions.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: filterOptionsTableViewCellIdentifier, for: indexPath) as? FilterOptionsTableViewCell else { return UITableViewCell() }
		cell.filterOptionLabel.text = filterOptions[indexPath.row].rawValue

        // Configure the cell...

        return cell
    }


	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//		guard let cell = tableView.dequeueReusableCell(withIdentifier: filterOptionsTableViewCellIdentifier, for: indexPath) as? FilterOptionsTableViewCell else { return }
		selectedFilterOption = filterOptions[indexPath.row]
		dismiss(animated: true) {
			print("dismissing view with \(self.selectedFilterOption)")
			self.filterDelegate.filterInventory(using: self.selectedFilterOption)
		}
	}
    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
