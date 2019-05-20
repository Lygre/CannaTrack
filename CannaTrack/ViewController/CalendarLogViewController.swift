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

	var dosePreviewInteraction: UIPreviewInteraction?

	//add button stuff
	@IBOutlet var addButton: AddProductFloatingButton!

	var viewPropertyAnimator: UIViewPropertyAnimator!

	var dynamicAnimator: UIDynamicAnimator?

	var snapBehavior: UISnapBehavior?

	var originalAddButtonPosition: CGPoint! = .zero

	var originalAddButtonSize: CGSize! = CGSize(width: 60, height: 60)

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
		self.addButton.addTarget(self, action: #selector(handleHapticsForAddButton(sender:)), for: [.backToAnchorPoint, .overEligibleContainerRegion])

		self.viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
			self.addButton.transform = .init(scaleX: 2.0, y: 2.0)
		})
		originalAddButtonPosition = CGPoint(x: view.frame.width - 25 - ((view.frame.width * 0.145) / 2.0), y: view.frame.height - 60 - ((view.frame.height * 0.067) / 2.0))
		originalAddButtonSize = addButton.bounds.size
		setupAddButtonPanGesture(button: addButton)
		dynamicAnimator = UIDynamicAnimator(referenceView: self.view)
		dynamicAnimator!.delegate = self
		snapBehavior = UISnapBehavior(item: addButton, snapTo: originalAddButtonPosition)
		snapBehavior?.damping = 0.8
		dynamicAnimator?.addBehavior(snapBehavior!)


		//preview interaction work
		dosePreviewInteraction = UIPreviewInteraction(view: addButton)
		dosePreviewInteraction?.delegate = self
		selectedDate = Date()
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
		guard let selectedDate = selectedDate else { return }
		calendarCollectionView.scrollToDate(selectedDate, triggerScrollToDateDelegate: true, animateScroll: true, preferredScrollPosition: nil, extraAddedOffset: 0) {
			self.calendarCollectionView.selectDates([selectedDate])
		}

		originalAddButtonPosition = CGPoint(x: view.frame.width - 25 - ((view.frame.width * 0.145) / 2.0), y: view.frame.height - 60 - ((view.frame.height * 0.067) / 2.0))

		viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
			self.addButton.bounds = CGRect(origin: self.originalAddButtonPosition, size: self.originalAddButtonSize)
			self.addButton.layer.shadowOpacity = 1.0
			//					self.addButton.layer.cornerRadius
		})

		viewPropertyAnimator.startAnimation()
		guard let dynamicAnimator = self.dynamicAnimator else { return }
		snapAddButtonToInitialPosition(button: addButton, animator: addButton.propertyAnimator, dynamicAnimator: dynamicAnimator)

	}

	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		self.selectedDate = calendarCollectionView.selectedDates[0]
	}

	override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//		super.viewWillTransition(to: size, with: coordinator)
		if let selectedDate = selectedDate {
			calendarCollectionView?.viewWillTransition(to: size, with: coordinator, anchorDate: selectedDate)
		} else {
			calendarCollectionView.viewWillTransition(to: size, with: coordinator, anchorDate: Date())
		}

		guard let snapBehavior = snapBehavior else { return }
		originalAddButtonPosition = CGPoint(x: size.width - 25 - ((size.width * 0.145) / 2.0), y: size.height - 60 - ((size.height * 0.067) / 2.0))
		dynamicAnimator?.removeBehavior(snapBehavior)
		self.snapBehavior = UISnapBehavior(item: addButton, snapTo: originalAddButtonPosition)
		dynamicAnimator?.addBehavior(self.snapBehavior!)
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
		handleCellSelected(cell: myCustomCell, cellState: cellState)
		handleCellTextColor(cell: myCustomCell, cellState: cellState)
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
		if cellState.selectionType != nil {
			calendar.deselectAllDates()
			return true
		}
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
			validCell.dosesPresentOnDate = true
			validCell.dosesPresentIndicatorView.isHidden = false
		} else {
			validCell.dosesPresentOnDate = false
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

	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let cell = tableView.cellForRow(at: indexPath) as? DoseCalendarTableViewCell else { return }

		print(cell.frame)

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
					self.calendarCollectionView.collectionViewLayout.invalidateLayout()
					self.calendarCollectionView.reloadData()
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
	/*
		viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
			self.addButton.transform = .identity
		})
		viewPropertyAnimator.startAnimation()
	*/
		guard let snapBehavior = snapBehavior else { return }
		dynamicAnimator.removeBehavior(snapBehavior)
		self.snapBehavior = UISnapBehavior(item: addButton, snapTo: originalAddButtonPosition)
		dynamicAnimator.addBehavior(self.snapBehavior!)
	}

	func setupAddButtonPanGesture(button: AddProductFloatingButton) {
		let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePanForAddButton(recognizer:)))
		addButton.addGestureRecognizer(pan)
		addButton.isUserInteractionEnabled = true
	}

	/*
	func animateButtonForRegion(button: AddProductFloatingButton, size: CGSize) {
		viewPropertyAnimator = UIViewPropertyAnimator(duration: 0.15, curve: .linear, animations: {
			button.bounds = CGRect(origin: button.center, size: size)
			button.layer.shadowOpacity = 0.0
		})
		viewPropertyAnimator.startAnimation()
	}
	*/
}


extension CalendarLogViewController: UIDynamicAnimatorDelegate {

	func dynamicAnimatorDidPause(_ animator: UIDynamicAnimator) {

		guard let button = animator.items(in: self.view.frame).first as? AddProductFloatingButton else {
			print("There is no button; not able to be cast as The Button, anyway")
			return
		}
		UIView.animate(withDuration: 0.1) {
			self.addButton.alpha = 1
		}
		button.sendActions(for: .backToAnchorPoint)
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
		let locationInTableView = recognizer.location(in: self.doseTableView)
		let locationInCalendarView = recognizer.location(in: self.calendarCollectionView)

		guard let dynamicAnimator = self.dynamicAnimator else { return }
		guard let snapBehavior = snapBehavior else { return }
		if dynamicAnimator.isRunning {
			return
		}

		switch recognizer.state {
		case .changed:
			addButton.center = CGPoint(x: addButton.center.x + translation.x, y: addButton.center.y + translation.y)
			recognizer.setTranslation(.zero, in: view)



			if !addButton.propertyAnimator.isRunning {
				if (locationInTableView.x > 0) && (locationInTableView.y > 0) {
					let sizeForAnimation: CGSize = CGSize(width: doseTableView.bounds.width, height: 50)

					addButton.sendActions(for: .overEligibleContainerRegion)
					addButton.animateButtonForRegion(for: sizeForAnimation)
				} else if (locationInCalendarView.y > 0) && (locationInCalendarView.y <= calendarCollectionView.bounds.size.height) {
					guard let indexPath = calendarCollectionView.indexPathForItem(at: locationInCalendarView), let cell = calendarCollectionView.cellForItem(at: indexPath) as? CustomCell else {
						print("no date custom cell")
						return
					}

					guard let cellState = calendarCollectionView.cellStatus(at: locationInCalendarView) else {
						print("no cell state for point \(locationInCalendarView)")
						return
					}
					calendarCollectionView.deselectAllDates()
					calendarCollectionView.selectDates([cellState.date], triggerSelectionDelegate: true, keepSelectionIfMultiSelectionAllowed: false)
					if cell.dosesPresentOnDate {
						addButton.sendActions(for: .overEligibleContainerRegion)
					}
					addButton.animateButtonForRegion(for: cell.bounds.size)
				} else {
					addButton.propertyAnimator.isReversed = true

					//				addButton.propertyAnimator.startAnimation()

					print("not in tableview, or collectionview")
				}
			} else { print("button animator is still running") }


		case .began:
//			stopAndFinishCurrentAnimations()
			recognizer.setTranslation(.zero, in: view)
			print("add button pan began")
			dynamicAnimator.removeBehavior(snapBehavior)

			addButton.center = location

		case .ended:
			recognizer.setTranslation(.zero, in: view)


			let xAndYForTouch: (CGFloat, CGFloat) = (locationInTableView.x, locationInTableView.y)
			let sizeForAnimation: CGSize = CGSize(width: doseTableView.bounds.width, height: 50)
			if (xAndYForTouch.0 > 0) && (xAndYForTouch.1 > 0) {
				addButton.sendActions(for: .overEligibleContainerRegion)
				print("pan ended on tableview")
				performSegue(withIdentifier: logDoseFromCalendarSegueIdentifier, sender: nil)
				//				animateButtonForTableRegion(button: addButton, size: sizeForAnimation)
			} else if (locationInCalendarView.y > 0) && (locationInCalendarView.y < calendarCollectionView.bounds.height) {
//				addButton.sendActions(for: .overEligibleContainerRegion)
				print("pan ended on calendar collection")
//				performSegue(withIdentifier: logDoseFromCalendarSegueIdentifier, sender: nil)
				guard let cellState = calendarCollectionView.cellStatus(at: locationInCalendarView) else { return }
				calendarCollectionView.selectDates([cellState.date], triggerSelectionDelegate: true, keepSelectionIfMultiSelectionAllowed: false)

				snapAddButtonToInitialPosition(button: addButton, animator: addButton.propertyAnimator, dynamicAnimator: dynamicAnimator)
			} else {
				print("no dose tableview; add button pan ended")
				snapAddButtonToInitialPosition(button: addButton, animator: addButton.propertyAnimator, dynamicAnimator: dynamicAnimator)
			}

			//			performSegue(withIdentifier: "ProductDetailSegue", sender: cell)
			//whole lot has to be implemented here
			//have to handle checking to see if the location passes a hit test for any appropriate views in the view hierarchy

		case .cancelled, .failed:
			recognizer.setTranslation(.zero, in: view)
			guard let dynamicAnimator = self.dynamicAnimator else { return }
			snapAddButtonToInitialPosition(button: addButton, animator: addButton.propertyAnimator, dynamicAnimator: dynamicAnimator)

			print("pan gesture cancelled or failed")

		case .possible:
			print("possible pan gesture state case. No implementation")
		@unknown default:
			fatalError("unknown default handling of unknown case in switch: InventoryViewController.swift")
		}
	}


	@objc func handleHapticsForAddButton(sender: AddProductFloatingButton) {

		let targets = sender.allControlEvents
		switch targets {
		case .backToAnchorPoint:
			print("back to anchor point haptic action triggered")
			sender.generator.impactOccurred()
		case .overEligibleContainerRegion:
			print("over eligible container region haptic action")
			sender.generator.impactOccurred()
		default:
			sender.generator.impactOccurred()
			print("do nothing")
		}


	}


}


extension CalendarLogViewController: UIPreviewInteractionDelegate {
	func previewInteraction(_ previewInteraction: UIPreviewInteraction, didUpdatePreviewTransition transitionProgress: CGFloat, ended: Bool) {
		//code to update preview

		if ended {
			//complete preview

		}
	}

	func previewInteractionDidCancel(_ previewInteraction: UIPreviewInteraction) {

		//uiviewanimate
	}



}
