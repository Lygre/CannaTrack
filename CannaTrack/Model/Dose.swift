//
//  Dose.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/29/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit
import JTAppleCalendar
import CloudKit

class Dose: Codable {




	var timestamp: Date!
	var product: Product!
	var mass: Double!
	var administrationRoute: AdministrationRoute?
	var otherProducts: [Product: Double]!

	init(timestamp: Date, product: Product, mass: Double, route: AdministrationRoute?) {
		self.timestamp = timestamp
		self.product = product
		self.mass = mass
		self.administrationRoute = route
		self.otherProducts = [:]
	}

	init(timestamp: Date, product: Product, mass: Double, route: AdministrationRoute?, otherProductDictionary: [Product: Double]) {
		self.timestamp = timestamp
		self.product = product
		self.mass = mass
		self.administrationRoute = route
		self.otherProducts = otherProductDictionary
	}

	required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		timestamp = try values.decode(Date.self, forKey: .timestamp)
		product = try values.decode(Product.self, forKey: .product)
		mass = try values.decode(Double.self, forKey: .mass)
		administrationRoute = try values.decode(AdministrationRoute.self, forKey: .administrationRoute)
		otherProducts = try values.decode([Product: Double].self, forKey: .otherProducts)
	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(timestamp, forKey: .timestamp)
		try container.encode(product, forKey: .product)
		try container.encode(mass, forKey: .mass)
		try container.encode(administrationRoute, forKey: .administrationRoute)
		try container.encode(otherProducts, forKey: .otherProducts)
	}


}


extension Dose {

	enum AdministrationRoute: String, Codable {
		case oral = "Oral"
		case inhalation = "Inhalation"
	}

	enum CodingKeys: String, CodingKey {
		case timestamp
		case product
		case mass
		case administrationRoute
		case otherProducts
	}


}


extension Dose {

	func logDoseToCalendar(_ dose: Dose) {
		let userCalendar = Calendar.current
		let requestedComponents: Set<Calendar.Component> = [.year, .month, .day]
		let dateTimeComponents = userCalendar.dateComponents(requestedComponents, from: dose.timestamp)
		let componentsForDateKey: DateComponents = DateComponents(calendar: .current, timeZone: .current, era: nil, year: dateTimeComponents.year, month: dateTimeComponents.month, day: dateTimeComponents.day, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
//		guard let constructedDateKey: Date = userCalendar.date(from: componentsForDateKey) else { return }

		doseLogDictionaryGLOBAL.append(dose)
		//we should have the dose handle logging itself to CloudKit, but this needs revising and revisiting at a later time
		saveDoseCalendarInfo()


	}


//	func saveDoseLogToCloud() {
//		let newDose = CKRecord(recordType: "Dose")
//
//
//		//archive the ckrecord to nsdata
//		var archivedData = Data()
//
//		let archiver = NSKeyedArchiver(requiringSecureCoding: true)
//		let encoder = PropertyListEncoder()
//
//		let doseData: Data = {
//			do {
//				let data = try encoder.encode(self)
//				return data
//			}
//			catch { print(error); return Data() }
//		}()
//
//		newDose["DoseData"] = doseData
//		newDose.encodeSystemFields(with: archiver)
//		newDose.encode(with: archiver)
//		archiver.finishEncoding()
//		//this works, and the encoded CKRecord data is right here [archivedData]
//		archivedData = archiver.encodedData
//
//		//		UserDefaults.standard.set(archivedData, forKey: )
//
//
//		let database = CKContainer.default().privateCloudDatabase
//
//		database.save(newDose) { (record, error) in
//			if error == nil {
//				print("dose saved to private database in Dose.swift method")
//			}
//		}
//
//	}

	func saveDoseLogToCloud() {
		let newDose = CKRecord(recordType: "Dose")


		//archive the ckrecord to nsdata
		let encoder = PropertyListEncoder()

		let doseData: CKRecordValue = {
			do {
				let data = try encoder.encode(self)
				return data as CKRecordValue
			}
			catch { print(error); return Data() as CKRecordValue }
		}()

		newDose.setObject(doseData, forKey: "DoseData")
//		privateDatabase.save
		privateDatabase.save(doseZone) { (recordZone, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					print("Entire DoseZone Saved by Dose.swift method")
				}
			}
		}


		privateDatabase.save(newDose) { (record, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					print("Record was saved in Private DB by Dose.swift method")
				}
			}
		}
	}




}
