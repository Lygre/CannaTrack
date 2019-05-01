//
//  CalendarLogViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/28/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import JTAppleCalendar
import CloudKit

var doseLogDictionaryGLOBAL: [Dose] = []




class CalendarLogViewController: UIViewController {

	@IBOutlet weak var doseTableView: UITableView!

	var activityView = UIActivityIndicatorView()

	@IBOutlet weak var calendarCollectionView: JTAppleCalendarView!
	@IBOutlet weak var year: UILabel!
	@IBOutlet weak var month: UILabel!

	let tableCellIdentifier: String = "DoseCell"

	let logDoseFromCalendarSegueIdentifier = "LogDoseFromCalendarSegue"

	var doseCKRecords = [CKRecord]()

	//!!!!TODO -- need to provide getter and setters for these two properties
	fileprivate func updateDosesForSelectedDate() {
		self.dosesForDate = doseLogDictionaryGLOBAL.filter({ (someDose) -> Bool in
			let dateFromDose = Calendar.current.dateComponents([.year, .month, .day], from: someDose.timestamp)
			let currentDate = Calendar.current.dateComponents([.year, .month, .day], from: self.selectedDate ?? Date())
			return dateFromDose == currentDate

		})
		DispatchQueue.main.async {
			self.doseTableView.reloadData()
		}
		print("doses for date set")
	}

	var selectedDate: Date? {
		didSet(newlySelectedDate) {
//			updateDosesForSelectedDate()
			self.recordsForDate = doseCKRecords.filter { (someRecord) -> Bool in
				let dateFromDose = Calendar.current.dateComponents([.year, .month, .day], from: someRecord.creationDate!)
				let currentDate = Calendar.current.dateComponents([.year, .month, .day], from: newlySelectedDate ?? Date())
				return dateFromDose == currentDate
			}
		}
	}

	var recordsForDate: [CKRecord] {
		get {
			let dateRecords = doseCKRecords.filter { (someRecord) -> Bool in
				let dateFromDose = Calendar.current.dateComponents([.year, .month, .day], from: someRecord.creationDate!)
				let currentDate = Calendar.current.dateComponents([.year, .month, .day], from: self.selectedDate ?? Date())
				return dateFromDose == currentDate
			}
			return dateRecords
		}
		set {
			self.doseTableView.reloadData()
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





	fileprivate func savePrivateDatabase() {
		privateDatabase.save(doseZone) { (zone, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else { print("zone was saved")}
			}
		}
	}

	override func viewDidLoad() {
        super.viewDidLoad()

		self.doseTableView.delegate = self
		self.doseTableView.dataSource = self
		setupActivityView()
		savePrivateDatabase()
		queryCloudForDoseRecords()
//		loadDoseCalendarInfo()
		// Do any additional setup after loading the view.
		setupDoseLoggingDateFormatter()


    }

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		queryCloudForDoseRecords()
		setupCalendarView()
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
		loadDoseCalendarInfo()

	}

	@IBAction func logNewDose(_ sender: Any) {

	}

	@IBAction func refreshDoseLogDataClicked(_ sender: Any) {
		queryCloudForDoseRecords()
		print("querying cloud for dose records")
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

		let myCustomCell = cell as! CustomCell
		sharedFunctionToConfigureCell(cell: myCustomCell, cellState: cellState, date: date)
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
		//shared method to configure cell after this comment
		sharedFunctionToConfigureCell(cell: myCustomCell, cellState: cellState, date: date)
		handleCellSelected(cell: myCustomCell, cellState: cellState)
		handleCellTextColor(cell: myCustomCell, cellState: cellState)
		//return cell
		return myCustomCell
	}

	func calendar(_ calendar: JTAppleCalendarView, shouldSelectDate date: Date, cell: JTAppleCell?, cellState: CellState) -> Bool {
		if cellState.dateBelongsTo != .thisMonth {
			return false
		} else {
			return true
		}
	}


	func calendar(_ calendar: JTAppleCalendarView, didScrollToDateSegmentWith visibleDates: DateSegmentInfo) {
		let date = visibleDates.monthDates.first!.date

		formatter.dateFormat = "yyyy"
		year.text = formatter.string(from: date)

		formatter.dateFormat = "MMMM"
		month.text = formatter.string(from: date)

	}


//	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//		super.viewWillTransition(to: size, with: coordinator)
//		calendarCollectionView.collectionViewLayout.invalidateLayout()
//		calendarCollectionView.reloadData()
//	}


}



extension CalendarLogViewController {

	func sharedFunctionToConfigureCell(cell: JTAppleCell, cellState: CellState, date: Date) {

		guard let validCell = cell as? CustomCell else { return }

		let dosesOnDate = doseCKRecords.filter { (someDoseRecord) -> Bool in
			guard let dateFromRecord = someDoseRecord.creationDate else { return false }
			let dateFromDose = Calendar.current.dateComponents([.year, .month, .day], from: dateFromRecord)
			let currentDate = Calendar.current.dateComponents([.year, .month, .day], from: date)
			return dateFromDose == currentDate
		}
		if !dosesOnDate.isEmpty {
			validCell.dosesPresentIndicatorView.isHidden = false
		} else {
			validCell.dosesPresentIndicatorView.isHidden = true
		}



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
		calendarCollectionView.scrollingMode = .stopAtEachSection
		calendarCollectionView.allowsDateCellStretching = false

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

	func deleteAction(at indexPath: IndexPath) -> UIContextualAction {

		let plistDecoder = PropertyListDecoder()
		let doseRecord = doseCKRecords[indexPath.row]

//		let decodedDoseFromRecord = try? plistDecoder.decode(Dose.self, from: doseRecord["DoseData"] as! Data)
		let action2 = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
			let indexInRecords = self.doseCKRecords.firstIndex(of: doseRecord)
			guard let indexToRemove = indexInRecords else { return }
			self.doseCKRecords.remove(at: indexToRemove)
			self.deleteDoseRecordFromCloud(with: doseRecord)
			self.doseTableView.deleteRows(at: [indexPath], with: .automatic)
		}
		action2.backgroundColor = .red
		return action2

//		let dose = dosesForDate?[indexPath.row]
//		let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
//			let indexInGlobalDoses = doseLogDictionaryGLOBAL.firstIndex(where: { (doseCompletion) -> Bool in
//				return doseCompletion === dose })
//			self.dosesForDate?.remove(at: indexPath.row)
//			doseLogDictionaryGLOBAL.remove(at: indexInGlobalDoses!)
//			saveDoseCalendarInfo()
//			self.doseTableView.deleteRows(at: [indexPath], with: .automatic)
//		}
//		action.backgroundColor = .red
//		return action
	}

}


extension CalendarLogViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return recordsForDate.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier) as? DoseCalendarTableViewCell else { fatalError("could not cast a calendar table view cell") }
//		guard let doseArray = dosesForDate else { return cell }

		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .medium

		let data = recordsForDate[indexPath.row]["DoseData"] as! Data

		let propertylistDecoder = PropertyListDecoder()

		guard let doseForIndex = try? propertylistDecoder.decode(Dose.self, from: data) else { return cell }

		cell.timeLabel.text = formatter.string(from: doseForIndex.timestamp)
		cell.productLabel.text = doseForIndex.product.productType.rawValue
		cell.strainLabel.text = doseForIndex.product.strain.name


//		cell.timeLabel.text = formatter.string(from: doseArray[indexPath.row].timestamp)
//		cell.productLabel.text = doseArray[indexPath.row].product.productType.rawValue
//		cell.strainLabel.text = doseArray[indexPath.row].product.strain.name

		switch doseForIndex.product.strain.race {
		case .hybrid:
			cell.backgroundColor = UIColor(named: "hybridColor")
		case .indica:
			cell.backgroundColor = UIColor(named: "indicaColor")
		case .sativa:
			cell.backgroundColor = UIColor(named: "sativaColor")
		}

		return cell
	}


	func tableView(_ tableView: UITableView, trailingSwipeActionsConfigurationForRowAt indexPath: IndexPath) -> UISwipeActionsConfiguration? {
		let delete = deleteAction(at: indexPath)
		return UISwipeActionsConfiguration(actions: [delete])
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

extension CalendarLogViewController: UICollectionViewDelegateFlowLayout {

//	func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//		return CGSize(width: (self.calendarCollectionView.frame.size.width/3)-10, height: (self.calendarCollectionView.frame.size.height/4)-10)
//	}







}


extension CalendarLogViewController {

	fileprivate func queryCloudForDoseRecords() {

		let query = CKQuery(recordType: "Dose", predicate: NSPredicate(value: true))
		self.activityView.startAnimating()
		privateDatabase.perform(query, inZoneWith: nil) { (recordsRetrieved, error) in

			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					self.doseCKRecords = recordsRetrieved ?? []
					print("dose records loaded: # \(recordsRetrieved?.count)")
					self.doseTableView.reloadData()
					self.activityView.stopAnimating()
				}


				
			}
		}

	}



	fileprivate func deleteDoseRecordFromCloud(with record: CKRecord) {
		let recordID = record.recordID

		privateDatabase.delete(withRecordID: recordID) { (deletedRecordID, error) in
			DispatchQueue.main.async {
				if let error = error {
					print(error)
				} else {
					print("Dose Record was deleted from ProductDetailViewController.swift method")
					self.doseTableView?.reloadData()

				}
			}

		}
	}


	fileprivate func setupActivityView() {
		activityView.center = self.view.center
		activityView.hidesWhenStopped = true
		activityView.style = .gray

		self.view.addSubview(activityView)
	}

}
