//
//  DKPullUpConfiguration.swift
//  DKPullUpController
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import UIKit

@objc(DKPullUpLayoutMode)
public enum DKPullUpLayoutMode: Int {
    /// Selects side layout for wider-than-tall parents; otherwise uses bottom layout.
    case automatic
    /// Uses bottom layout regardless of the parent size.
    case bottom
    /// Uses the preferred side frame and disables sheet dragging.
    case side
}

@objc(DKPullUpHorizontalAlignment)
public enum DKPullUpHorizontalAlignment: Int {
    /// Aligns the sheet with the parent's leading edge.
    case leading
    /// Centers the sheet within the parent.
    case center
    /// Aligns the sheet with the parent's trailing edge.
    case trailing
}

@objc(DKPullUpBackgroundBlurStyle)
public enum DKPullUpBackgroundBlurStyle: Int {
    /// Uses an ultra-thin system material.
    case systemUltraThinMaterial
    /// Uses a thin system material.
    case systemThinMaterial
    /// Uses the standard system material.
    case systemMaterial
    /// Uses a thick system material.
    case systemThickMaterial
    /// Uses the system chrome material.
    case systemChromeMaterial
    /// Uses a light blur.
    case light
    /// Uses a dark blur.
    case dark

    var uiBlurEffectStyle: UIBlurEffect.Style {
        switch self {
        case .systemUltraThinMaterial: .systemUltraThinMaterial
        case .systemThinMaterial: .systemThinMaterial
        case .systemMaterial: .systemMaterial
        case .systemThickMaterial: .systemThickMaterial
        case .systemChromeMaterial: .systemChromeMaterial
        case .light: .light
        case .dark: .dark
        }
    }
}

/// Selects whether the background card uses live content or a captured image.
@objc(DKPullUpBackgroundCardContentMode)
public enum DKPullUpBackgroundCardContentMode: Int {
    /// Scales live parent content while keeping its controls interactive in their displayed positions.
    case live
    /// Scales a captured image and blocks touches outside the sheet.
    case snapshot
}

/// Settings for positioning, dragging, and animating a pull-up sheet.
///
/// Assign a configuration to ``DKPullUpController/configuration`` before or
/// after presentation. Changes update the sheet's layout and gestures.
public struct DKPullUpConfiguration {
    public typealias LayoutMode = DKPullUpLayoutMode
    public typealias HorizontalAlignment = DKPullUpHorizontalAlignment
    public typealias BackgroundBlurStyle = DKPullUpBackgroundBlurStyle
    public typealias BackgroundCardContentMode = DKPullUpBackgroundCardContentMode

    /// The layout mode. Defaults to ``LayoutMode/automatic``.
    public var layoutMode: LayoutMode = .automatic
    /// The horizontal alignment in bottom layout. Defaults to ``HorizontalAlignment/center``.
    public var horizontalAlignment: HorizontalAlignment = .center
    /// Horizontal offset in points. Positive edge-aligned offsets move inward;
    /// positive centered offsets move right. Defaults to zero.
    public var horizontalOffset: CGFloat = 0
    /// Distance in points above the parent's bottom edge used as the sheet's
    /// reference edge. Safe-area insets are not applied automatically. Defaults to zero.
    public var bottomInset: CGFloat = 0
    /// Enables the sheet's own pan gesture. Defaults to `true`.
    public var isDraggingEnabled = true
    /// Enables sheet dragging through an attached scroll view. Defaults to `true`.
    public var isScrollDraggingEnabled = true
    /// Settles the sheet at a snap point after a drag. When `false`, the sheet
    /// remains at its bounded release position. Defaults to `true`.
    public var isSnappingEnabled = true
    /// Allows scroll-driven drags to extend beyond the snap range by the
    /// controller's bounce offset. Defaults to `false`.
    public var allowsScrollDragBounce = false
    /// Maximum touches accepted by the sheet pan gesture. Values below one are
    /// treated as one. Defaults to `1`.
    public var maximumNumberOfTouches = 1
    /// Shows the built-in handle when no custom handle is selected. Defaults to `true`.
    public var showsDefaultDragHandle = true
    /// Enables the built-in blur behind the sheet content. Defaults to `false`.
    public var isBackgroundBlurEnabled = false
    /// Style used by the built-in blur when enabled. Defaults to `.systemMaterial`.
    public var backgroundBlurStyle: BackgroundBlurStyle = .systemMaterial
    /// Enables the background card effect behind the sheet. Defaults to `false`.
    public var isBackgroundCardEffectEnabled = false
    /// Target scale for the background card. Values outside `(0, 1]` use `1`.
    public var backgroundCardScale: CGFloat = 0.9
    /// Vertical translation in points at the maximum sheet height; positive values move down.
    /// Defaults to `24`.
    public var backgroundCardVerticalOffset: CGFloat = 24
    /// Target corner radius, in points, at the maximum sheet height. Defaults to `24`.
    public var backgroundCardCornerRadius: CGFloat = 24
    /// Color visible around the scaled background card. Defaults to `.systemBackground`.
    public var backgroundCardBackdropColor: UIColor = .systemBackground
    /// Content mode used by the background card effect. Defaults to `.live`.
    public var backgroundCardContentMode: BackgroundCardContentMode = .live
    /// Color of the built-in handle. Defaults to the dynamic tertiary label color.
    public var defaultDragHandleColor: UIColor = .tertiaryLabel
    /// Width of the built-in handle in points. Defaults to `40`.
    /// Negative or non-finite values are treated as zero.
    public var defaultDragHandleWidth: CGFloat = 40
    /// Height of the built-in handle in points. Defaults to `5`.
    /// Negative or non-finite values are treated as zero.
    public var defaultDragHandleHeight: CGFloat = 5
    /// Corner radius of the built-in handle in points. Defaults to `2.5`.
    /// Negative or non-finite values are treated as zero.
    public var defaultDragHandleCornerRadius: CGFloat = 2.5
    /// Distance from the sheet's top edge in points. Defaults to `10`.
    /// Negative or non-finite values are treated as zero.
    public var defaultDragHandleTopInset: CGFloat = 10
    /// Presentation animation duration in seconds. Defaults to `0.3`.
    public var presentationDuration: TimeInterval = 0.3
    /// Dismissal animation duration in seconds. Defaults to `0.3`.
    public var dismissalDuration: TimeInterval = 0.3
    /// Duration in seconds for programmatic moves and preferred-frame updates.
    /// Defaults to `0.3`.
    public var movementDuration: TimeInterval = 0.3
    /// Minimum release-animation duration in seconds, limited to the configured
    /// maximum. Defaults to `0.08`.
    public var minimumSnapDuration: TimeInterval = 0.08
    /// Maximum release-animation duration in seconds. Defaults to `0.3`.
    public var maximumSnapDuration: TimeInterval = 0.3
    /// Uses release speed and distance to calculate the release duration. When
    /// `false`, the maximum duration is used. Defaults to `true`.
    public var usesVelocityForSnapDuration = true
    /// Allowance in points when determining whether an attached scroll view is
    /// at its adjusted top. Defaults to `0.5`.
    public var scrollTopTolerance: CGFloat = 0.5

    /// Creates a configuration with the default settings.
    public init() { }
}
