//
//  StrainSearchResultsCollectionView.swift
//  CannaTrack
//
//  Created by Hugh Broome on 6/15/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import Foundation
import UIKit

class ResultsCollectionViewController: UICollectionViewController {

	var filteredStrains = [Strain]()

	override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return filteredStrains.count
	}


	override func numberOfSections(in collectionView: UICollectionView) -> Int {
		return 1
	}


}
