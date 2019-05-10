//
//  Strains.swift
//  CannaTracker
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit


var masterStrainDatabase: [Strain] = [] {
	didSet(updatedDatabase) {
		saveStrainDatabaseData(strainDB: updatedDatabase)
	}
}

func saveStrainDatabaseData(strainDB: [Strain]) {

	let propertyListEncoder = PropertyListEncoder()

	do {
		let strainData: [Strain] = masterStrainDatabase
		let data = try propertyListEncoder.encode(strainData)
		UserDefaults.standard.set(data, forKey: "strainDatabase")
	}
	catch {
		print(error)
	}

}

func loadSavedStrainDatabase() {

	let propertyListDecoder = PropertyListDecoder()

	do {
		if let da = UserDefaults.standard.data(forKey: "strainDatabase") {
			let stored = try propertyListDecoder.decode([Strain].self, from: da)
			masterStrainDatabase = stored
		}
	}
	catch {
		print(error)
	}


}

struct BaseStrain: Decodable, Hashable {

	let id: Int
	let name: String
	let race: StrainVariety
	let desc: String?
	var flavors: String?
	var effects: Effects?


	func sendRequestForEffects(forStrain id: Int, completion: @escaping ((Effects) ->Void)) {
		let urlForId = "https://strainapi.evanbusse.com/oJ5GvWc/strains/data/effects/" + String("\(id)").trimmingCharacters(in: .whitespaces)
		guard let urlObj = URL(string: urlForId) else { return }

		URLSession.shared.dataTask(with: urlObj) {(data, response, error) in

			guard let data = data else { return }

			do {
				let effectsDictionary = try JSONDecoder().decode(Effects.self, from: data)
				//				self.effects = intermediateBasestrainArray.effects
				completion(effectsDictionary)
				print("effect parsed from strain database")
			} catch let jsonError {
				print("Error serializing json: ", jsonError)
			}

			}.resume()
	}

	mutating func getDetails() {
		let strainID = id
		var effectsToSet: Effects?
		if effects == nil {
			sendRequestForEffects(forStrain: strainID, completion: { effectsParsed in
				print(effectsParsed)
				effectsToSet = effectsParsed
			})
			self.effects = effectsToSet
			print(self)
		}
	}
}


struct Effect: Decodable, Hashable {

	enum EffectName: String, Decodable {
		case relaxed = "Relaxed"
		case dizzy = "Dizzy"
		case hungry = "Hungry"
		case euphoric = "Euphoric"
		case happy = "Happy"
		case depression = "Depression"
		case insomnia = "Insomnia"
		case pain = "Pain"
		case stress = "Stress"
		case cramps = "Cramps"
		case creative = "Creative"
		case energetic = "Energetic"
		case talkative = "Talkative"
		case lackOfApetite = "Lack of Appetite"
		case nausea = "Nausea"
		case dryMouth = "Dry Mouth"
		case sleepy = "Sleepy"
		case fatigue = "Fatigue"
		case headaches = "Headaches"
		case headache = "Headache"
		case uplifted = "Uplifted"
		case tingly = "Tingly"
		case dryEyes = "Dry Eyes"
		case paranoid = "Paranoid"
		case focused = "Focused"
		case eyePressure = "Eye Pressure"
		case anxious = "Anxious"
		case giggly = "Giggly"
		case aroused = "Aroused"
		case inflammation = "Inflammation"
		case spasticity = "Spasticity"
		case seizures = "Seizures"
		case muscleSpasms = "Muscle Spasms"
	}

	enum EffectCategory: String, Decodable {
		case positive = "positive"
		case negative = "negative"
		case medical = "medical"
	}

	var effect: EffectName
	var type: EffectCategory

}

struct Effects: Encodable, Decodable, Hashable {
	var positive: [String]?
	var negative: [String]?
	var medical: [String]?

}

enum StrainVariety: String, Encodable, Decodable, Hashable {
	case hybrid = "hybrid"
	case indica = "indica"
	case sativa = "sativa"
}

class Strain: Codable {
	let id: Int
	let name: String
	let race: StrainVariety
	let desc: String?
	//	var flavors: ???
	var effects: Effects?
	var flavors: [String]?

	init(id: Int, name: String, race: StrainVariety, description: String?) {
		self.id = id
		self.name = name
		self.race = race
		self.desc = description
		self.effects = nil
//		sendRequestForEffects(forStrain: id, completion: { effectParsed in })


	}






	/*
	func sendRequestForEffects(forStrain id: Int, completion: @escaping ((Effects) ->Void)) {
		let urlForId = "https://strainapi.evanbusse.com/oJ5GvWc/strains/data/effects/" + String("\(id)").trimmingCharacters(in: .whitespaces)
		guard let urlObj = URL(string: urlForId) else { return }

		URLSession.shared.dataTask(with: urlObj) {(data, response, error) in

			guard let data = data else { return }

			do {
				let effectsDictionary = try JSONDecoder().decode(Effects.self, from: data)
				//				self.effects = intermediateBasestrainArray.effects
				self.effects = effectsDictionary
				completion(effectsDictionary)
				print("effect parsed from strain database")
			} catch let jsonError {
				print("Error serializing json: ", jsonError)
			}

			}.resume()
	}
	*/


}


extension Strain: Equatable {

	static func == (lhs: Strain, rhs: Strain) -> Bool {
		return lhs.id == rhs.id && lhs.name == rhs.name && lhs.race == rhs.race
	}

}

extension Strain: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(id)
		hasher.combine(name)
		hasher.combine(race)

	}
}

func searchStrains(using strainName: String) -> [Strain] {
	var strainSearchResults: [Strain] = []

	let strainDatabase = masterStrainDatabase
	for strain in strainDatabase {
		if strain.name.lowercased().contains(strainName.lowercased()) {
			strainSearchResults.append(strain)
		}
	}


	return strainSearchResults
}


//----playing around with something here

struct StrainInformation: Codable {
	var id: Int
	var race: String
	var flavors: [String]?
	var effects: [String: [String]]?

}

struct StrainTestStruct: Codable {

}
