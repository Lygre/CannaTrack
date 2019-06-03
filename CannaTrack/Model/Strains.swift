//
//  Strains.swift
//  CannaTracker
//
//  Created by Hugh Broome on 2/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit




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
	var favorite: Bool
	var effects: Effects?
	var flavors: [String]?

	init(id: Int, name: String, race: StrainVariety, description: String?) {
		self.id = id
		self.name = name
		self.race = race
		self.desc = description
		self.favorite = false
		self.effects = nil


	}

	required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)

		id = try values.decode(Int.self, forKey: .id)
		name = try values.decode(String.self, forKey: .name)
		race = try values.decode(StrainVariety.self, forKey: .race)
		desc = try values.decode(String.self, forKey: .desc)
		favorite = try values.decode(Bool.self, forKey: .favorite)
		effects = try values.decode(Effects.self, forKey: .effects)
		flavors = try values.decode([String].self, forKey: .flavors)

	}


	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(id, forKey: .id)
		try container.encode(name, forKey: .name)
		try container.encode(race, forKey: .race)
		try container.encode(desc, forKey: .desc)
		try container.encode(favorite, forKey: .favorite)
		try container.encode(effects, forKey: .effects)
		try container.encode(flavors, forKey: .flavors)

	}

	enum CodingKeys: String, CodingKey {
		case id
		case name
		case race
		case desc
		case favorite
		case effects
		case flavors
	}


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





//----playing around with something here

struct StrainInformation: Codable {
	var id: Int
	var race: String
	var flavors: [String]?
	var effects: [String: [String]]?

}

struct StrainTestStruct: Codable {

}
