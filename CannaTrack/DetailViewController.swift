//
//  DetailViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/18/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
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
		strainRaceLabel.text = currentStrain.race.rawValue
		strainDescriptionLabel.text = currentStrain.desc ?? "No Description Available"
	}


	@IBAction func loadEffects(_ sender: UIButton) {

		guard let strain = activeDetailStrain else { fatalError("No strain set") }

		var strainMutable: BaseStrain = strain
		self.activeDetailStrain?.getDetails()

	}


}

