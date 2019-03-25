//
//  DoseCalendarViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/25/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit
import CVCalendar

class DoseCalendarViewController: UIViewController {


	@IBOutlet var menuView: CVCalendarMenuView!
	@IBOutlet var calendarView: CVCalendarView!


    override func viewDidLoad() {
        super.viewDidLoad()

//		self.calendarView.calendarAppearanceDelegate = self
//		self.calendarView.animatorDelegate = self
		self.menuView.menuViewDelegate = self
		self.calendarView.calendarDelegate = self
        // Do any additional setup after loading the view.
    }
    

	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()

		menuView.commitMenuViewUpdate()
		calendarView.commitCalendarViewUpdate()
	}


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}


extension DoseCalendarViewController: CVCalendarViewDelegate, CVCalendarMenuViewDelegate {
	func presentationMode() -> CalendarMode {
		var mode: CalendarMode = .monthView
		return mode
	}

	func firstWeekday() -> Weekday {
		return .sunday
	}


}
