import UIKit
import CloudKit

var str = "Hello, playground"

let startDate = Date()

let formatter = DateFormatter()

formatter.locale = .current
formatter.timeZone = .current
formatter.calendar = .current

formatter.dateFormat = "yyy-MM-dd"
var dateString = "2016-03-02"


var date = formatter.date(from: dateString)

let userCalendar = Calendar.current

let requestedComponents: Set<Calendar.Component> = [.year, .month, .day]

let dateTimeComponents = userCalendar.dateComponents(requestedComponents, from: startDate)
dateTimeComponents.year
dateTimeComponents.month
dateTimeComponents.day

let dictionaryEntry = String(dateTimeComponents.year!) + String(dateTimeComponents.month!) + String(dateTimeComponents.day!)
var dateComponents = DateComponents()
dateComponents.year = dateTimeComponents.year
dateComponents.month = dateTimeComponents.month
dateComponents.day = dateTimeComponents.day

let someDateTime = userCalendar.date(from: dateComponents)

func saveUserData(with dataToWrite: [String]) {
	let propertyListEncoder = PropertyListEncoder()
	do {
		let data = try propertyListEncoder.encode(dataToWrite)
		UserDefaults.standard.set(data, forKey: "data")
	}
	catch {
		print(error)
	}
}

func loadProductInventoryFromUserData() -> [String] {
	let propertyListDecoder = PropertyListDecoder()
	var storedData: [String] = []
	do {
		if let da = UserDefaults.standard.data(forKey: "data") {
			let stored = try propertyListDecoder.decode([String].self, from: da)
			storedData = stored
		}
	}
	catch {
		print(error)
	}
	return storedData
}

func saveUserDataTextField(with dataToWriteFromTextField: String) {
	let propertyListEncoder = PropertyListEncoder()
	var savedData: [String] = loadProductInventoryFromUserData()

	savedData.append(dataToWriteFromTextField)

	do {
		let data = try propertyListEncoder.encode(savedData)
		UserDefaults.standard.set(data, forKey: "data")
	}
	catch {
		print(error)
	}
}

let dates: [Date] = [Date(), Date(timeIntervalSinceReferenceDate: TimeInterval(exactly: 8.0)!)]
dates.sorted { (date, otherDate) -> Bool in
	return date > otherDate
}

var record: CKRecord?
var data: Data?

struct CstObj {
	var name: String
}

func saveDoseToCloud() {

	let newDose = CKRecord(recordType: "Dose")

//	let objToEncode = CstObj(name: "myName")

	//archive the ckrecord to nsdata
	var archivedData = Data()
	print(archivedData)
	let archiver = NSKeyedArchiver(requiringSecureCoding: true)
	newDose["content"] = Data()
	newDose.encodeSystemFields(with: archiver)
	archiver.finishEncoding()
	archivedData = archiver.encodedData
	//store data locally? where?
	print(archivedData)

	data = archivedData

}


func loadDoseFromData(data: Data) -> CKRecord? {
	var record: CKRecord?

	let unarchiver = try! NSKeyedUnarchiver(forReadingFrom: data)
	unarchiver.requiresSecureCoding = true
	do {
		record = CKRecord(coder: unarchiver)
	}


	return record

}
saveDoseToCloud()

loadDoseFromData(data: data!)

var array: [Int] = []

class Object {

	var array: [Int]? {
		willSet(oldArray) {
			print(oldArray)
		}
	}

	init(with array: [Int]?) {
		self.array = array
	}

	init() {
		self.array = []
	}

	func addNumbersToArray(numbers: Int...) {
		self.array?.append(contentsOf: numbers)
	}

}

let object = Object()
object.addNumbersToArray(numbers: 1)
object.addNumbersToArray(numbers: 2)
