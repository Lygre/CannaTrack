//
//  StrainCollectionDelegate.swift
//  CannaTrack
//
//  Created by Hugh Broome on 5/22/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

protocol StrainCollectionDelegate: class {

	var collectionView: UICollectionView! { get }

	var selectedIndexPaths: [IndexPath]? { get set }

	func updateItems()

}
