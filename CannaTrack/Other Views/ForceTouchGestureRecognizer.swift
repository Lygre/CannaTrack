//
//  ForceTouchGestureRecognizer.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/19/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class ForceTouchGestureRecognizer: UIGestureRecognizer {

	private let threshold: CGFloat = 0.2

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesBegan(touches, with: event)
		if let touch = touches.first {
			handleTouch(touch)
		}
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesMoved(touches, with: event)
		if let touch = touches.first {
			handleTouch(touch)
		}
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesEnded(touches, with: event)
		state = UIGestureRecognizer.State.failed
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesCancelled(touches, with: event)
		state = UIGestureRecognizer.State.failed
	}

	private func handleTouch(_ touch: UITouch) {
		guard touch.force != 0 && touch.maximumPossibleForce != 0 else { return }

		if touch.force / touch.maximumPossibleForce >= threshold {
			state = UIGestureRecognizer.State.recognized
		}
	}


}


class DynamicProductGestureRecognizer: UIGestureRecognizer {

	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesBegan(touches, with: event)
		if let touch = touches.first {
			handleTouch(touch)
		}
	}

	override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesMoved(touches, with: event)
		state = UIGestureRecognizer.State.ended
	}

	override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesEnded(touches, with: event)
		state = UIGestureRecognizer.State.ended
	}

	override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
		super.touchesCancelled(touches, with: event)
		state = UIGestureRecognizer.State.ended
	}

	private func handleTouch(_ touch: UITouch) {
		state = UIGestureRecognizer.State.began
	}

}
