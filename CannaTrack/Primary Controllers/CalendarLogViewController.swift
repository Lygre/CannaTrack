//
//  CalendarLogViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/28/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import JTAppleCalendar


var doseLogDictionaryGLOBAL: [Dose] = []






class CalendarLogViewController: UIViewController {

	@IBOutlet weak var doseTableView: UITableView!

	@IBOutlet weak var calendarCollectionView: JTAppleCalendarView!
	@IBOutlet weak var year: UILabel!
	@IBOutlet weak var month: UILabel!

	let tableCellIdentifier: String = "DoseCell"

	let logDoseFromCalendarSegueIdentifier = "LogDoseFromCalendarSegue"

	//!!!!TODO -- need to provide getter and setters for these two properties
	var selectedDate: Date? {
		didSet {
			self.dosesForDate = doseLogDictionaryGLOBAL.filter({ (someDose) -> Bool in
				let dateFromDose = Calendar.current.dateComponents([.year, .month, .day], from: someDose.timestamp)
				let currentDate = Calendar.current.dateComponents([.year, .month, .day], from: self.selectedDate ?? Date())
				return dateFromDose == currentDate

			})
			print("doses for date set")
		}
	}

	var dosesForDate: [Dose]? {
		didSet {
			print(self.dosesForDate?.debugDescription)
			DispatchQueue.main.async {
				self.doseTableView.reloadData()
			}
		}
	}

	let outsideMonthColor = UIColor.lightGray

	let monthColor = UIColor.purple
	let selectedMonthColor = UIColor.white

	let formatter = DateFormatter()

	let logFormatter = DateFormatter()





	override func viewDidLoad() {
        super.viewDidLoad()

		self.doseTableView.delegate = self
		self.doseTableView.dataSource = self

		loadDoseCalendarInfo()
		// Do any additional setup after loading the view.
		setupDoseLoggingDateFormatter()

    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		calendarCollectionView.collectionViewLayout.invalidateLayout()
		calendarCollectionView.reloadData()

	}

	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		selectedDate = Date()
		calendarCollectionView.scrollToDate(Date(), triggerScrollToDateDelegate: true, animateScroll: true, preferredScrollPosition: nil, extraAddedOffset: 0) {
			self.calendarCollectionView.selectDates([Date()])
		}

	}

	@IBAction func unwindToDoseCalendar(unwindSegue: UIStoryboardSegue) {

	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

	@IBAction func saveDoseLogClicked(_ sender: Any) {
		saveDoseCalendarInfo()
	}


	@IBAction func printDoseLogClicked(_ sender: Any) {
		print(doseLogDictionaryGLOBAL.debugDescription)
		loadLocalDoseCalendarInfo()

	}

	@IBAction func logNewDose(_ sender: Any) {

	}




}


extension CalendarLogViewController: JTAppleCalendarViewDataSource {


	func configureCalendar(_ calendar: JTAppleCalendarView) -> ConfigurationParameters {

		formatter.dateFormat = "yyy MM dd"
		formatter.timeZone = Calendar.current.timeZone
		formatter.locale = Calendar.current.locale

		let startDate = formatter.date(from: "2017 01 01")!
		let endDate = formatter.date(from: "2022 01 01")!


		let configs = ConfigurationParameters(startDate: startDate, endDate: endDate, numberOfRows: 6, calendar: .current, generateInDates: .forAllMonths, generateOutDates: .tillEndOfRow, firstDayOfWeek: .sunday, hasStrictBoundaries: true)

//		let configs = ConfigurationParameters(startDate: startDate, endDate: endDate)

		return configs
	}


}


extension CalendarLogViewController: JTAppleCalendarViewDelegate {
	func calendar(_ calendar: JTAppleCalendarView, willDisplay cell: JTAppleCell, forItemAt date: Date, cellState: CellState, indexPath: IndexPath) {

	}

	func calendar(_ calendar: JTAppleCalendarView, didSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
		selectedDate = date
		handleCellSelected(cell: cell, cellState: cellState)
		handleCellTextColor(cell: cell, cellState: cellState)
	}

	func calendar(_ calendar: JTAppleCalendarView, didDeselectDate date: Date, cell: JTAppleCell?, cellState: CellState) {
		handleCellSelected(cell: cell, cellState: cellState)
		handleCellTextColor(cell: cell, cellState: cellState)
	}

	func calendar(_ calendar: JTAppleCalendarView, cellForItemAt date: Date, cellState: CellState, indexPath: IndexPath) -> JTAppleCell {
		let myCustomCell = calendar.dequeueReusableJTAppleCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCell
		myCustomCell.dateLabel.text = cellState.text
		myCustomCell.layer.cornerRadius = myCustomCell.frame.width / 2
		myCustomCell.layer.masksToBounds = true
		//shared method to configure cell after this comment
		handleCellSelected(cell: myCustomCell, cellState: cellState)
		handleCellTextColor(cell: myCustomCell, cellState: cellState)
		//return cell
		return myCustomCell
	}



	func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
		let date = visibleDates.monthDates.first!.date

		formatter.dateFormat = "yyyy"
		year.text = formatter.string(from: date)

		formatter.dateFormat = "MMMM"
		month.text = formatter.string(from: date)

	}





}



extension CalendarLogViewController {

	func sharedFunctionToConfigureCell(cell: JTAppleCell, cellState: CellState, date: Date) {
		print("do nothing; not implemented")

	}


	func handleCellSelected(cell: JTAppleCell?, cellState: CellState) {
		guard let validCell = cell as? CustomCell else { return }
		if cellState.isSelected {
			validCell.selectedView.isHidden = false
		} else {
			validCell.selectedView.isHidden = true
		}
	}

	func handleCellTextColor(cell: JTAppleCell?, cellState: CellState) {
		guard let validCell = cell as? CustomCell else { return }
		if cellState.isSelected {
			validCell.dateLabel.textColor = selectedMonthColor
		} else {
			if cellState.dateBelongsTo == .thisMonth {
				validCell.dateLabel.textColor = monthColor
				validCell.backgroundColor = UIColor(named: "indicaColor")
			} else {
				validCell.dateLabel.textColor = outsideMonthColor
				validCell.backgroundColor = UIColor.white
			}
		}
	}



	func setupCalendarView() {
		calendarCollectionView.minimumLineSpacing = 0
		calendarCollectionView.minimumInteritemSpacing = 0

		calendarCollectionView.visibleDates { visibleDates in
			self.setupViewsOfCalendar(from: visibleDates)
		}
	}

	func setupViewsOfCalendar(from visibleDates: DateSegmentInfo) {
		let date = visibleDates.monthDates.first!.date

		formatter.dateFormat = "yyyy"
		year.text = formatter.string(from: date)

		formatter.dateFormat = "MMMM"
		month.text = formatter.string(from: date)

	}

}


extension CalendarLogViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return dosesForDate?.count ?? 0
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier) as? DoseCalendarTableViewCell else { fatalError("could not cast a calendar table view cell") }
		guard let doseArray = dosesForDate else { return cell }
		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .medium
		cell.timeLabel.text = formatter.string(from: doseArray[indexPath.row].timestamp)
		cell.productLabel.text = doseArray[indexPath.row].product.productType.rawValue
		cell.strainLabel.text = doseArray[indexPath.row].product.strain.name

		switch doseArray[indexPath.row].product.strain.race {
		case .hybrid:
			cell.backgroundColor = UIColor(named: "hybridColor")
		case .indica:
			cell.backgroundColor = UIColor(named: "indicaColor")
		case .sativa:
			cell.backgroundColor = UIColor(named: "sativaColor")
		}

		return cell
	}




}


extension CalendarLogViewController {

	fileprivate func setupDoseLoggingDateFormatter() {
		logFormatter.locale = .current
		logFormatter.timeZone = .current
		logFormatter.calendar = .current
		logFormatter.dateFormat = "yyy-MM-dd"
	}


}

extension CalendarLogViewController {

	func loadLocalDoseCalendarInfo() {
		let propertyListDecoder = PropertyListDecoder()
		do {
			if let da = UserDefaults.standard.data(forKey: "doseLogData") {
				let stored = try propertyListDecoder.decode([Dose].self, from: da)
				print(stored)
				doseLogDictionaryGLOBAL = stored
			}
		}
		catch {
			print(error)
		}
	}

	func saveDoseCalendarInfo() {
		let propertyListEncoder = PropertyListEncoder()
		do {
			let doseLogData: [Dose] = doseLogDictionaryGLOBAL
			let data = try propertyListEncoder.encode(doseLogData)
			UserDefaults.standard.set(data, forKey: "doseLogData")
		}
		catch {
			print(error)
		}
	}





}
