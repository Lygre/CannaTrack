//
//  DoseController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/27/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit
import CloudKit

struct DoseController {

	static let shared = DoseController()
	static let localDosesKey = "localDosesKey"

	static var doses: [Dose] {
		get {
			guard let localDoses = UserDefaults.standard.object([Dose].self, with: DoseController.localDosesKey) else {
				print("could not decode doses; returning empty dose array")
				return []
			}
			return localDoses
		}
		set {
			UserDefaults.standard.set(object: newValue, forKey: DoseController.localDosesKey)

		}
	}


	func log(dose: Dose) {
		DoseController.doses.append(dose)
		print("saved \(dose) locally from DoseController")
	}

	func delete(dose: Dose) {
		guard let indexOfDoseInDoseArray = DoseController.doses.firstIndex(of: dose) else {
			return
		}
		DoseController.doses.remove(at: indexOfDoseInDoseArray)
		print("deleted dose \(dose) locally")
	}



	
}
