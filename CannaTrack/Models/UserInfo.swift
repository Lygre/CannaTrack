//
//  UserInfo.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/22/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation

import UIKit

var savedUserInfo: [Product] = {
	guard let existingUserInfo = UserDefaults.standard.object(forKey: "ProductInventory") as? [Product] else {
		let newInfo: [Product] = []
		UserDefaults.standard.set(newInfo, forKey: "ProductInventory")
		print("unable to cast existing info into Product Array or does not exist")
		return newInfo
	}
	print("returning saved user info")
	return existingUserInfo
}()

let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
let archiveURL = documentsDirectory.appendingPathComponent("product_inventory").appendingPathExtension("plist")
