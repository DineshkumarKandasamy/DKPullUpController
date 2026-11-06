//
//  SheetHostView.swift
//  DKPullUpController
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import UIKit

@MainActor
final class SheetHostView: UIView {
    var onResize: (() -> Void)?
    private var previousSize: CGSize = .zero

    override init(frame: CGRect) {
        super.init(frame: frame)
        previousSize = bounds.size
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        previousSize = bounds.size
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard previousSize != bounds.size else { return }
        previousSize = bounds.size
        onResize?()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let result = super.hitTest(point, with: event)
        return result === self ? nil : result
    }
}

@MainActor
final class SheetPanDelegate: NSObject, UIGestureRecognizerDelegate {
    weak var controller: DKPullUpController?

    init(controller: DKPullUpController) {
        self.controller = controller
    }

    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        controller?.shouldReceivePullUpTouch(touch) ?? false
    }
}
