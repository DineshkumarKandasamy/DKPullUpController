import XCTest
@testable import DKPullUpController

@MainActor
final class AccessibilityTests: XCTestCase {
    func testDefaultHandleSupportsAdjustableVoiceOverActions() throws {
        let (window, parent) = makeVisibleParent()
        let sheet = DKPullUpController()
        sheet.pullUpPreferredSize = CGSize(width: 320, height: 400)
        sheet.pullUpIntermediateSnapPoints = [250]
        sheet.configuration.layoutMode = .bottom
        sheet.configuration.movementDuration = 0
        sheet.add(to: parent, initialVisibleHeight: 100, animated: false)

        let handle = try XCTUnwrap(sheet.view.subviews.first {
            $0.isAccessibilityElement && $0.accessibilityTraits.contains(.adjustable)
        })
        XCTAssertEqual(handle.accessibilityLabel, "Sheet height")
        XCTAssertEqual(handle.accessibilityValue, "100 points")

        handle.accessibilityIncrement()
        XCTAssertEqual(sheet.visibleHeight, 250)
        XCTAssertEqual(handle.accessibilityValue, "250 points")

        handle.accessibilityIncrement()
        XCTAssertEqual(sheet.visibleHeight, 400)
        handle.accessibilityIncrement()
        XCTAssertEqual(sheet.visibleHeight, 400)

        handle.accessibilityDecrement()
        XCTAssertEqual(sheet.visibleHeight, 250)
        handle.accessibilityDecrement()
        XCTAssertEqual(sheet.visibleHeight, 100)
        handle.accessibilityDecrement()
        XCTAssertEqual(sheet.visibleHeight, 100)

        sheet.remove(animated: false)
        XCTAssertEqual(window.rootViewController, parent)
    }

    func testDefaultHandleIsNotAdjustableInSideLayout() throws {
        let (window, parent) = makeVisibleParent(size: CGSize(width: 844, height: 390))
        let sheet = DKPullUpController()
        sheet.configuration.layoutMode = .side
        sheet.add(to: parent, initialVisibleHeight: 100, animated: false)

        let handle = try XCTUnwrap(sheet.view.subviews.first { $0.accessibilityLabel == "Sheet height" })
        XCTAssertFalse(handle.isAccessibilityElement)

        sheet.remove(animated: false)
        XCTAssertEqual(window.rootViewController, parent)
    }

    func testReducedMotionDisablesConfiguredAnimationDurations() {
        let sheet = DKPullUpController()

        XCTAssertEqual(sheet.validDuration(0.3, reduceMotion: true), 0)
        XCTAssertEqual(sheet.validDuration(0.3, reduceMotion: false), 0.3)
    }

    func testReducedMotionSuppressesLiveBackgroundCardMotion() throws {
        let (window, parent) = makeVisibleParent()
        let sheet = makeSheet(contentMode: .live)
        sheet.add(to: parent, initialVisibleHeight: 100, animated: false)

        let card = try XCTUnwrap(sheet.backgroundCardContentView)
        sheet.updateBackgroundCardProgress(to: 100, reduceMotion: true)

        XCTAssertEqual(card.transform, .identity)
        XCTAssertEqual(card.layer.cornerRadius, 0)
        XCTAssertFalse(card.clipsToBounds)

        sheet.remove(animated: false)
        XCTAssertEqual(window.rootViewController, parent)
    }

    func testReducedMotionKeepsSnapshotVisibleWithoutCardMotion() throws {
        let (window, parent) = makeVisibleParent()
        let sheet = makeSheet(contentMode: .snapshot)
        sheet.add(to: parent, initialVisibleHeight: 100, animated: false)

        let snapshot = try XCTUnwrap(sheet.backgroundCardSnapshotView)
        sheet.updateBackgroundCardProgress(to: 100, reduceMotion: true)

        XCTAssertFalse(snapshot.isHidden)
        XCTAssertEqual(snapshot.transform, .identity)
        XCTAssertEqual(snapshot.layer.cornerRadius, 0)

        sheet.remove(animated: false)
        XCTAssertEqual(window.rootViewController, parent)
    }

    private func makeVisibleParent(size: CGSize = CGSize(width: 390, height: 844)) -> (UIWindow, UIViewController) {
        let window = UIWindow(frame: CGRect(origin: .zero, size: size))
        let parent = UIViewController()
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
        sheet.configuration.backgroundCardVerticalOffset = 24
        sheet.configuration.backgroundCardCornerRadius = 24
        sheet.configuration.presentationDuration = 0
        sheet.configuration.dismissalDuration = 0
        return sheet
    }
}
