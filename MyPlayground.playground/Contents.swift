import UIKit

var str = "Hello, playground"

let startDate = Date()

let formatter = DateFormatter()

formatter.locale = .current
formatter.timeZone = .current
formatter.calendar = .current

formatter.dateFormat = "yyy-MM-dd"
var dateString = "2016-01-01"
var date = formatter.date(from: dateString)
