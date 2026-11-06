//
//  SheetPhysics.swift
//  DKPullUpController
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import Foundation

/// Calculates bounded snap positions and release behavior for a pull-up sheet.
struct SheetPhysics {
    /// Valid snap positions in ascending order, with duplicates removed.
    let positions: [CGFloat]

    /// Creates snap positions from the initial, maximum, and intermediate heights.
    /// - Parameters:
    ///   - initial: The sheet's initial visible height.
    ///   - maximum: The upper bound for all snap positions.
    ///   - intermediate: Additional requested snap heights.
    init(initial: CGFloat, maximum: CGFloat, intermediate: [CGFloat]) {
        let ceiling = maximum.isFinite ? max(0, maximum) : 0
        let candidates = [initial, ceiling] + intermediate
        let bounded = candidates.filter(\.isFinite).map { min(ceiling, max(0, $0)) }
        positions = Array(Set(bounded)).sorted()
    }

    /// Limits a height to the snap range with an optional overshoot allowance.
    /// - Parameters:
    ///   - value: The requested height.
    ///   - overshoot: Additional distance allowed beyond either end of the range.
    /// - Returns: The bounded height.
    func clamp(_ value: CGFloat, overshoot: CGFloat = 0) -> CGFloat {
        let lower = positions.first ?? 0
        let upper = positions.last ?? 0
        let allowance = overshoot.isFinite ? max(0, overshoot) : 0
        let position = value.isFinite ? value : lower
        return min(upper + allowance, max(lower - allowance, position))
    }

    /// Finds the snap position closest to a requested height.
    /// - Parameter value: The height to compare against the available positions.
    /// - Returns: The nearest snap position, or zero when no positions exist.
    func nearest(to value: CGFloat) -> CGFloat {
        let position = clamp(value)
        return positions.min { abs($0 - position) < abs($1 - position) } ?? 0
    }

    /// Projects a release position using velocity and returns its nearest snap point.
    /// - Parameters:
    ///   - position: The sheet's current visible height.
    ///   - velocity: Vertical release velocity in points per second; positive is downward.
    ///   - threshold: Minimum absolute velocity required to project the position.
    /// - Returns: The selected snap position.
    func destination(from position: CGFloat, velocity: CGFloat, threshold: CGFloat) -> CGFloat {
        let start = clamp(position)
        let minimumSpeed = threshold.isFinite ? max(0, threshold) : 0
        guard velocity.isFinite, abs(velocity) > minimumSpeed else { return nearest(to: start) }
        let displacement = min(max(velocity * 0.18, -1200), 1200)
        return nearest(to: start - displacement)
    }

    /// Calculates a bounded release-animation duration from distance and velocity.
    /// - Parameters:
    ///   - distance: Distance to the target in points.
    ///   - velocity: Release velocity in points per second.
    ///   - minimum: Minimum allowed duration.
    ///   - maximum: Maximum allowed duration.
    /// - Returns: The calculated duration in seconds.
    static func duration(
        distance: CGFloat, velocity: CGFloat, minimum: TimeInterval, maximum: TimeInterval
    ) -> TimeInterval {
        let upper = maximum.isFinite ? max(0, maximum) : 0
        let lower = minimum.isFinite ? min(upper, max(0, minimum)) : 0
        guard distance.isFinite, velocity.isFinite, velocity != 0 else { return upper }
        let distanceRatio = min(abs(distance) / 800, 1)
        let speedRatio = min(abs(velocity) / 2500, 1)
        return lower + (upper - lower) * Double(distanceRatio * (1 - 0.6 * speedRatio))
    }
}
