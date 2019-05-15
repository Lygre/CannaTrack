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


	//add button stuff
	@IBOutlet var addButton: AddProductFloatingButton!

	var viewPropertyAnimator: UIViewPropertyAnimator!

	var dynamicAnimator: UIDynamicAnimator!

	var snapBehavior: UISnapBehavior!

	var originalAddButtonPosition: CGPoint!

	//------------------------------

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
			print(self.dosesForDate?.debugDescription ?? "No doses for selected Date")
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
//		savePrivateDatabase()
		queryCloudForDoseRecords()
//		loadDoseCalendarInfo()
		// Do any additional setup after loading the view.
		setupDoseLoggingDateFormatter()

		//add button setup
		self.addButton.addButtonDelegate = self
//		self.addButton.addTarget(, action: <#T##Selector#>, for: <#T##UIControl.Event#>)
		self.viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
			self.addButton.transform = .init(scaleX: 2.0, y: 2.0)
		})
		originalAddButtonPosition = CGPoint(x: view.frame.width - 25 - ((view.frame.width * 0.145) / 2.0), y: view.frame.height - 60 - ((view.frame.height * 0.067) / 2.0))
		setupAddButtonPanGesture(button: addButton)
		dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
//		dynamicAnimator.delegate = self
		snapBehavior = UISnapBehavior(item: addButton, snapTo: originalAddButtonPosition)
		snapBehavior.damping = 0.8
		dynamicAnimator.addBehavior(snapBehavior)

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

		originalAddButtonPosition = CGPoint(x: view.frame.width - 25 - ((view.frame.width * 0.145) / 2.0), y: view.frame.height - 60 - ((view.frame.height * 0.067) / 2.0))
		snapAddButtonToInitialPosition(button: addButton, animator: viewPropertyAnimator, dynamicAnimator: dynamicAnimator)

	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {

		calendarCollectionView?.viewWillTransition(to: size, with: coordinator, anchorDate: selectedDate)

		originalAddButtonPosition = CGPoint(x: size.width - 25 - ((size.width * 0.145) / 2.0), y: size.height - 60 - ((size.height * 0.067) / 2.0))
		dynamicAnimator.removeBehavior(snapBehavior)
		snapBehavior = UISnapBehavior(item: addButton, snapTo: originalAddButtonPosition)
		dynamicAnimator.addBehavior(snapBehavior)
		print("view is transitioning orientation")
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
		calendarCollectionView.allowsDateCellStretching = true

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

		let doseRecord = doseCKRecords[indexPath.row]

		let action = UIContextualAction(style: .destructive, title: "Delete") { (action, view, completion) in
			let indexInRecords = self.doseCKRecords.firstIndex(of: doseRecord)
			guard let indexToRemove = indexInRecords else { return }
			self.doseCKRecords.remove(at: indexToRemove)
			self.deleteDoseRecordFromCloud(with: doseRecord)
			self.doseTableView.deleteRows(at: [indexPath], with: .automatic)
		}
		action.backgroundColor = .red
		return action

	}

}


extension CalendarLogViewController: UITableViewDelegate, UITableViewDataSource {
	func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return recordsForDate.count
	}

	func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		guard let cell = tableView.dequeueReusableCell(withIdentifier: tableCellIdentifier) as? DoseCalendarTableViewCell else { fatalError("could not cast a calendar table view cell") }

		let formatter = DateFormatter()
		formatter.dateStyle = .none
		formatter.timeStyle = .medium

		let data = recordsForDate[indexPath.row]["DoseData"] as! Data
		let propertylistDecoder = PropertyListDecoder()

		guard let doseForIndex = try? propertylistDecoder.decode(Dose.self, from: data) else { return cell }

		cell.timeLabel.text = formatter.string(from: doseForIndex.timestamp)
		cell.productLabel.text = doseForIndex.product.productType.rawValue
		cell.strainLabel.text = doseForIndex.product.strain.name

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
	//nothing implemented, nor do I know that anything needs to be

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
					print("dose records loaded: # \(recordsRetrieved?.count ?? 0)")
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

extension CalendarLogViewController: AddButtonDelegate {


	func animateTouchesBegan(button: AddProductFloatingButton, animator: UIViewPropertyAnimator) {
		viewPropertyAnimator = animator
		viewPropertyAnimator.startAnimation()
	}

	func snapAddButtonToInitialPosition(button: AddProductFloatingButton, animator: UIViewPropertyAnimator, dynamicAnimator: UIDynamicAnimator) {
		viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
			self.addButton.transform = .identity
		})
		viewPropertyAnimator.startAnimation()

		dynamicAnimator.removeBehavior(snapBehavior)
		snapBehavior = UISnapBehavior(item: addButton, snapTo: originalAddButtonPosition)
		dynamicAnimator.addBehavior(snapBehavior)
	}

	func setupAddButtonPanGesture(button: AddProductFloatingButton) {
		let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanForAddButton(recognizer:)))
		addButton.addGestureRecognizer(pan)
		addButton.isUserInteractionEnabled = true
	}


}

//objc methods
extension CalendarLogViewController {

	func stopAndFinishCurrentAnimations() {
		viewPropertyAnimator.stopAnimation(false)
		viewPropertyAnimator.finishAnimation(at: .end)
	}

	@objc func handlePanForAddButton(recognizer: UIPanGestureRecognizer) {
		let location = recognizer.location(in: self.view)
		let translation = recognizer.translation(in: self.view)
		//create secondary location variable to get location on the recognizer in the tableview, then check using this

		switch recognizer.state {
		case .changed:
			addButton.center = CGPoint(x: addButton.center.x + translation.x, y: addButton.center.y + translation.y)
			recognizer.setTranslation(.zero, in: view)

			guard let indexPath = self.calendarCollectionView.indexPathForItem(at: location), let dateCell = self.calendarCollectionView.cellForItem(at: indexPath) as? CustomCell else {
				print("no date cell")
				return
			}
			addButton.sendActions(for: .overEligibleContainerRegion)
			print("collision with \(dateCell.debugDescription)")
		case .began:
			stopAndFinishCurrentAnimations()
			recognizer.setTranslation(.zero, in: view)

			dynamicAnimator.removeBehavior(snapBehavior)

			addButton.center = location

		case .ended:
			recognizer.setTranslation(.zero, in: view)


			guard let indexPath = self.calendarCollectionView.indexPathForItem(at: location), let dateCell = self.calendarCollectionView.cellForItem(at: indexPath) as? CustomCell else {
				print("no date cell")
				snapAddButtonToInitialPosition(button: addButton, animator: viewPropertyAnimator, dynamicAnimator: dynamicAnimator)
				return
			}
//			performSegue(withIdentifier: "ProductDetailSegue", sender: cell)
			print("pan ended on a date cell")


			//whole lot has to be implemented here
			//have to handle checking to see if the location passes a hit test for any appropriate views in the view hierarchy

		case .cancelled, .failed:
			recognizer.setTranslation(.zero, in: view)
			viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
				self.addButton.transform = .identity
			})
			viewPropertyAnimator.startAnimation()
			dynamicAnimator.addBehavior(snapBehavior)


		case .possible:
			print("possible pan gesture state case. No implementation")
		@unknown default:
			fatalError("unknown default handling of unknown case in switch: InventoryViewController.swift")
		}
	}

}
