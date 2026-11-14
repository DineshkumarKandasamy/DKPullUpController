import XCTest
@testable import DKPullUpController

@MainActor
final class ControllerInteractionTests: XCTestCase {
    func testDetachRestoresOriginalScrollBounceSetting() {
        let (_, parent) = makeVisibleParent()
        let sheet = makeSheet(parent: parent)
        let scrollView = UIScrollView()
        sheet.attach(scrollView: scrollView)
        simulateScrollDrag(sheet: sheet)

        XCTAssertFalse(scrollView.bounces)
        XCTAssertEqual(sheet.savedScrollBounce, true)

        sheet.detachScrollView()

        XCTAssertTrue(scrollView.bounces)
        XCTAssertNil(sheet.savedScrollBounce)
        XCTAssertNil(sheet.scrollView)
        sheet.remove(animated: false)
    }

    func testDisablingScrollDraggingRestoresBounceDuringActiveScrollDrag() {
        let (_, parent) = makeVisibleParent()
        let sheet = makeSheet(parent: parent)
        let scrollView = UIScrollView()
        sheet.attach(scrollView: scrollView)
        simulateScrollDrag(sheet: sheet)

        XCTAssertFalse(scrollView.bounces)
        XCTAssertTrue(sheet.scrollMovedSheet)

        sheet.configuration.isScrollDraggingEnabled = false

        XCTAssertTrue(scrollView.bounces)
        XCTAssertNil(sheet.savedScrollBounce)
        XCTAssertFalse(sheet.scrollMovedSheet)
        sheet.remove(animated: false)
    }

    func testConfigurationChangesUpdateGestureAvailabilityAfterAttachment() throws {
        let (_, parent) = makeVisibleParent()
        let sheet = makeSheet(parent: parent)
        let pan = try XCTUnwrap(sheet.pullUpPanGestureRecognizer)

        sheet.configuration.isDraggingEnabled = false
        XCTAssertFalse(pan.isEnabled)

        sheet.configuration.isDraggingEnabled = true
        XCTAssertTrue(pan.isEnabled)

        sheet.configuration.layoutMode = .side
        XCTAssertFalse(pan.isEnabled)

        sheet.configuration.layoutMode = .bottom
        XCTAssertTrue(pan.isEnabled)
        sheet.remove(animated: false)
    }

    func testRemovalRestoresScrollBounceSetting() {
        let (_, parent) = makeVisibleParent()
        let sheet = makeSheet(parent: parent)
        let scrollView = UIScrollView()
        sheet.attach(scrollView: scrollView)
        simulateScrollDrag(sheet: sheet)

        XCTAssertFalse(scrollView.bounces)
        XCTAssertEqual(sheet.savedScrollBounce, true)

        sheet.remove(animated: false)

        XCTAssertTrue(scrollView.bounces)
        XCTAssertNil(sheet.savedScrollBounce)
    }

    func testDisablingSnappingKeepsBoundedReleaseHeight() {
        let (_, parent) = makeVisibleParent()
        let sheet = makeSheet(parent: parent)
        sheet.configuration.isSnappingEnabled = false

        sheet.move(to: 230, animated: false)
        sheet.settle(velocity: 0)

        XCTAssertEqual(sheet.visibleHeight, 230)
        sheet.remove(animated: false)
    }

    func testEnabledSnappingSettlesAtNearestSnapPoint() {
        let (_, parent) = makeVisibleParent()
        let sheet = makeSheet(parent: parent)

        sheet.move(to: 230, animated: false)
        sheet.settle(velocity: 0)

        XCTAssertEqual(sheet.visibleHeight, 250)
        sheet.remove(animated: false)
    }

    private func makeVisibleParent() -> (UIWindow, UIViewController) {
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        let parent = UIViewController()
        window.rootViewController = parent
        window.makeKeyAndVisible()
        parent.view.layoutIfNeeded()
        return (window, parent)
    }

    private func makeSheet(parent: UIViewController) -> DKPullUpController {
        let sheet = DKPullUpController()
        sheet.pullUpPreferredSize = CGSize(width: 340, height: 400)
        sheet.pullUpIntermediateSnapPoints = [250]
        sheet.configuration.layoutMode = .bottom
        sheet.configuration.presentationDuration = 0
        sheet.configuration.dismissalDuration = 0
        sheet.configuration.movementDuration = 0
        sheet.configuration.minimumSnapDuration = 0
        sheet.configuration.maximumSnapDuration = 0
        sheet.add(to: parent, initialVisibleHeight: 100, animated: false)
        return sheet
    }

    private func simulateScrollDrag(sheet: DKPullUpController) {
        let recognizer = SimulatedPanGestureRecognizer()
        recognizer.simulatedState = .began
        sheet.handleScrollPan(recognizer)

        recognizer.simulatedState = .changed
        recognizer.simulatedTranslation = CGPoint(x: 0, y: 20)
        sheet.handleScrollPan(recognizer)
    }
}

private final class SimulatedPanGestureRecognizer: UIPanGestureRecognizer {
    var simulatedState: UIGestureRecognizer.State = .possible
    var simulatedTranslation = CGPoint.zero

    override var state: UIGestureRecognizer.State {
        get { simulatedState }
        set { simulatedState = newValue }
    }

    override func translation(in view: UIView?) -> CGPoint { simulatedTranslation }

    override func setTranslation(_ translation: CGPoint, in view: UIView?) {
        simulatedTranslation = translation
    }
}
