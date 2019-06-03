//
//  StrainController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 6/3/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit
import CloudKit
import UserNotifications
import SwifterSwift


struct StrainController {

	static let shared = StrainController()
	static let localStrainsKey = "localStrainsKey"
//	static let randomFilename = UUID().uuidString
//	static let fullPathForStrains = getDocumentsDirectory().appendingPathComponent(StrainController.randomFilename)


	static var strains: [Strain] {
		get {
			guard let localStrains = UserDefaults.standard.object([Strain].self, with: StrainController.localStrainsKey) else {
				print("could not decode strains; returning empty strain array")
				return []
			}
			print("returning locally stored strains")
			return localStrains
		}
		set(newStrainArray) {
			print("new locally stored strains value set")
			UserDefaults.standard.set(object: newStrainArray, forKey: StrainController.localStrainsKey)
		}
	}

}



//MARK: -- Shared methods
extension StrainController {

	func add(toDatabase strains: [Strain], completion: @escaping ([Strain]?)->Void) {
		StrainController.strains.append(contentsOf: strains)
		print("added local strain to Database")
		completion(strains)
	}

	func delete(fromDatabase strain: Strain, completion: @escaping ()->Void) {
		guard let indexOfStrainInDatabase = StrainController.strains.firstIndex(of: strain) else {
			return
		}
		StrainController.strains.remove(at: indexOfStrainInDatabase)
		print("deleted strain \(strain) from Database")
		completion()

	}

	//use a Result<[Strain], Error> here
	func fetchLocalStrains(using startingArray: [Strain]?, completion: @escaping ([Strain])->Void) {
		guard let localStrains = UserDefaults.standard.object([Strain].self, with: StrainController.localStrainsKey) else {
			print("could not decode strains; returning empty strain array")
			return

		}
		print("returning locally stored strains")
		completion(localStrains)

	}


	func searchStrains(using strainName: String) -> [Strain] {
		var strainSearchResults: [Strain] = []

		for strain in StrainController.strains {
			if strain.name.lowercased().contains(strainName.lowercased()) {
				strainSearchResults.append(strain)
			}
		}


		return strainSearchResults
	}

}




//MARK: -- Needs to be moved to global extensions
func getDocumentsDirectory() -> URL {
	let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
	return paths[0]
}

