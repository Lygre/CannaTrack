//
//  ProductTableViewCell.swift
//  CannaTrack
//
//  Created by Hugh Broome on 4/7/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class ProductTableViewCell: UITableViewCell {

	let productTypeLabel: UILabel = makePrimaryLabel()
	let productStrainLabel: UILabel = makePrimaryLabel()
	let productDoseCountLabel: UILabel = makePrimaryLabel()
	let massForProductInDoseLabel: UILabel = makePrimaryLabel()


	private static func makePrimaryLabel() -> UILabel {
		let label = UILabel()

		label.translatesAutoresizingMaskIntoConstraints = false
		label.numberOfLines = 0
		return label
	}
	
	override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
		super.init(style: style, reuseIdentifier: reuseIdentifier)
		setUpLabelsAndConstraints()
	}

	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		setUpLabelsAndConstraints()
	}

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

	private func setupColor() {

	}

	private func setUpLabelsAndConstraints() {
		//dynamic font size

		//custom defined font

		guard let palatino = UIFont(name: "Palatino", size: 18) else {
			fatalError("""
                Failed to load the "Palatino" font.
                Since this font is included with all versions of iOS that support Dynamic Type, verify that the spelling and casing is correct.
                """)
		}


		productTypeLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		productTypeLabel.adjustsFontForContentSizeCategory = true



		productStrainLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: palatino)
		productStrainLabel.adjustsFontForContentSizeCategory = true


		productDoseCountLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: palatino)
		productDoseCountLabel.adjustsFontForContentSizeCategory = true

		contentView.addSubview(productTypeLabel)
		contentView.addSubview(productDoseCountLabel)
		contentView.addSubview(productStrainLabel)
		contentView.addSubview(massForProductInDoseLabel)

		productTypeLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
		productTypeLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
		productDoseCountLabel.leadingAnchor.constraint(equalTo: productTypeLabel.leadingAnchor).isActive = true
		productDoseCountLabel.trailingAnchor.constraint(equalTo: productTypeLabel.trailingAnchor).isActive = true
		productStrainLabel.leadingAnchor.constraint(equalTo: productTypeLabel.leadingAnchor).isActive = true
		productStrainLabel.trailingAnchor.constraint(equalTo: productTypeLabel.trailingAnchor).isActive = true
		massForProductInDoseLabel.leadingAnchor.constraint(equalTo: productTypeLabel.leadingAnchor).isActive = true
		massForProductInDoseLabel.trailingAnchor.constraint(equalTo: productTypeLabel.trailingAnchor).isActive = true


		productTypeLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: contentView.layoutMarginsGuide.topAnchor, multiplier: 1).isActive = true
		productStrainLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: productTypeLabel.lastBaselineAnchor, multiplier: 1).isActive = true
		productDoseCountLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: productStrainLabel.lastBaselineAnchor, multiplier: 1).isActive = true

		massForProductInDoseLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: productDoseCountLabel.lastBaselineAnchor, multiplier: 1).isActive = true
		contentView.layoutMarginsGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: massForProductInDoseLabel.lastBaselineAnchor, multiplier: 1).isActive = true


	}

}
