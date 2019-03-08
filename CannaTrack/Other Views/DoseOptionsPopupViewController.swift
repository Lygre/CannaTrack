//
//  DoseOptionsPopupViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/8/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DoseOptionsPopupViewController: UIViewController {

	@IBOutlet var doseOptionLabel: UILabel!

	@IBOutlet var affirmButton: UIButton!

	@IBOutlet var deferButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()

	}
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

	@IBAction func affirmDoseOptionClicked(_ sender: Any) {

	}

	@IBAction func deferDoseOptionClicked(_ sender: Any) {
		dismiss(animated: true, completion: nil)
	}



}
