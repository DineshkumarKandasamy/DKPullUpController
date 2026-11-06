//
//  SheetHostView.swift
//  DKPullUpController
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import UIKit

/// Container view that hosts a pull-up sheet and forwards size changes to it.
@MainActor
final class SheetHostView: UIView {
    /// Closure called when the container's bounds size changes.
    var onResize: (() -> Void)?
    private var previousSize: CGSize = .zero

    /// Creates a host view and records its initial bounds size.
    override init(frame: CGRect) {
        super.init(frame: frame)
        previousSize = bounds.size
    }

    /// Creates a host view from a decoded interface and records its bounds size.
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        previousSize = bounds.size
    }

    /// Notifies the controller when the host view's bounds size changes.
    override func layoutSubviews() {
        super.layoutSubviews()
        guard previousSize != bounds.size else { return }
        previousSize = bounds.size
        onResize?()
    }

    /// Prevents empty areas of the host view from intercepting touches.
    /// - Parameters:
    ///   - point: The point to test in the view's coordinate system.
    ///   - event: The event associated with the hit test.
    /// - Returns: The hit subview, or `nil` when the point hits only the host.
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result === self ? nil : result
    }
}

/// Routes the sheet pan gesture's touch decision to its owning controller.
@MainActor
final class SheetPanDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var controller: DKPullUpController?

    /// Creates a delegate associated with the given pull-up controller.
    init(controller: DKPullUpController) {
        self.controller = controller
    }

    /// Asks the controller whether the sheet pan gesture should receive a touch.
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        controller?.shouldReceivePullUpTouch(touch) ?? false
    }
}
