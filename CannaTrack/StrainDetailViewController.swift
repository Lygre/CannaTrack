//
//  StrainDetailViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 2/19/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class StrainDetailViewController: UIViewController {

	var activeDetailStrain: Strain? {
		didSet {
			refreshUI()
		}
	}

	@IBOutlet var strainAbbreviation: UILabel!

	@IBOutlet var strainFullName: UILabel!

	@IBOutlet var varietyLabel: UILabel!

	@IBOutlet var medicalEffectsLabel: UILabel!

	@IBOutlet var positiveEffectsLabel: UILabel!

	@IBOutlet var negativeEffectsLabel: UILabel!

	override func viewDidLoad() {
        super.viewDidLoad()



        // Do any additional setup after loading the view.
    }

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)

	}

	func refreshUI() {
		loadViewIfNeeded()
		guard let strain = activeDetailStrain else { return }

		strainFullName.text = strain.name
		strainAbbreviation.text = String(strain.name.first ?? "A")

		switch strain.race {
		case .hybrid:
			varietyLabel.text = "Hybrid"
			view.backgroundColor = UIColor.green
		case .indica:
			varietyLabel.text = "Indica"
			view.backgroundColor = UIColor.purple
		case .sativa:
			varietyLabel.text = "Sativa"
			view.backgroundColor = UIColor.yellow
		}
		if let effects = strain.effects {
			if let medical = effects.medical {
				var medicalEffectsString: String = ""
				for effect in medical {
					if medicalEffectsString == "" {
						medicalEffectsString = effect
					} else {
						medicalEffectsString += ", \(effect)"
					}
				}

				medicalEffectsLabel.text = medicalEffectsString
			}
			if let positive = effects.positive {
				var positiveEffectsString: String = ""
				for effect in positive {
					if positiveEffectsString == "" {
						positiveEffectsString = effect
					} else {
						positiveEffectsString += ", \(effect)"
					}
				}

				positiveEffectsLabel.text = positiveEffectsString
			}
			if let negative = effects.negative {
				var negativeEffectsString: String = ""
				for effect in negative {
					if negativeEffectsString == "" {
						negativeEffectsString = effect
					} else {
						negativeEffectsString += ", \(effect)"
					}
				}

				negativeEffectsLabel.text = negativeEffectsString
			}
		}

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
