//
//  ExampleViewController.swift
//  DKPullUpExample
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import DKPullUpController
import UIKit

final class ExampleViewController: UIViewController {
    private let sheet = ExampleSheet()
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

private final class ExampleSheet: DKPullUpController, UITableViewDataSource {
    private let list = UITableView(frame: .zero, style: .plain)
    private let items = ["Overview", "Favorites", "Recent", "Collections", "Saved", "Shared", "Archive", "Settings"]

    override var preferredPullUpSize: CGSize {
        let bounds = parent?.view.bounds ?? .zero
        let safeTop = parent?.view.safeAreaInsets.top ?? 0
        return CGSize(width: bounds.width, height: min(600, max(0, bounds.height - safeTop - 24)))
    }

    override var middleSnapPoints: [CGFloat] { [320] }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 16
        view.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.clipsToBounds = true

        let handle = UIView()
        handle.backgroundColor = .tertiaryLabel
        handle.layer.cornerRadius = 2.5
        handle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(handle)

        let heading = UILabel()
        heading.text = "Library"
        heading.font = .preferredFont(forTextStyle: .title2)
        heading.adjustsFontForContentSizeCategory = true
        heading.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(heading)

        list.dataSource = self
        list.backgroundColor = .clear
        list.alwaysBounceVertical = true
        list.register(UITableViewCell.self, forCellReuseIdentifier: "Item")
        list.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(list)
        NSLayoutConstraint.activate([
            handle.topAnchor.constraint(equalTo: view.topAnchor, constant: 10),
            handle.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            handle.widthAnchor.constraint(equalToConstant: 40),
            handle.heightAnchor.constraint(equalToConstant: 5),
            heading.topAnchor.constraint(equalTo: handle.bottomAnchor, constant: 18),
            heading.leadingAnchor.constraint(equalTo: view.layoutMarginsGuide.leadingAnchor),
            heading.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),
            list.topAnchor.constraint(equalTo: heading.bottomAnchor, constant: 12),
            list.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            list.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            list.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        attach(scrollView: list)
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { items.count }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Item", for: indexPath)
        var content = cell.defaultContentConfiguration()
        content.text = items[indexPath.row]
        cell.contentConfiguration = content
        cell.backgroundColor = .clear
        return cell
    }
}
