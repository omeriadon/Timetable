//
//  TranscriptView.swift
//  Timetable Message Extension
//
//  Created by Adon Omeri on 30/4/2026.
//

import UIKit

class TranscriptView: UIView {
	private let label = UILabel()

	override init(frame: CGRect) {
		super.init(frame: frame)
		setupUI()
	}

	required init?(coder: NSCoder) {
		super.init(coder: coder)
		setupUI()
	}

	private func setupUI() {
		backgroundColor = UIColor.clear

		label.text = "Timetable"
		label.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
		label.textColor = UIColor.label
		label.textAlignment = .center
		label.numberOfLines = 0

		addSubview(label)
		label.translatesAutoresizingMaskIntoConstraints = false

		NSLayoutConstraint.activate([
			label.centerXAnchor.constraint(equalTo: centerXAnchor),
			label.centerYAnchor.constraint(equalTo: centerYAnchor),
			label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 16),
			label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -16),
		])
	}
}
