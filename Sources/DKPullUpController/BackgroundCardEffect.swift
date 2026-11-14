import UIKit

/// Applies the configured background card presentation to the parent content.
@MainActor
extension DKPullUpController {
    /// Applies changes to the enabled state, content mode, and card appearance.
    func updateBackgroundCardEffect(snapshot: UIView? = nil) {
        guard let host, let parent else { return }
        guard configuration.isBackgroundCardEffectEnabled else {
            resetBackgroundCardEffect()
            return
        }

        if let activeBackgroundCardContentMode,
           activeBackgroundCardContentMode != configuration.backgroundCardContentMode {
            resetBackgroundCardEffect()
        }
        activeBackgroundCardContentMode = configuration.backgroundCardContentMode

        switch configuration.backgroundCardContentMode {
        case .live:
            backgroundCardSnapshotView?.removeFromSuperview()
            backgroundCardSnapshotView = nil
            installLiveBackgroundCard(parentView: parent.view, host: host)
            parent.view.backgroundColor = configuration.backgroundCardBackdropColor
            host.backgroundColor = .clear
            host.passesTouchesThrough = true
        case .snapshot:
            if backgroundCardSnapshotView == nil {
                guard let cardSnapshot = snapshot ?? makeBackgroundCardSnapshot(parentView: parent.view, host: host) else {
                    NSLog("DKPullUpController: Unable to capture the background card snapshot.")
                    return
                }
                installBackgroundCardSnapshot(cardSnapshot, host: host)
            }
            host.backgroundColor = configuration.backgroundCardBackdropColor
            host.passesTouchesThrough = false
        }

        updateBackgroundCardProgress(to: visibleHeight)
    }

    /// Updates the live background card or captured image for the current sheet height.
    func updateBackgroundCardProgress(to height: CGFloat) {
        guard configuration.isBackgroundCardEffectEnabled else { return }
        let maximumHeight = preferredPullUpSize.height
        let progress: CGFloat
        if usesSideLayout || !height.isFinite || !maximumHeight.isFinite || maximumHeight <= 0 {
            progress = 0
        } else {
            progress = min(1, max(0, height / maximumHeight))
        }

        let configuredScale = configuration.backgroundCardScale
        let targetScale = configuredScale.isFinite && configuredScale > 0 && configuredScale <= 1
            ? configuredScale : 1
        let scale = 1 + (targetScale - 1) * progress
        let offset = configuration.backgroundCardVerticalOffset.isFinite
            ? configuration.backgroundCardVerticalOffset * progress : 0
        let radius = configuration.backgroundCardCornerRadius.isFinite
            ? max(0, configuration.backgroundCardCornerRadius) * progress : 0

        switch configuration.backgroundCardContentMode {
        case .live:
            guard let contentView = backgroundCardContentView else { return }
            let cardTransform = CGAffineTransform(translationX: 0, y: offset).scaledBy(x: scale, y: scale)
            contentView.transform = (backgroundCardOriginalTransform ?? .identity).concatenating(cardTransform)
            let originalRadius = backgroundCardOriginalCornerRadius ?? 0
            let targetRadius = configuration.backgroundCardCornerRadius.isFinite
                ? max(0, configuration.backgroundCardCornerRadius) : 0
            contentView.layer.cornerRadius = originalRadius + (targetRadius - originalRadius) * progress
            contentView.layer.cornerCurve = .continuous
            contentView.clipsToBounds = progress > 0
            contentView.layer.masksToBounds = progress > 0
        case .snapshot:
            guard let snapshot = backgroundCardSnapshotView else { return }
            snapshot.isHidden = progress == 0
            snapshot.transform = CGAffineTransform(translationX: 0, y: offset).scaledBy(x: scale, y: scale)
            snapshot.layer.cornerRadius = radius
            snapshot.layer.cornerCurve = .continuous
            snapshot.layer.masksToBounds = true
        }
    }

    /// Removes temporary card views and restores the parent's original appearance.
    func resetBackgroundCardEffect() {
        NSLayoutConstraint.deactivate(backgroundCardContentConstraints ?? [])
        NSLayoutConstraint.deactivate(backgroundCardContainerConstraints ?? [])
        if let parentView = backgroundCardParentView {
            for subview in backgroundCardOriginalSubviews ?? [] where subview.superview !== parentView {
                if let host, subview === host { continue }
                if let host, host.superview === parentView {
                    parentView.insertSubview(subview, belowSubview: host)
                } else {
                    parentView.addSubview(subview)
                }
            }
            NSLayoutConstraint.activate(backgroundCardOriginalConstraints ?? [])
            parentView.backgroundColor = backgroundCardOriginalParentBackgroundColor
        }
        if let contentView = backgroundCardContentView {
            contentView.transform = backgroundCardOriginalTransform ?? .identity
            if let originalCornerRadius = backgroundCardOriginalCornerRadius {
                contentView.layer.cornerRadius = originalCornerRadius
            }
            if let originalCornerCurve = backgroundCardOriginalCornerCurve {
                contentView.layer.cornerCurve = originalCornerCurve
            }
            if let originalMasksToBounds = backgroundCardOriginalMasksToBounds {
                contentView.layer.masksToBounds = originalMasksToBounds
            }
            if let originalClipsToBounds = backgroundCardOriginalClipsToBounds {
                contentView.clipsToBounds = originalClipsToBounds
            }
            contentView.removeFromSuperview()
        }
        backgroundCardSnapshotView?.removeFromSuperview()
        backgroundCardSnapshotView = nil
        host?.backgroundColor = .clear
        host?.passesTouchesThrough = true
        backgroundCardParentView = nil
        backgroundCardContentView = nil
        backgroundCardOriginalSubviews = nil
        backgroundCardOriginalConstraints = nil
        backgroundCardContainerConstraints = nil
        backgroundCardContentConstraints = nil
        backgroundCardOriginalParentBackgroundColor = nil
        backgroundCardOriginalTransform = nil
        backgroundCardOriginalCornerRadius = nil
        backgroundCardOriginalCornerCurve = nil
        backgroundCardOriginalMasksToBounds = nil
        backgroundCardOriginalClipsToBounds = nil
        activeBackgroundCardContentMode = nil
    }

    /// Moves parent content into a transformable sibling while keeping the sheet host untransformed.
    private func installLiveBackgroundCard(parentView: UIView, host: SheetHostView) {
        guard backgroundCardContentView == nil else { return }
        let originalSubviews = parentView.subviews.filter { $0 !== host }
        let originalConstraints = parentView.constraints.filter { constraint in
            constraint.isActive && (
                originalSubviews.contains { contentSubview in
                    if let firstView = constraint.firstItem as? UIView,
                       firstView === contentSubview || firstView.isDescendant(of: contentSubview) {
                        return true
                    }
                    if let secondView = constraint.secondItem as? UIView,
                       secondView === contentSubview || secondView.isDescendant(of: contentSubview) {
                        return true
                    }
                    return false
                }
            )
        }
        NSLayoutConstraint.deactivate(originalConstraints)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        contentView.backgroundColor = parentView.backgroundColor
        contentView.directionalLayoutMargins = parentView.directionalLayoutMargins
        contentView.insetsLayoutMarginsFromSafeArea = parentView.insetsLayoutMarginsFromSafeArea
        parentView.insertSubview(contentView, at: 0)
        let containerConstraints = [
            contentView.leadingAnchor.constraint(equalTo: parentView.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: parentView.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: parentView.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: parentView.bottomAnchor)
        ]
        NSLayoutConstraint.activate(containerConstraints)

        for subview in originalSubviews {
            subview.removeFromSuperview()
            contentView.addSubview(subview)
        }

        let contentConstraints = originalConstraints.map { constraint in
            @MainActor
            func mappedItem(_ item: Any?) -> Any? {
                if let itemView = item as? UIView, itemView === parentView {
                    return contentView
                }
                if let guide = item as? UILayoutGuide, guide.owningView === parentView {
                    if guide === parentView.safeAreaLayoutGuide { return contentView.safeAreaLayoutGuide }
                    if guide === parentView.layoutMarginsGuide { return contentView.layoutMarginsGuide }
                }
                return item
            }

            let copy = NSLayoutConstraint(
                item: mappedItem(constraint.firstItem)!,
                attribute: constraint.firstAttribute,
                relatedBy: constraint.relation,
                toItem: mappedItem(constraint.secondItem),
                attribute: constraint.secondAttribute,
                multiplier: constraint.multiplier,
                constant: constraint.constant
            )
            copy.priority = constraint.priority
            copy.identifier = constraint.identifier
            copy.shouldBeArchived = constraint.shouldBeArchived
            return copy
        }
        NSLayoutConstraint.activate(contentConstraints)

        backgroundCardParentView = parentView
        backgroundCardContentView = contentView
        backgroundCardOriginalSubviews = originalSubviews
        backgroundCardOriginalConstraints = originalConstraints
        backgroundCardContainerConstraints = containerConstraints
        backgroundCardContentConstraints = contentConstraints
        backgroundCardOriginalParentBackgroundColor = parentView.backgroundColor
        backgroundCardOriginalTransform = contentView.transform
        backgroundCardOriginalCornerRadius = contentView.layer.cornerRadius
        backgroundCardOriginalCornerCurve = contentView.layer.cornerCurve
        backgroundCardOriginalMasksToBounds = contentView.layer.masksToBounds
        backgroundCardOriginalClipsToBounds = contentView.clipsToBounds
    }

    /// Adds the captured parent content below the sheet view.
    private func installBackgroundCardSnapshot(_ snapshot: UIView, host: SheetHostView) {
        snapshot.isUserInteractionEnabled = false
        snapshot.translatesAutoresizingMaskIntoConstraints = false
        if view.superview === host {
            host.insertSubview(snapshot, belowSubview: view)
        } else {
            host.insertSubview(snapshot, at: 0)
        }
        backgroundCardSnapshotView = snapshot
        NSLayoutConstraint.activate([
            snapshot.leadingAnchor.constraint(equalTo: host.leadingAnchor),
            snapshot.trailingAnchor.constraint(equalTo: host.trailingAnchor),
            snapshot.topAnchor.constraint(equalTo: host.topAnchor),
            snapshot.bottomAnchor.constraint(equalTo: host.bottomAnchor)
        ])
    }

    /// Captures the parent without including the sheet host.
    private func makeBackgroundCardSnapshot(parentView: UIView, host: SheetHostView) -> UIView? {
        let wasHidden = host.isHidden
        host.isHidden = true
        let snapshot = parentView.snapshotView(afterScreenUpdates: true)
        host.isHidden = wasHidden
        return snapshot
    }
}
