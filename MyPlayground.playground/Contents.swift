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

