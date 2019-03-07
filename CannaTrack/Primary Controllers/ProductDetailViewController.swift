//
//  ProductDetailViewController.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class ProductDetailViewController: UIViewController {

	var activeDetailProduct: Product!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)

		view.backgroundColor = {
			switch self.activeDetailProduct.strain.race {
			case .hybrid:
				return .green
			case .indica:
				return .purple
			case .sativa:
				return .yellow
			}
		}()

	}


}
