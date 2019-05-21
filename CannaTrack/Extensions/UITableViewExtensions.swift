//
//  UITableViewExtensions.swift
//  SwiftOneDAy
//
//  Created by Taro Minowa on 6/21/14.
//  Copyright (c) 2014 Higepon Taro Minowa. All rights reserved.
//

import UIKit

extension UITableView {
    func scrollToBottom(animated: Bool = true) {
		let bottomOffset = CGPoint(x: 0, y: contentSize.height - bounds.size.height)
        setContentOffset(bottomOffset, animated: animated)
    }
}
