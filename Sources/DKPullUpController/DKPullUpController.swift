//
//  DKPullUpController.swift
//  DKPullUpController
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import UIKit

@MainActor
private final class PullUpAccessibilityHandleView: UIView {
    var onIncrement: (() -> Void)?
    var onDecrement: (() -> Void)?

    override func accessibilityIncrement() {
        onIncrement?()
    }

    override func accessibilityDecrement() {
        onDecrement?()
    }
}

/// A child controller whose content can be dragged between visible heights.
///
/// Subclass this controller to provide the sheet's content and preferred size,
/// then add it to a parent using ``add(to:initialVisibleHeight:animated:completion:)``.
/// Heights are measured above the configured bottom inset. All operations run
/// on the main actor.
@MainActor
@objc(DKPullUpController)
open class DKPullUpController: UIViewController {
    /// The operation being passed to the animation hook.
    @objc(DKPullUpAction)
    public enum Action: Int {
        /// The sheet is being presented.
        case add
        /// The sheet is being removed.
        case remove
        /// The sheet is moving or updating its preferred frame.
        case move
    }

    /// Preferred size in bottom layout. The width is limited to the parent's
    /// width, and the height sets the maximum snap position. The default width
    /// is the parent width or `320` before attachment; the default height is `400`.
    /// Call ``updatePreferredFrame(animated:)`` after changing the returned size.
    @objc open var preferredPullUpSize: CGSize {
        objectiveCPreferredSize ?? CGSize(width: parent?.view.bounds.width ?? 320, height: 400)
    }

    private var objectiveCPreferredSize: CGSize?

    /// Preferred bottom-layout size for Objective-C clients that configure the
    /// controller without subclassing it.
    @objc public var pullUpPreferredSize: CGSize {
        get { preferredPullUpSize }
        set {
            objectiveCPreferredSize = newValue
            updatePreferredFrame(animated: false)
        }
    }

    /// Preferred frame in the parent's coordinate space for side layout.
    /// The default uses a 16-point inset and a width of at most 360 points.
    /// Call ``updatePreferredFrame(animated:)`` after changing the returned frame.
    @objc open var preferredLandscapeFrame: CGRect {
        if let objectiveCPreferredLandscapeFrame { return objectiveCPreferredLandscapeFrame }
        let bounds = parent?.view.bounds ?? .zero
        return CGRect(x: 16, y: 16, width: min(360, max(0, bounds.width - 32)), height: max(0, bounds.height - 32))
    }

    private var objectiveCPreferredLandscapeFrame: CGRect?

    /// Preferred side-layout frame for Objective-C clients that configure the
    /// controller without subclassing it.
    @objc public var pullUpPreferredLandscapeFrame: CGRect {
        get { preferredLandscapeFrame }
        set {
            objectiveCPreferredLandscapeFrame = newValue
            updatePreferredFrame(animated: false)
        }
    }

    /// Additional visible heights in points, excluding the initial and maximum
    /// heights. Values are bounded, sorted, and deduplicated. Defaults to empty.
    /// Call ``updatePreferredFrame(animated:)`` after changing the returned points.
    open var middleSnapPoints: [CGFloat] {
        objectiveCIntermediateSnapPoints ?? pullUpMiddleSnapPoints().map { CGFloat(truncating: $0) }
    }

    private var objectiveCIntermediateSnapPoints: [CGFloat]?

    /// Intermediate snap positions for Objective-C clients that configure the
    /// controller without subclassing it.
    @objc public var pullUpIntermediateSnapPoints: [NSNumber] {
        get { middleSnapPoints.map { NSNumber(value: Double($0)) } }
        set {
            objectiveCIntermediateSnapPoints = newValue.map { CGFloat(truncating: $0) }
            updatePreferredFrame(animated: false)
        }
    }

    /// Objective-C override point for additional visible heights.
    @objc open func pullUpMiddleSnapPoints() -> [NSNumber] { [] }

    /// Extra distance in points that a drag may extend beyond the snap range.
    /// Scroll-driven drags use it only when scroll drag bounce is enabled. Defaults to `0`.
    @objc open var bounceOffset: CGFloat { 0 }
    /// Absolute release velocity in points per second above which the default
    /// snap target uses a projected position. Defaults to `700`.
    @objc open var skipPointVelocity: CGFloat { 700 }

    /// Layout, gesture, and animation settings. Changes update the loaded sheet.
    public var configuration = DKPullUpConfiguration() {
        didSet { configurationDidChange() }
    }

    @objc public var layoutMode: DKPullUpLayoutMode {
        get { configuration.layoutMode }
        set { configuration.layoutMode = newValue }
    }
    @objc public var horizontalAlignment: DKPullUpHorizontalAlignment {
        get { configuration.horizontalAlignment }
        set { configuration.horizontalAlignment = newValue }
    }
    @objc public var horizontalOffset: CGFloat {
        get { configuration.horizontalOffset }
        set { configuration.horizontalOffset = newValue }
    }
    @objc public var bottomInset: CGFloat {
        get { configuration.bottomInset }
        set { configuration.bottomInset = newValue }
    }
    @objc public var isDraggingEnabled: Bool {
        get { configuration.isDraggingEnabled }
        set { configuration.isDraggingEnabled = newValue }
    }
    @objc public var isScrollDraggingEnabled: Bool {
        get { configuration.isScrollDraggingEnabled }
        set { configuration.isScrollDraggingEnabled = newValue }
    }
    @objc public var isSnappingEnabled: Bool {
        get { configuration.isSnappingEnabled }
        set { configuration.isSnappingEnabled = newValue }
    }
    @objc public var allowsScrollDragBounce: Bool {
        get { configuration.allowsScrollDragBounce }
        set { configuration.allowsScrollDragBounce = newValue }
    }
    @objc public var maximumNumberOfTouches: Int {
        get { configuration.maximumNumberOfTouches }
        set { configuration.maximumNumberOfTouches = newValue }
    }
    @objc public var showsDefaultDragHandle: Bool {
        get { configuration.showsDefaultDragHandle }
        set { configuration.showsDefaultDragHandle = newValue }
    }
    @objc public var isBackgroundBlurEnabled: Bool {
        get { configuration.isBackgroundBlurEnabled }
        set { configuration.isBackgroundBlurEnabled = newValue }
    }
    @objc public var backgroundBlurStyle: DKPullUpBackgroundBlurStyle {
        get { configuration.backgroundBlurStyle }
        set { configuration.backgroundBlurStyle = newValue }
    }
    @objc public var isBackgroundCardEffectEnabled: Bool {
        get { configuration.isBackgroundCardEffectEnabled }
        set { configuration.isBackgroundCardEffectEnabled = newValue }
    }
    @objc public var backgroundCardScale: CGFloat {
        get { configuration.backgroundCardScale }
        set { configuration.backgroundCardScale = newValue }
    }
    @objc public var backgroundCardVerticalOffset: CGFloat {
        get { configuration.backgroundCardVerticalOffset }
        set { configuration.backgroundCardVerticalOffset = newValue }
    }
    @objc public var backgroundCardCornerRadius: CGFloat {
        get { configuration.backgroundCardCornerRadius }
        set { configuration.backgroundCardCornerRadius = newValue }
    }
    @objc public var backgroundCardBackdropColor: UIColor {
        get { configuration.backgroundCardBackdropColor }
        set { configuration.backgroundCardBackdropColor = newValue }
    }
    @objc public var backgroundCardContentMode: DKPullUpBackgroundCardContentMode {
        get { configuration.backgroundCardContentMode }
        set { configuration.backgroundCardContentMode = newValue }
    }
    @objc public var pullUpDefaultDragHandleColor: UIColor {
        get { configuration.defaultDragHandleColor }
        set { configuration.defaultDragHandleColor = newValue }
    }
    @objc public var pullUpDefaultDragHandleWidth: CGFloat {
        get { configuration.defaultDragHandleWidth }
        set { configuration.defaultDragHandleWidth = newValue }
    }
    @objc public var pullUpDefaultDragHandleHeight: CGFloat {
        get { configuration.defaultDragHandleHeight }
        set { configuration.defaultDragHandleHeight = newValue }
    }
    @objc public var pullUpDefaultDragHandleCornerRadius: CGFloat {
        get { configuration.defaultDragHandleCornerRadius }
        set { configuration.defaultDragHandleCornerRadius = newValue }
    }
    @objc public var pullUpDefaultDragHandleTopInset: CGFloat {
        get { configuration.defaultDragHandleTopInset }
        set { configuration.defaultDragHandleTopInset = newValue }
    }
    @objc public var presentationDuration: TimeInterval {
        get { configuration.presentationDuration }
        set { configuration.presentationDuration = newValue }
    }
    @objc public var dismissalDuration: TimeInterval {
        get { configuration.dismissalDuration }
        set { configuration.dismissalDuration = newValue }
    }
    @objc public var movementDuration: TimeInterval {
        get { configuration.movementDuration }
        set { configuration.movementDuration = newValue }
    }
    @objc public var minimumSnapDuration: TimeInterval {
        get { configuration.minimumSnapDuration }
        set { configuration.minimumSnapDuration = newValue }
    }
    @objc public var maximumSnapDuration: TimeInterval {
        get { configuration.maximumSnapDuration }
        set { configuration.maximumSnapDuration = newValue }
    }
    @objc public var usesVelocityForSnapDuration: Bool {
        get { configuration.usesVelocityForSnapDuration }
        set { configuration.usesVelocityForSnapDuration = newValue }
    }
    @objc public var scrollTopTolerance: CGFloat {
        get { configuration.scrollTopTolerance }
        set { configuration.scrollTopTolerance = newValue }
    }

    /// Current bottom-layout height in points above the bottom inset. In side
    /// layout, this retains the bottom-layout height rather than the side height.
    @objc public internal(set) var visibleHeight: CGFloat = 0 {
        didSet { updateDefaultDragHandleAccessibilityValue() }
    }
    /// The sheet's pan gesture after its view loads, or `nil` before then.
    /// Keep its target and delegate intact so sheet dragging continues to work.
    @objc public var pullUpPanGestureRecognizer: UIPanGestureRecognizer? { sheetPan }
    /// Sorted, unique snap positions, including the initial and preferred heights.
    /// Non-finite values are excluded and positions are limited to the preferred height.
    public var snapPoints: [CGFloat] { physics.positions }

    /// Objective-C representation of the current snap positions.
    @objc public var pullUpSnapPoints: [NSNumber] {
        physics.positions.map { NSNumber(value: Double($0)) }
    }

    /// Optional content view hosted inside the sheet.
    @objc public var pullUpContentView: UIView? {
        didSet { updatePullUpContentView() }
    }

    private var installedContentView: UIView?
    private var contentViewConstraints: [NSLayoutConstraint] = []

    var initialHeight: CGFloat = 0
    var host: SheetHostView?
    var sheetPan: UIPanGestureRecognizer?
    var panDelegate: SheetPanDelegate?
    var backgroundCardSnapshotView: UIView?
    weak var backgroundCardParentView: UIView?
    var backgroundCardContentView: UIView?
    var backgroundCardOriginalSubviews: [UIView]?
    var backgroundCardOriginalConstraints: [NSLayoutConstraint]?
    var backgroundCardContainerConstraints: [NSLayoutConstraint]?
    var backgroundCardContentConstraints: [NSLayoutConstraint]?
    var backgroundCardOriginalParentBackgroundColor: UIColor?
    var backgroundCardOriginalTransform: CGAffineTransform?
    var backgroundCardOriginalCornerRadius: CGFloat?
    var backgroundCardOriginalCornerCurve: CALayerCornerCurve?
    var backgroundCardOriginalMasksToBounds: Bool?
    var backgroundCardOriginalClipsToBounds: Bool?
    var activeBackgroundCardContentMode: DKPullUpBackgroundCardContentMode?
    private let defaultDragHandle = PullUpAccessibilityHandleView()
    private let backgroundBlurView = UIVisualEffectView()
    private var defaultDragHandleWidth: NSLayoutConstraint?
    private var defaultDragHandleHeight: NSLayoutConstraint?
    private var defaultDragHandleTop: NSLayoutConstraint?
    private var usesCustomDragHandle = false
    weak var scrollView: UIScrollView?
    var savedScrollBounce: Bool?
    var scrollMovedSheet = false
    var isRemoving = false
    var lastLayoutWasSide = false

    var physics: SheetPhysics {
        SheetPhysics(initial: initialHeight, maximum: preferredPullUpSize.height, intermediate: middleSnapPoints)
    }

    /// Sets up the sheet's pan gesture. Subclasses that override this method
    /// must call `super.viewDidLoad()`.
    open override func viewDidLoad() {
        super.viewDidLoad()
        backgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(backgroundBlurView)
        NSLayoutConstraint.activate([
            backgroundBlurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            backgroundBlurView.topAnchor.constraint(equalTo: view.topAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        updatePullUpContentView()
        defaultDragHandle.isUserInteractionEnabled = false
        defaultDragHandle.isAccessibilityElement = true
        defaultDragHandle.accessibilityLabel = "Sheet height"
        defaultDragHandle.accessibilityHint = "Swipe up or down to adjust the sheet height."
        defaultDragHandle.accessibilityTraits = .adjustable
        defaultDragHandle.onIncrement = { [weak self] in self?.adjustToAdjacentSnapPoint(expanding: true) }
        defaultDragHandle.onDecrement = { [weak self] in self?.adjustToAdjacentSnapPoint(expanding: false) }
        defaultDragHandle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(defaultDragHandle)
        defaultDragHandleTop = defaultDragHandle.topAnchor.constraint(equalTo: view.topAnchor)
        defaultDragHandleWidth = defaultDragHandle.widthAnchor.constraint(equalToConstant: 0)
        defaultDragHandleHeight = defaultDragHandle.heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([
            defaultDragHandleTop, defaultDragHandleWidth, defaultDragHandleHeight,
            defaultDragHandle.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ].compactMap { $0 })
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(handleSheetPan(_:)))
        let delegate = SheetPanDelegate(controller: self)
        recognizer.delegate = delegate
        panDelegate = delegate
        sheetPan = recognizer
        view.addGestureRecognizer(recognizer)
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(reduceMotionStatusDidChange(_:)),
            name: UIAccessibility.reduceMotionStatusDidChangeNotification,
            object: nil
        )
        configurationDidChange()
    }

    /// Installs the configured content view and pins it to the sheet's bounds.
    private func updatePullUpContentView() {
        guard isViewLoaded else { return }
        NSLayoutConstraint.deactivate(contentViewConstraints)
        installedContentView?.removeFromSuperview()
        installedContentView = pullUpContentView
        contentViewConstraints = []
        guard let contentView = installedContentView else { return }
        contentView.translatesAutoresizingMaskIntoConstraints = false
        view.insertSubview(contentView, aboveSubview: backgroundBlurView)
        contentViewConstraints = [
            contentView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentView.topAnchor.constraint(equalTo: view.topAnchor),
            contentView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ]
        NSLayoutConstraint.activate(contentViewConstraints)
    }

    /// Keeps the built-in drag handle above the sheet's content after layout.
    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(defaultDragHandle)
    }

    /// Applies the configured appearance and visibility to the built-in handle.
    func updateDefaultDragHandle() {
        guard isViewLoaded else { return }
        defaultDragHandle.backgroundColor = configuration.defaultDragHandleColor
        defaultDragHandle.layer.cornerRadius = validHandleDimension(configuration.defaultDragHandleCornerRadius)
        defaultDragHandleWidth?.constant = validHandleDimension(configuration.defaultDragHandleWidth)
        defaultDragHandleHeight?.constant = validHandleDimension(configuration.defaultDragHandleHeight)
        defaultDragHandleTop?.constant = validHandleDimension(configuration.defaultDragHandleTopInset)
        defaultDragHandle.isHidden = usesCustomDragHandle || !configuration.showsDefaultDragHandle
        defaultDragHandle.isAccessibilityElement = !defaultDragHandle.isHidden && !usesSideLayout
        updateDefaultDragHandleAccessibilityValue()
    }

    private func updateDefaultDragHandleAccessibilityValue() {
        guard isViewLoaded else { return }
        defaultDragHandle.accessibilityValue = "\(Int(visibleHeight.rounded())) points"
    }

    private func adjustToAdjacentSnapPoint(expanding: Bool) {
        guard host != nil, !isRemoving, !usesSideLayout else { return }
        let points = snapPoints
        guard let currentIndex = points.firstIndex(of: physics.nearest(to: visibleHeight)) else { return }
        let destinationIndex = expanding ? currentIndex + 1 : currentIndex - 1
        guard points.indices.contains(destinationIndex) else { return }
        move(to: points[destinationIndex], animated: true)
    }

    @objc private func reduceMotionStatusDidChange(_ notification: Notification) {
        updateBackgroundCardProgress(to: visibleHeight)
    }

    /// Applies the configured blur style or removes the blur when disabled.
    func updateBackgroundBlur() {
        backgroundBlurView.effect = configuration.isBackgroundBlurEnabled
            ? UIBlurEffect(style: configuration.backgroundBlurStyle.uiBlurEffectStyle)
            : nil
        backgroundBlurView.isHidden = !configuration.isBackgroundBlurEnabled
    }

    /// Clamps a handle dimension to a finite, nonnegative value.
    private func validHandleDimension(_ value: CGFloat) -> CGFloat {
        value.isFinite ? max(0, value) : 0
    }

    /// Called before a programmatic or release movement begins.
    /// - Parameter visibleHeight: The destination in points above the bottom inset.
    @objc open func pullUpWillMove(to visibleHeight: CGFloat) { }
    /// Called after a programmatic or release movement finishes successfully.
    /// - Parameter visibleHeight: The destination in points above the bottom inset.
    @objc open func pullUpDidMove(to visibleHeight: CGFloat) { }
    /// Called as a gesture changes the sheet's visible height.
    /// - Parameter visibleHeight: The current height in points above the bottom inset.
    @objc open func pullUpDidDrag(to visibleHeight: CGFloat) { }

    /// Selects the destination when a drag ends with snapping enabled.
    ///
    /// The default chooses the nearest point to the current or velocity-projected
    /// position. Fast swipes may cross multiple points. The resulting destination
    /// is limited to the configured snap range.
    /// - Parameters:
    ///   - visibleHeight: The bottom-layout height at release, in points.
    ///   - velocity: Vertical release velocity in points per second; positive is downward.
    ///   - points: The sorted snap points available to the controller.
    /// - Returns: The requested destination in points above the bottom inset.
    open func targetSnapPoint(for visibleHeight: CGFloat, velocity: CGFloat, points: [CGFloat]) -> CGFloat {
        pullUpTargetSnapPoint(
            forVisibleHeight: visibleHeight,
            velocity: velocity,
            points: points.map { NSNumber(value: Double($0)) }
        )
    }

    /// Objective-C override point for selecting a destination snap position.
    @objc open func pullUpTargetSnapPoint(
        forVisibleHeight visibleHeight: CGFloat, velocity: CGFloat, points: [NSNumber]
    ) -> CGFloat {
        let positions = points.map { CGFloat(truncating: $0) }
        let available = SheetPhysics(initial: positions.first ?? 0, maximum: positions.last ?? 0, intermediate: positions)
        return available.destination(from: visibleHeight, velocity: velocity, threshold: skipPointVelocity)
    }

    /// Returns the release-animation duration in seconds.
    ///
    /// The default uses distance and speed within the configured duration bounds.
    /// A zero or non-finite velocity uses the configured maximum duration.
    /// - Parameters:
    ///   - visibleHeight: The bottom-layout height at release, in points.
    ///   - target: The bounded destination height, in points.
    ///   - velocity: Vertical release velocity in points per second.
    /// - Returns: The requested animation duration in seconds.
    @objc open func snapAnimationDuration(
        from visibleHeight: CGFloat, to target: CGFloat, velocity: CGFloat
    ) -> TimeInterval {
        SheetPhysics.duration(
            distance: target - visibleHeight,
            velocity: configuration.usesVelocityForSnapDuration ? velocity : 0,
            minimum: configuration.minimumSnapDuration,
            maximum: configuration.maximumSnapDuration
        )
    }

    /// Determines whether the sheet's pan gesture accepts a touch.
    ///
    /// By default, touches inside an attached scroll view are excluded when the
    /// sheet gesture is on the root view.
    /// - Parameter touch: The touch being evaluated.
    /// - Returns: `true` when the sheet gesture should receive the touch.
    @objc open func shouldReceivePullUpTouch(_ touch: UITouch) -> Bool {
        guard sheetPan?.view === view, let scrollView, let touchedView = touch.view else { return true }
        return touchedView !== scrollView && !touchedView.isDescendant(of: scrollView)
    }

    /// Determines whether an attached scroll view's current pan should move the sheet.
    ///
    /// By default, upward drags expand the sheet and downward drags move it when
    /// the scroll view is at its adjusted top.
    /// - Parameters:
    ///   - scrollView: The attached scroll view.
    ///   - translation: Vertical pan translation in points; positive is downward.
    /// - Returns: `true` when the pan should move the sheet.
    @objc open func shouldDragPullUp(from scrollView: UIScrollView, translation: CGFloat) -> Bool {
        let top = -scrollView.adjustedContentInset.top
        let tolerance = configuration.scrollTopTolerance.isFinite ? max(0, configuration.scrollTopTolerance) : 0
        let allowance = configuration.allowsScrollDragBounce ? bounceOffset : 0
        let maximum = physics.clamp(.greatestFiniteMagnitude, overshoot: allowance)
        return (translation < 0 && visibleHeight < maximum)
            || (translation > 0 && scrollView.contentOffset.y <= top + tolerance)
    }

    /// Performs a presentation, removal, or movement animation.
    ///
    /// Overrides must execute the animations and invoke the completion when
    /// provided, including for zero-duration requests.
    /// - Parameters:
    ///   - action: The operation being animated.
    ///   - duration: Requested duration in seconds.
    ///   - animations: Changes to perform during the animation.
    ///   - completion: Receives whether the animation finished.
    @objc open func animatePullUp(
        action: Action, duration: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)?
    ) {
        guard duration > 0 else {
            animations()
            completion?(true)
            return
        }
        UIView.animate(withDuration: duration, delay: 0, options: [.beginFromCurrentState, .allowUserInteraction],
                       animations: animations, completion: completion)
    }

    /// Adds the sheet as a child of a parent view controller.
    /// - Parameters:
    ///   - parent: The view controller whose view hosts the sheet.
    ///   - initialVisibleHeight: The initial height in points above the bottom
    ///     inset. It must be finite and is limited to the sheet's height.
    ///   - animated: Whether to animate presentation.
    ///   - completion: Receives the animation result, or `false` when the sheet
    ///     is already attached, being removed, or the initial height is invalid.
    @objc(addToParent:initialVisibleHeight:animated:completion:)
    public func add(
        to parent: UIViewController, initialVisibleHeight: CGFloat, animated: Bool = true,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard self.parent == nil, host == nil, !isRemoving, initialVisibleHeight.isFinite else {
            completion?(false)
            return
        }
        let backgroundCardSnapshot: UIView?
        if configuration.isBackgroundCardEffectEnabled,
           configuration.backgroundCardContentMode == .snapshot {
            guard let snapshot = parent.view.snapshotView(afterScreenUpdates: true) else {
                completion?(false)
                return
            }
            backgroundCardSnapshot = snapshot
        } else {
            backgroundCardSnapshot = nil
        }
        initialHeight = initialVisibleHeight
        parent.loadViewIfNeeded()
        parent.addChild(self)
        loadViewIfNeeded()
        let container = SheetHostView(frame: parent.view.bounds)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.onResize = { [weak self] in self?.refreshLayout() }
        container.onWindowChange = { [weak self] in
            self?.updateBackgroundCardEffect()
            self?.refreshLayout()
        }
        host = container
        updateDefaultDragHandle()
        parent.view.addSubview(container)
        container.addSubview(view)
        updateBackgroundCardEffect(snapshot: backgroundCardSnapshot)
        visibleHeight = physics.clamp(initialVisibleHeight)
        lastLayoutWasSide = usesSideLayout
        let destination = sheetFrame(in: container.bounds)
        updateBackgroundCardProgress(to: 0)
        view.frame = animated ? CGRect(x: destination.minX, y: container.bounds.maxY,
                                       width: destination.width, height: destination.height) : destination
        didMove(toParent: parent)
        updatePanAvailability()
        animatePullUp(action: .add, duration: animated ? validDuration(configuration.presentationDuration) : 0,
                      animations: { [weak self] in
                          self?.view.frame = destination
                          self?.updateBackgroundCardProgress(to: self?.visibleHeight ?? 0)
                      }, completion: completion)
    }

    /// Removes the sheet and restores the attached scroll view's bounce setting.
    /// - Parameters:
    ///   - animated: Whether to animate removal.
    ///   - completion: Receives the animation result, or `false` when the sheet
    ///     is not attached or a removal is already in progress.
    @objc(removeAnimated:completion:)
    public func remove(animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        guard parent != nil, let host, !isRemoving else {
            completion?(false)
            return
        }
        isRemoving = true
        willMove(toParent: nil)
        restoreScrollBounce()
        scrollMovedSheet = false
        var destination = view.frame
        destination.origin.y = host.bounds.maxY
        let duration = animated ? validDuration(configuration.dismissalDuration) : 0
        animatePullUp(action: .remove, duration: duration, animations: { [weak self] in
            self?.view.frame = destination
            self?.updateBackgroundCardProgress(to: 0)
        }, completion: { [weak self] finished in
            guard let self else {
                completion?(false)
                return
            }
            self.resetBackgroundCardEffect()
            self.host?.onResize = nil
            self.host?.onWindowChange = nil
            self.view.removeFromSuperview()
            self.host?.removeFromSuperview()
            self.host = nil
            self.removeFromParent()
            self.isRemoving = false
            completion?(finished)
        })
    }

    /// Moves the sheet to a bounded position in bottom layout.
    /// - Parameters:
    ///   - visibleHeight: Requested height in points above the bottom inset. It
    ///     need not be a snap point, but is limited to the snap range.
    ///   - animated: Whether to animate the movement.
    ///   - completion: Receives the animation result, or `false` when the sheet
    ///     is detached, being removed, in side layout, or the height is invalid.
    @objc(moveToVisibleHeight:animated:completion:)
    public func move(to visibleHeight: CGFloat, animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
        guard host != nil, !isRemoving, !usesSideLayout, visibleHeight.isFinite else {
            completion?(false)
            return
        }
        let duration = animated ? validDuration(configuration.movementDuration) : 0
        moveSheet(to: physics.clamp(visibleHeight), duration: duration, completion: completion)
    }

    /// Updates the sheet after a preferred size, side frame, or snap point changes.
    /// Does nothing when the sheet is detached or being removed.
    /// - Parameter animated: Whether to animate the resulting layout change.
    @objc(updatePreferredFrameAnimated:)
    public func updatePreferredFrame(animated: Bool = false) {
        guard host != nil, !isRemoving else { return }
        visibleHeight = physics.clamp(visibleHeight)
        updatePanAvailability()
        animatePullUp(action: .move, duration: animated ? validDuration(configuration.movementDuration) : 0,
                      animations: { [weak self] in self?.refreshLayout() }, completion: nil)
    }

    /// Coordinates an attached scroll view's pan gesture with the sheet. Attaching
    /// another scroll view first detaches the existing one.
    /// - Parameter scrollView: The scroll view whose pan may move the sheet.
    @objc(attachScrollView:)
    public func attach(scrollView: UIScrollView) {
        guard self.scrollView !== scrollView else { return }
        detachScrollView()
        self.scrollView = scrollView
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleScrollPan(_:)))
    }

    /// Stops coordinating with the attached scroll view and restores its bounce
    /// setting. An in-progress sheet drag is settled when appropriate.
    @objc
    public func detachScrollView() {
        restoreScrollBounce()
        scrollView?.panGestureRecognizer.removeTarget(self, action: #selector(handleScrollPan(_:)))
        scrollView = nil
        if scrollMovedSheet, host != nil, !isRemoving, !usesSideLayout { settle(velocity: 0) }
        scrollMovedSheet = false
    }

    /// Moves the sheet's pan gesture to a designated handle view.
    /// - Parameter handle: The sheet root or one of its descendants. Pass `nil`
    ///   to restore the default handle and the gesture on the root view.
    /// - Returns: `true` when the gesture is attached; otherwise `false` and the
    ///   existing attachment remains unchanged.
    @discardableResult
    @objc(setDragHandleView:)
    public func setDragHandleView(_ handle: UIView?) -> Bool {
        loadViewIfNeeded()
        guard let recognizer = sheetPan, let root = view else { return false }
        let destination = handle ?? root
        guard destination === root || destination.isDescendant(of: root) else { return false }
        destination.addGestureRecognizer(recognizer)
        usesCustomDragHandle = handle != nil
        updateDefaultDragHandle()
        return true
    }
}
