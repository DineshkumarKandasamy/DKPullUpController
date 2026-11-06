//
//  ExampleViewController.swift
//  DKPullUpExample
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import DKPullUpController
import UIKit

final class ExampleViewController: UIViewController {
    private let sheet = ExampleSheetViewController()
    private let positions = UISegmentedControl(items: ["Small", "Medium", "Large"])
    private let layout = UISegmentedControl(items: ["Bottom", "Auto", "Side"])
    private var visibilityButton: UIBarButtonItem?
    private var isTransitioning = false
    private var didPresentSheet = false

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Pull-up Sheet"
        view.backgroundColor = .systemGroupedBackground
        let visibility = UIBarButtonItem(title: "Hide", style: .plain, target: self, action: #selector(toggleSheet))
        visibilityButton = visibility
        navigationItem.rightBarButtonItem = visibility

        let titleLabel = UILabel()
        titleLabel.text = "Sheet controls"
        titleLabel.font = .preferredFont(forTextStyle: .title2)
        titleLabel.adjustsFontForContentSizeCategory = true
        positions.selectedSegmentIndex = 0
        positions.accessibilityLabel = "Sheet position"
        positions.addTarget(self, action: #selector(changePosition), for: .valueChanged)
        layout.selectedSegmentIndex = 0
        layout.accessibilityLabel = "Sheet layout"
        layout.addTarget(self, action: #selector(changeLayout), for: .valueChanged)

        let stack = UIStackView(arrangedSubviews: [titleLabel, positions, layout])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24),
            stack.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor)
        ])
        sheet.configuration.layoutMode = .bottom
        sheet.configuration.defaultDragHandleColor = .systemTeal
        sheet.configuration.defaultDragHandleWidth = 48
        sheet.configuration.defaultDragHandleHeight = 6
        sheet.configuration.defaultDragHandleCornerRadius = 3
        sheet.configuration.defaultDragHandleTopInset = 10
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didPresentSheet else { return }
        didPresentSheet = true
        showSheet()
    }

    private func showSheet() {
        guard !isTransitioning else { return }
        isTransitioning = true
        sheet.add(to: self, initialVisibleHeight: 160) { [weak self] _ in
            self?.isTransitioning = false
            self?.visibilityButton?.title = "Hide"
        }
    }

    @objc private func toggleSheet() {
        guard !isTransitioning else { return }
        guard sheet.parent != nil else {
            showSheet()
            return
        }
        isTransitioning = true
        sheet.remove { [weak self] _ in
            self?.isTransitioning = false
            self?.visibilityButton?.title = "Show"
        }
    }

    @objc private func changePosition() {
        let points = sheet.snapPoints
        guard !points.isEmpty else { return }
        let index = min(positions.selectedSegmentIndex, points.count - 1)
        sheet.move(to: points[index])
    }

    @objc private func changeLayout() {
        switch layout.selectedSegmentIndex {
        case 1: sheet.configuration.layoutMode = .automatic
        case 2: sheet.configuration.layoutMode = .side
        default: sheet.configuration.layoutMode = .bottom
        }
    }
}
