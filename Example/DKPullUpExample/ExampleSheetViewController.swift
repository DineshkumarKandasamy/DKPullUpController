//
//  ExampleSheetViewController.swift
//  DKPullUpExample
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import DKPullUpController
import UIKit

final class ExampleSheetViewController: DKPullUpController, UITableViewDataSource {
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
            heading.topAnchor.constraint(equalTo: view.topAnchor, constant: 34),
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
