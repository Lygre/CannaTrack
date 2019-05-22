//
//  DoseCalendarTableViewCell.swift
//  CannaTrack
//
//  Created by Hugh Broome on 3/29/19.
//  Copyright © 2019 Lygre. All rights reserved.
//

import UIKit

class DoseCalendarTableViewCell: UITableViewCell {


	let timeLabel = makePrimaryLabel()
	let productLabel = makePrimaryLabel()
	let strainLabel = makePrimaryLabel()
	let massLabel = makePrimaryLabel()


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

//	layout

	private func setUpLabelsAndConstraints() {
		//dynamic font size

		//custom defined font

		guard let palatino = UIFont(name: "Palatino", size: 18) else {
			fatalError("""
                Failed to load the "Palatino" font.
                Since this font is included with all versions of iOS that support Dynamic Type, verify that the spelling and casing is correct.
                """)
		}


		timeLabel.font = UIFont.preferredFont(forTextStyle: .headline)
		timeLabel.adjustsFontForContentSizeCategory = true



		productLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: palatino)
		productLabel.adjustsFontForContentSizeCategory = true


		strainLabel.font = UIFontMetrics(forTextStyle: .body).scaledFont(for: palatino)
		strainLabel.adjustsFontForContentSizeCategory = true

		contentView.addSubview(timeLabel)
		contentView.addSubview(strainLabel)
		contentView.addSubview(productLabel)
		contentView.addSubview(massLabel)

		timeLabel.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor).isActive = true
		timeLabel.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor).isActive = true
		strainLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor).isActive = true
		strainLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor).isActive = true
		productLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor).isActive = true
		productLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor).isActive = true
		massLabel.leadingAnchor.constraint(equalTo: timeLabel.leadingAnchor).isActive = true
		massLabel.trailingAnchor.constraint(equalTo: timeLabel.trailingAnchor).isActive = true


		timeLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: contentView.layoutMarginsGuide.topAnchor, multiplier: 1).isActive = true
		strainLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: timeLabel.lastBaselineAnchor, multiplier: 1).isActive = true
		productLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: strainLabel.lastBaselineAnchor, multiplier: 1).isActive = true
		massLabel.firstBaselineAnchor.constraint(equalToSystemSpacingBelow: productLabel.lastBaselineAnchor, multiplier: 1).isActive = true
		contentView.layoutMarginsGuide.bottomAnchor.constraint(equalToSystemSpacingBelow: massLabel.lastBaselineAnchor, multiplier: 1).isActive = true






	}


}
