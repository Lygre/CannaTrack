import UIKit

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
