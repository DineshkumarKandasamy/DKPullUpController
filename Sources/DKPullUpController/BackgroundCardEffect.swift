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
            backgroundCardBackdropView?.backgroundColor = configuration.backgroundCardBackdropColor
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
            guard let parentView = backgroundCardTransformedView, let host else { return }
            backgroundCardInteractionScale = scale
            let cardTransform = CGAffineTransform(translationX: 0, y: offset).scaledBy(x: scale, y: scale)
            parentView.transform = (backgroundCardOriginalTransform ?? .identity).concatenating(cardTransform)
            host.transform = backgroundCardOriginalHostTransform ?? .identity
            let originalRadius = backgroundCardOriginalCornerRadius ?? 0
            let targetRadius = configuration.backgroundCardCornerRadius.isFinite
                ? max(0, configuration.backgroundCardCornerRadius) : 0
            parentView.layer.cornerRadius = originalRadius + (targetRadius - originalRadius) * progress
            parentView.layer.cornerCurve = .continuous
            parentView.clipsToBounds = false
            parentView.layer.masksToBounds = false
        case .snapshot:
            backgroundCardInteractionScale = 1
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
        if let parentView = backgroundCardTransformedView {
            if let originalTransform = backgroundCardOriginalTransform {
                parentView.transform = originalTransform
            }
            if let originalCornerRadius = backgroundCardOriginalCornerRadius {
                parentView.layer.cornerRadius = originalCornerRadius
            }
            if let originalCornerCurve = backgroundCardOriginalCornerCurve {
                parentView.layer.cornerCurve = originalCornerCurve
            }
            if let originalMasksToBounds = backgroundCardOriginalMasksToBounds {
                parentView.layer.masksToBounds = originalMasksToBounds
            }
            if let originalClipsToBounds = backgroundCardOriginalClipsToBounds {
                parentView.clipsToBounds = originalClipsToBounds
            }
        }
        host?.transform = backgroundCardOriginalHostTransform ?? .identity
        backgroundCardBackdropView?.removeFromSuperview()
        backgroundCardBackdropView = nil
        backgroundCardSnapshotView?.removeFromSuperview()
        backgroundCardSnapshotView = nil
        host?.backgroundColor = .clear
        host?.passesTouchesThrough = true
        backgroundCardInteractionScale = 1
        backgroundCardTransformedView = nil
        backgroundCardOriginalTransform = nil
        backgroundCardOriginalHostTransform = nil
        backgroundCardOriginalCornerRadius = nil
        backgroundCardOriginalCornerCurve = nil
        backgroundCardOriginalMasksToBounds = nil
        backgroundCardOriginalClipsToBounds = nil
        activeBackgroundCardContentMode = nil
    }

    /// Saves the parent appearance and places a backdrop behind its transformed card.
    private func installLiveBackgroundCard(parentView: UIView, host: SheetHostView) {
        guard backgroundCardTransformedView == nil,
              let superview = parentView.superview else { return }
        backgroundCardTransformedView = parentView
        backgroundCardOriginalTransform = parentView.transform
        backgroundCardOriginalHostTransform = host.transform
        backgroundCardOriginalCornerRadius = parentView.layer.cornerRadius
        backgroundCardOriginalCornerCurve = parentView.layer.cornerCurve
        backgroundCardOriginalMasksToBounds = parentView.layer.masksToBounds
        backgroundCardOriginalClipsToBounds = parentView.clipsToBounds

        let backdrop = UIView(frame: parentView.frame)
        backdrop.backgroundColor = configuration.backgroundCardBackdropColor
        backdrop.isUserInteractionEnabled = false
        backdrop.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        superview.insertSubview(backdrop, belowSubview: parentView)
        backgroundCardBackdropView = backdrop
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
