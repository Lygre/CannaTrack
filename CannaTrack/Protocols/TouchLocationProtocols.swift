//
//  TouchLocationProtocols.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/13/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

protocol TouchLocatable {
	func touchLocation(in view: UIView) -> CGPoint
}


extension UIGestureRecognizer: TouchLocatable {
	func touchLocation(in view: UIView) -> CGPoint {
		return self.location(in: view)
	}
}


extension UIPreviewInteraction: TouchLocatable {
	func touchLocation(in view: UIView) -> CGPoint {
		return self.touchLocation(in: view)
	}



}

extension ProductDetailViewController {

	func updateButtonSelectionState(for event: TouchLocatable) {
		var actionSelected = false
		let firstIteration = (firstLocation == nil)

		if firstIteration {
			//configureMovementRequirementIfMovedFarEnoughFromFirstLocation(for: event)
		} else {
			if requiresMovement {
				//removeMovementRequirementIfMovedFarEnoughFromFirstLocation(for event)
			}
			actionSelected = setSelectedActionByTouchLocation(for: event)
		}

		if actionSelected == false {
			selectedAction = nil
		}
	}

	func setSelectedActionByTouchLocation(for event: TouchLocatable) -> Bool {
		var actionSelected = false
		/*
		for cell in tableView.visibleCells {
			let indexPath = tableView.indexPath(for: cell)!
			let location = event.touchLocation(in: cell)

			let inside = (location.y > 0 && location.y < cell.frame.size.height)

			if requiresMovement == false {
				cell.setHighlighted(inside, animated: false)

				if inside {
					playSelectionChangedHaptic(for: indexPath)
					selectedAction = actions[indexPath.row]

					actionSelected = true
				}
			}
		}
		*/
		return actionSelected

	}

	func configureMovementRequiredStateForInitialTouchLocation(for event: TouchLocatable) {
		/*
		for cell in tableView.visibleCells {
			let indexPath = tableView.indexPath(for: cell)!
			let location = event.touchLocation(in: cell)

			let inside = (location.y > 0 && location.y < cell.frame.size.height)

			if firstLocation == nil {
				firstLocation = location
				firstIndex = indexPath.row

				if inside {
					requiresMovement = true
					return
				}
			}

			if inside == false && requiresMovement == false {
				firstLocation = nil
				firstIndex = nil
			}
		}
		*/
	}


	func removeMovementRequirementIfMovedFarEnoughFromFirstLocation(for event: TouchLocatable) {
		/*
		for cell in tableView.visibleCells {
			let indexPath = tableView.indexPath(for: cell)!
			let location = event.touchLocation(in: cell)

			if firstIndex! == indexPath.row && requiresMovement {
				let distanceX = abs(firstLocation!.x - location.x)
				let distanceY = abs(firstLocation!.y - location.y)

				if distanceX >= 35 || distanceY >= 35 {
					requiresMovement = false
				}
			}
		}
		*/
	}

}
