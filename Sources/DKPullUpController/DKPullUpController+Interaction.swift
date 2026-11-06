//
//  DKPullUpController+Interaction.swift
//  DKPullUpController
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import UIKit

extension DKPullUpController {
    var usesSideLayout: Bool {
        guard let host else { return false }
        switch configuration.layoutMode {
        case .automatic: return host.bounds.width > host.bounds.height
        case .bottom: return false
        case .side: return true
        }
    }

    func validDuration(_ value: TimeInterval) -> TimeInterval {
        value.isFinite ? max(0, value) : 0
    }

    func configurationDidChange() {
        sheetPan?.maximumNumberOfTouches = max(1, configuration.maximumNumberOfTouches)
        if !configuration.isScrollDraggingEnabled {
            restoreScrollBounce()
            if scrollMovedSheet, host != nil, !isRemoving, !usesSideLayout { settle(velocity: 0) }
            scrollMovedSheet = false
        }
        updatePanAvailability()
        refreshLayout()
    }

    func updatePanAvailability() {
        sheetPan?.isEnabled = configuration.isDraggingEnabled && !usesSideLayout && !isRemoving
    }

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
        updatePanAvailability()
        view.frame = sheetFrame(in: host.bounds)
    }

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
        }, completion: { [weak self] finished in
            if finished { self?.pullUpDidMove(to: destination) }
            completion?(finished)
        })
    }

    func settle(velocity: CGFloat) {
        let proposed = configuration.isSnappingEnabled
            ? targetSnapPoint(for: visibleHeight, velocity: velocity, points: snapPoints) : visibleHeight
        let destination = proposed.isFinite ? physics.clamp(proposed) : physics.nearest(to: visibleHeight)
        let duration = snapAnimationDuration(from: visibleHeight, to: destination, velocity: velocity)
        moveSheet(to: destination, duration: duration, completion: nil)
    }

    func restoreScrollBounce() {
        if let savedScrollBounce { scrollView?.bounces = savedScrollBounce }
        savedScrollBounce = nil
    }

    @objc func handleSheetPan(_ recognizer: UIPanGestureRecognizer) {
        guard let host, !usesSideLayout, !isRemoving else { return }
        switch recognizer.state {
        case .changed:
            let translation = recognizer.translation(in: host).y
            visibleHeight = physics.clamp(visibleHeight - translation, overshoot: bounceOffset)
            view.frame = sheetFrame(in: host.bounds)
            recognizer.setTranslation(.zero, in: host)
            pullUpDidDrag(to: visibleHeight)
        case .ended:
            settle(velocity: recognizer.velocity(in: host).y)
        case .cancelled, .failed:
            settle(velocity: 0)
        default: break
        }
    }

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
