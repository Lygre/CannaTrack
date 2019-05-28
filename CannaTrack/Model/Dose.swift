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
	var doseImage: UIImage?
	var recordID: CKRecord.ID?
	var encodedSystemFields: Data?

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

	init(timestamp: Date, product: Product, mass: Double, route: AdministrationRoute?, imageForDose: UIImage, otherProductDictionary: [Product: Double]) {
		self.timestamp = timestamp
		self.product = product
		self.mass = mass
		self.administrationRoute = route
		self.otherProducts = otherProductDictionary
		self.doseImage = imageForDose
	}

	required init(from decoder: Decoder) throws {
		let values = try decoder.container(keyedBy: CodingKeys.self)
		timestamp = try values.decode(Date.self, forKey: .timestamp)
		product = try values.decode(Product.self, forKey: .product)
		mass = try values.decode(Double.self, forKey: .mass)
		administrationRoute = try values.decode(AdministrationRoute.self, forKey: .administrationRoute)
		otherProducts = try values.decode([Product: Double].self, forKey: .otherProducts)

		/*
		let imgURL = try values.decode(URL.self, forKey: .doseImage)
		let imgPath = imgURL.path
		doseImage = UIImage(contentsOfFile: imgPath)
		*/

	}

	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(timestamp, forKey: .timestamp)
		try container.encode(product, forKey: .product)
		try container.encode(mass, forKey: .mass)
		try container.encode(administrationRoute, forKey: .administrationRoute)
		try container.encode(otherProducts, forKey: .otherProducts)
		/*
		//encode image; going to try handling this separately with the Record encoding; did not do this with product
		let img = doseImage
		let manager = FileManager.default
		let dir = manager.urls(for: .documentDirectory, in: .userDomainMask)
		let file = dir[0].appendingPathComponent((timestamp.description(with: .current)) + product.productType.rawValue + self.product.strain.name)
		try img?.jpegData(compressionQuality: 0.5)?.write(to: file, options: .atomic)
		let imgURL = NSURL.fileURL(withPath: file.path)

		try container.encode(imgURL, forKey: .doseImage)
		*/
	}


}


extension Dose {

	enum AdministrationRoute: String, Codable, CaseIterable {
		case oral = "Oral"
		case inhalation = "Inhalation"
	}

	enum CodingKeys: String, CodingKey {
		case timestamp
		case product
		case mass
		case administrationRoute
		case otherProducts
		case doseImage
	}


}


extension Dose {

	func logDoseToCalendar(_ dose: Dose) {
		let userCalendar = Calendar.current
		let requestedComponents: Set<Calendar.Component> = [.year, .month, .day]
		let dateTimeComponents = userCalendar.dateComponents(requestedComponents, from: dose.timestamp)
		let componentsForDateKey: DateComponents = DateComponents(calendar: .current, timeZone: .current, era: nil, year: dateTimeComponents.year, month: dateTimeComponents.month, day: dateTimeComponents.day, hour: nil, minute: nil, second: nil, nanosecond: nil, weekday: nil, weekdayOrdinal: nil, quarter: nil, weekOfMonth: nil, weekOfYear: nil, yearForWeekOfYear: nil)
//		guard let constructedDateKey: Date = userCalendar.date(from: componentsForDateKey) else { return }

//		doseLogDictionaryGLOBAL.append(dose)
		//we should have the dose handle logging itself to CloudKit, but this needs revising and revisiting at a later time
		saveDoseCalendarInfo()


	}

	static func replicateDoseWithCurrentTime(using referenceDose: Dose) -> Dose {
		referenceDose.timestamp = Date()
		referenceDose.recordID = nil
		referenceDose.doseImage = nil
		return referenceDose
	}

}


extension Dose {

	func encodeDoseAsCKRecordValue() -> CKRecordValue? {
		let plistEncoder = PropertyListEncoder()
		let data = try? plistEncoder.encode(self)
		return data as CKRecordValue?
	}


	func toCKRecord() -> CKRecord {

		var record: CKRecord!

		if let encodedSystemFields = self.encodedSystemFields {
			guard let coder = try? NSKeyedUnarchiver(forReadingFrom: encodedSystemFields) else { fatalError("could not create keyed unarchiver") }
			coder.requiresSecureCoding = true

			if let recordFromSystemFields = CKRecord(coder: coder) {
				record = recordFromSystemFields
				print("decoded record from system fields")
			} else { print("could not create record with system fields in toCKRecord method of Dose.") }
		} else {
			if let doseRecordID = self.recordID {
				record = CKRecord(recordType: "Dose", recordID: doseRecordID)
			} else {
				record = CKRecord(recordType: "Dose", zoneID: CloudKitManager.doseZoneID)
			}
		}


//		var record: CKRecord!
//		if let doseRecordID = self.recordID {
//			record = CKRecord(recordType: "Dose", recordID: doseRecordID)
//		} else {
//			record = CKRecord(recordType: "Dose", zoneID: CloudKitManager.doseZoneID)
//		}


		if let recordValue = self.encodeDoseAsCKRecordValue() {

			let manager = FileManager.default
			let nsDocumentDirectory = FileManager.SearchPathDirectory.documentDirectory
			let nsUserDomainMask = FileManager.SearchPathDomainMask.userDomainMask

			let paths = manager.urls(for: nsDocumentDirectory, in: nsUserDomainMask)

			if paths.count > 0 {
				let dirPath = paths[0]
				let writePath = dirPath.appendingPathComponent((timestamp.description(with: .current)) + self.product.productType.rawValue + self.product.strain.name)
				let doseImage: UIImage = {
					let imageToReturn: UIImage = UIImage(imageLiteralResourceName: "cannaleaf.png")
					guard let image = self.doseImage else { return imageToReturn }
					return image
				}()

				try? doseImage.pngData()?.write(to: writePath)
				let doseImageData: CKAsset? = CKAsset(fileURL: NSURL(fileURLWithPath: writePath.path) as URL)
				record.setObject(doseImageData, forKey: "DoseImageData")
			}
			record.setObject(recordValue, forKey: "DoseData")

		}
		print("encoded dose as a CKRecord from Dose method toCKRecord")
		return record
	}


	static func fromCKRecord(record: CKRecord) -> Dose? {
		let plistDecoder = PropertyListDecoder()
		guard let doseData = record["DoseData"] as? Data else {
			return nil
		}
		guard let decodedDose = try? plistDecoder.decode(Dose.self, from: doseData) else {
			return nil
		}
		guard let asset = record["DoseImageData"] as? CKAsset else {
			print("Image missing from Dose record")
			return nil
		}
		guard let imageData = NSData(contentsOf: asset.fileURL!) else {
			print("invalid image from dose")
			return nil
		}
		let image = UIImage(data: imageData as Data)
		decodedDose.doseImage = image

		//encoding system fields locally upon receiving newRecord
		let coder = NSKeyedArchiver.init(requiringSecureCoding: true)
		record.encodeSystemFields(with: coder)
		coder.finishEncoding()
		decodedDose.encodedSystemFields = coder.encodedData
		//end of encoding system fields
		decodedDose.recordID = record.recordID
		print("success decoding dose from record in Dose.swift fromCKRecord method")
		return decodedDose
	}

}

extension Dose: Equatable {

	static func == (lhs: Dose, rhs: Dose) -> Bool {
		return lhs.timestamp == rhs.timestamp && lhs.product == rhs.product && lhs.otherProducts == rhs.otherProducts && lhs.mass == rhs.mass
	}

}
