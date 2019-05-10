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

	var networkManager: NetworkManager!

	@IBOutlet var strainAbbreviation: UILabel!

	@IBOutlet var strainFullName: UILabel!

	@IBOutlet var varietyLabel: UILabel!

	@IBOutlet var medicalEffectsLabel: UILabel!

	@IBOutlet var positiveEffectsLabel: UILabel!

	@IBOutlet var negativeEffectsLabel: UILabel!



	init() {
		self.networkManager = NetworkManager()
		super.init(nibName: nil, bundle: nil)
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
	}




	override func viewDidLoad() {
        super.viewDidLoad()


		medicalEffectsLabel.numberOfLines = 0
		medicalEffectsLabel.lineBreakMode = .byWordWrapping
		positiveEffectsLabel.numberOfLines = 0
		positiveEffectsLabel.lineBreakMode = .byWordWrapping
		negativeEffectsLabel.numberOfLines = 0
		negativeEffectsLabel.lineBreakMode = .byWordWrapping



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
			view.backgroundColor = UIColor(named: "hybridColor")
		case .indica:
			varietyLabel.text = "Indica"
			view.backgroundColor = UIColor(named: "indicaColor")
		case .sativa:
			varietyLabel.text = "Sativa"
			view.backgroundColor = UIColor(named: "sativaColor")
		}
		if let effects = strain.effects {
			updateStrainEffectsUI(effects)
		} else {
			networkManager.getEffects(for: strain.id) { (effects, error) in
				DispatchQueue.main.async {
					if let error = error {
						print(error)
					}
					if let effects = effects {
						print("Updating effects UI, and effects property for strain object: Message sent by \(self.networkManager.debugDescription)")
						self.activeDetailStrain?.effects = effects
						self.updateStrainEffectsUI(effects)
					}
				}
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


extension StrainDetailViewController {
	//private helper methods
	fileprivate func updateStrainEffectsUI(_ effects: Effects) {
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
