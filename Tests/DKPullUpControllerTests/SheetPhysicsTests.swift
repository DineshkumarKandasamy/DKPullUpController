import XCTest
@testable import DKPullUpController

final class SheetPhysicsTests: XCTestCase {
    func testSnapPositionsAreBoundedSortedDeduplicatedAndFinite() {
        let physics = SheetPhysics(
            initial: 50,
            maximum: 100,
            intermediate: [80, 20, 80, -10, 120, .infinity, .nan]
        )

        XCTAssertEqual(physics.positions, [0, 20, 50, 80, 100])
    }

    func testInvalidMaximumProducesOnlyZeroPosition() {
        let physics = SheetPhysics(initial: 40, maximum: .infinity, intermediate: [20, .nan])

        XCTAssertEqual(physics.positions, [0])
    }

    func testDestinationUsesNearestPointAtOrBelowVelocityThreshold() {
        let physics = SheetPhysics(initial: 0, maximum: 200, intermediate: [100])

        XCTAssertEqual(physics.destination(from: 140, velocity: 700, threshold: 700), 100)
        XCTAssertEqual(physics.destination(from: 140, velocity: .nan, threshold: 700), 100)
    }

    func testDestinationProjectsFastReleaseInVelocityDirection() {
        let physics = SheetPhysics(initial: 0, maximum: 200, intermediate: [100])

        XCTAssertEqual(physics.destination(from: 140, velocity: 1_000, threshold: 700), 0)
        XCTAssertEqual(physics.destination(from: 60, velocity: -1_000, threshold: 700), 200)
    }
}
