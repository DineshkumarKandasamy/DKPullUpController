import XCTest
@testable import DKPullUpController

@MainActor
final class BackgroundCardEffectTests: XCTestCase {
    func testLiveCardPreservesNestedAutoLayoutContentAcrossResizeAndRemoval() throws {
        let (window, parent) = makeVisibleParent()
        let container = UIView()
        container.translatesAutoresizingMaskIntoConstraints = false
        let content = UIView()
        content.translatesAutoresizingMaskIntoConstraints = false
        parent.view.addSubview(container)
        container.addSubview(content)

        let originalConstraints = [
            container.leadingAnchor.constraint(equalTo: parent.view.safeAreaLayoutGuide.leadingAnchor, constant: 12),
            container.trailingAnchor.constraint(equalTo: parent.view.safeAreaLayoutGuide.trailingAnchor, constant: -12),
            container.topAnchor.constraint(equalTo: parent.view.safeAreaLayoutGuide.topAnchor, constant: 20),
            container.bottomAnchor.constraint(equalTo: parent.view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            content.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            content.topAnchor.constraint(equalTo: container.topAnchor),
            content.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ]
        NSLayoutConstraint.activate(originalConstraints)
        parent.view.layoutIfNeeded()

        let sheet = makeSheet(contentMode: .live)
        var added = false
        sheet.add(to: parent, initialVisibleHeight: 100, animated: false) { added = $0 }

        XCTAssertTrue(added)
        let card = try XCTUnwrap(sheet.backgroundCardContentView)
        XCTAssertTrue(container.isDescendant(of: card))
        XCTAssertTrue(content.isDescendant(of: card))
        XCTAssertTrue(originalConstraints.prefix(4).allSatisfy { !$0.isActive })
        XCTAssertTrue(originalConstraints.suffix(4).allSatisfy(\.isActive))
        XCTAssertTrue((sheet.backgroundCardContentConstraints ?? []).allSatisfy(\.isActive))

        window.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        window.setNeedsLayout()
        window.layoutIfNeeded()
        parent.view.layoutIfNeeded()
        sheet.host?.layoutIfNeeded()

        XCTAssertEqual(card.bounds.size, parent.view.bounds.size)
        XCTAssertGreaterThan(container.bounds.width, 0)

        let originalTransform = card.transform
        sheet.remove(animated: false)

        XCTAssertNil(sheet.host)
        XCTAssertTrue(container.isDescendant(of: parent.view))
        XCTAssertTrue(content.isDescendant(of: container))
        XCTAssertTrue(originalConstraints.allSatisfy(\.isActive))
        XCTAssertEqual(card.transform, .identity)
        XCTAssertEqual(parent.view.backgroundColor, .black)
        XCTAssertEqual(window.rootViewController, parent)
        XCTAssertNotEqual(originalTransform, .identity)
    }

    func testSnapshotCardTracksHostResizeAndIsRemovedWithSheet() throws {
        let (window, parent) = makeVisibleParent()
        let background = UIView()
        background.translatesAutoresizingMaskIntoConstraints = false
        parent.view.addSubview(background)
        NSLayoutConstraint.activate([
            background.leadingAnchor.constraint(equalTo: parent.view.leadingAnchor),
            background.trailingAnchor.constraint(equalTo: parent.view.trailingAnchor),
            background.topAnchor.constraint(equalTo: parent.view.topAnchor),
            background.bottomAnchor.constraint(equalTo: parent.view.bottomAnchor)
        ])
        parent.view.layoutIfNeeded()

        let sheet = makeSheet(contentMode: .snapshot)
        var added = false
        sheet.add(to: parent, initialVisibleHeight: 100, animated: false) { added = $0 }

        XCTAssertTrue(added)
        let host = try XCTUnwrap(sheet.host)
        let snapshot = try XCTUnwrap(sheet.backgroundCardSnapshotView)
        XCTAssertTrue(snapshot.isDescendant(of: host))
        XCTAssertFalse(snapshot.isUserInteractionEnabled)
        XCTAssertFalse(host.passesTouchesThrough)

        window.frame = CGRect(x: 0, y: 0, width: 844, height: 390)
        window.setNeedsLayout()
        window.layoutIfNeeded()
        parent.view.layoutIfNeeded()
        host.layoutIfNeeded()

        XCTAssertEqual(snapshot.bounds, host.bounds)

        sheet.remove(animated: false)

        XCTAssertNil(sheet.host)
        XCTAssertNil(sheet.backgroundCardSnapshotView)
        XCTAssertTrue(background.isDescendant(of: parent.view))
        XCTAssertTrue(host.passesTouchesThrough)
    }

    private func makeVisibleParent() -> (UIWindow, UIViewController) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let parent = UIViewController()
        parent.view.backgroundColor = .black
        window.rootViewController = parent
        window.makeKeyAndVisible()
        parent.view.layoutIfNeeded()
        return (window, parent)
    }

    private func makeSheet(contentMode: DKPullUpBackgroundCardContentMode) -> DKPullUpController {
        let sheet = DKPullUpController()
        sheet.configuration.layoutMode = .bottom
        sheet.configuration.isBackgroundCardEffectEnabled = true
        sheet.configuration.backgroundCardContentMode = contentMode
        sheet.configuration.backgroundCardScale = 0.8
        sheet.configuration.presentationDuration = 0
        sheet.configuration.dismissalDuration = 0
        return sheet
    }
}
