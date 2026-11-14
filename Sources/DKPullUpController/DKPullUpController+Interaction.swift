//
//  DKPullUpController+Interaction.swift
//  DKPullUpController
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import UIKit

/// Coordinates layout, animation, and gesture interactions for ``DKPullUpController``.
///
/// Positions the sheet for bottom and side layouts, updates it when configuration
/// changes, and coordinates sheet gestures with an attached scroll view. These
/// internal helpers support the controller's public presentation and movement API.
extension DKPullUpController {
    /// Indicates whether the current parent bounds select side layout.
    var usesSideLayout: Bool {
        guard let host else { return false }
        switch configuration.layoutMode {
        case .automatic: return host.bounds.width > host.bounds.height
        case .bottom: return false
        case .side: return true
        }
    }

    /// Validates a duration and disables movement animations when Reduce Motion is enabled.
    func validDuration(_ value: TimeInterval) -> TimeInterval {
        validDuration(value, reduceMotion: UIAccessibility.isReduceMotionEnabled)
    }

    func validDuration(_ value: TimeInterval, reduceMotion: Bool) -> TimeInterval {
        guard !reduceMotion else { return 0 }
        return value.isFinite ? max(0, value) : 0
    }

    /// Applies configuration changes to the drag handle, gestures, and sheet layout.
    func configurationDidChange() {
        updateDefaultDragHandle()
        updateBackgroundBlur()
        updateBackgroundCardEffect()
        sheetPan?.maximumNumberOfTouches = max(1, configuration.maximumNumberOfTouches)
        if !configuration.isScrollDraggingEnabled {
            restoreScrollBounce()
            if scrollMovedSheet, host != nil, !isRemoving, !usesSideLayout { settle(velocity: 0) }
            scrollMovedSheet = false
        }
        updatePanAvailability()
        refreshLayout()
    }

    /// Enables sheet dragging only when allowed by configuration and layout state.
    func updatePanAvailability() {
        sheetPan?.isEnabled = configuration.isDraggingEnabled && !usesSideLayout && !isRemoving
    }

    /// Calculates the sheet frame for the active layout within the given bounds.
    func sheetFrame(in bounds: CGRect) -> CGRect {
        if usesSideLayout {
            let frame = preferredLandscapeFrame
            return CGRect(x: frame.minX.isFinite ? frame.minX : 0, y: frame.minY.isFinite ? frame.minY : 0,
                          width: frame.width.isFinite ? max(0, min(bounds.width, frame.width)) : 0,
                          height: frame.height.isFinite ? max(0, frame.height) : 0)
        }
        let size = preferredPullUpSize
        let width = size.width.isFinite ? max(0, min(bounds.width, size.width)) : 0
        let height = size.height.isFinite ? max(0, size.height) : 0
        let offset = configuration.horizontalOffset.isFinite ? configuration.horizontalOffset : 0
        let inset = configuration.bottomInset.isFinite ? max(0, configuration.bottomInset) : 0
        let rightToLeft = host?.effectiveUserInterfaceLayoutDirection == .rightToLeft
        let horizontalPosition: CGFloat
        switch configuration.horizontalAlignment {
        case .center: horizontalPosition = bounds.midX - width / 2 + offset
        case .leading: horizontalPosition = rightToLeft ? bounds.maxX - width - offset : bounds.minX + offset
        case .trailing: horizontalPosition = rightToLeft ? bounds.minX + offset : bounds.maxX - width - offset
        }
        return CGRect(x: horizontalPosition, y: bounds.maxY - inset - visibleHeight, width: width, height: height)
    }

    /// Reconciles the sheet's position and pan gesture with the current layout.
    func refreshLayout() {
        guard let host, !isRemoving else { return }
        let isSide = usesSideLayout
        if isSide {
            restoreScrollBounce()
            scrollMovedSheet = false
        } else if lastLayoutWasSide && configuration.isSnappingEnabled {
            visibleHeight = physics.nearest(to: visibleHeight)
        } else {
            visibleHeight = physics.clamp(visibleHeight)
        }
        lastLayoutWasSide = isSide
        updateDefaultDragHandle()
        updatePanAvailability()
        updateBackgroundCardProgress(to: visibleHeight)
        view.frame = sheetFrame(in: host.bounds)
    }

    /// Moves an attached sheet to a destination and reports animation completion.
    func moveSheet(to destination: CGFloat, duration: TimeInterval, completion: ((Bool) -> Void)?) {
        guard let host, !isRemoving else {
            completion?(false)
            return
        }
        visibleHeight = destination
        pullUpWillMove(to: destination)
        let frame = sheetFrame(in: host.bounds)
        animatePullUp(action: .move, duration: validDuration(duration), animations: { [weak self] in
            self?.view.frame = frame
            self?.updateBackgroundCardProgress(to: destination)
        }, completion: { [weak self] finished in
            if finished { self?.pullUpDidMove(to: destination) }
            completion?(finished)
        })
    }

    /// Settles the sheet at its bounded release position or selected snap point.
    func settle(velocity: CGFloat) {
        let proposed = configuration.isSnappingEnabled
            ? targetSnapPoint(for: visibleHeight, velocity: velocity, points: snapPoints) : visibleHeight
        let destination = proposed.isFinite ? physics.clamp(proposed) : physics.nearest(to: visibleHeight)
        let duration = snapAnimationDuration(from: visibleHeight, to: destination, velocity: velocity)
        moveSheet(to: destination, duration: duration, completion: nil)
    }

    /// Restores the attached scroll view's bounce setting saved for sheet dragging.
    func restoreScrollBounce() {
        if let savedScrollBounce { scrollView?.bounces = savedScrollBounce }
        savedScrollBounce = nil
    }

    /// Updates the sheet position in response to its own pan gesture.
    @objc func handleSheetPan(_ recognizer: UIPanGestureRecognizer) {
        guard let host, !usesSideLayout, !isRemoving else { return }
        switch recognizer.state {
        case .changed:
            let translation = recognizer.translation(in: host).y
            visibleHeight = physics.clamp(visibleHeight - translation, overshoot: bounceOffset)
            view.frame = sheetFrame(in: host.bounds)
            updateBackgroundCardProgress(to: visibleHeight)
            recognizer.setTranslation(.zero, in: host)
            pullUpDidDrag(to: visibleHeight)
        case .ended:
            settle(velocity: recognizer.velocity(in: host).y)
        case .cancelled, .failed:
            settle(velocity: 0)
        default: break
        }
    }

    /// Coordinates an attached scroll view's pan gesture with sheet dragging.
    @objc func handleScrollPan(_ recognizer: UIPanGestureRecognizer) {
        guard let scrollView, let host, configuration.isScrollDraggingEnabled, !usesSideLayout, !isRemoving else {
            restoreScrollBounce()
            scrollMovedSheet = false
            return
        }
        switch recognizer.state {
        case .began:
            scrollMovedSheet = false
            recognizer.setTranslation(.zero, in: host)
        case .changed:
            let translation = recognizer.translation(in: host).y
            if shouldDragPullUp(from: scrollView, translation: translation) {
                if savedScrollBounce == nil { savedScrollBounce = scrollView.bounces }
                scrollView.bounces = false
                let top = -scrollView.adjustedContentInset.top
                scrollView.setContentOffset(CGPoint(x: scrollView.contentOffset.x, y: top), animated: false)
                let allowance = configuration.allowsScrollDragBounce ? bounceOffset : 0
                visibleHeight = physics.clamp(visibleHeight - translation, overshoot: allowance)
                view.frame = sheetFrame(in: host.bounds)
                updateBackgroundCardProgress(to: visibleHeight)
                pullUpDidDrag(to: visibleHeight)
                scrollMovedSheet = true
            }
            recognizer.setTranslation(.zero, in: host)
        case .ended, .cancelled, .failed:
            restoreScrollBounce()
            if scrollMovedSheet {
                let top = -scrollView.adjustedContentInset.top
                let tolerance = configuration.scrollTopTolerance.isFinite ? max(0, configuration.scrollTopTolerance) : 0
                let shouldUseVelocity = recognizer.state == .ended && scrollView.contentOffset.y <= top + tolerance
                settle(velocity: shouldUseVelocity ? recognizer.velocity(in: host).y : 0)
            }
            scrollMovedSheet = false
        default: break
        }
    }
}
