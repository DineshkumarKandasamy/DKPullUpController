//
//  DKPullUpController.swift
//  DKPullUpController
//
//  Created by Dineshkumar Kandasamy on 06/11/26.
//

import UIKit

/// A child controller whose content can be dragged between visible heights.
///
/// Subclass this controller to provide the sheet's content and preferred size,
/// then add it to a parent using ``add(to:initialVisibleHeight:animated:completion:)``.
/// Heights are measured above the configured bottom inset. All operations run
/// on the main actor.
@MainActor
open class DKPullUpController: UIViewController {
    /// The operation being passed to the animation hook.
    public enum Action {
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
    open var preferredPullUpSize: CGSize {
        CGSize(width: parent?.view.bounds.width ?? 320, height: 400)
    }

    /// Preferred frame in the parent's coordinate space for side layout.
    /// The default uses a 16-point inset and a width of at most 360 points.
    /// Call ``updatePreferredFrame(animated:)`` after changing the returned frame.
    open var preferredLandscapeFrame: CGRect {
        let bounds = parent?.view.bounds ?? .zero
        return CGRect(x: 16, y: 16, width: min(360, max(0, bounds.width - 32)), height: max(0, bounds.height - 32))
    }

    /// Additional visible heights in points, excluding the initial and maximum
    /// heights. Values are bounded, sorted, and deduplicated. Defaults to empty.
    /// Call ``updatePreferredFrame(animated:)`` after changing the returned points.
    open var middleSnapPoints: [CGFloat] { [] }
    /// Extra distance in points that a drag may extend beyond the snap range.
    /// Scroll-driven drags use it only when scroll drag bounce is enabled. Defaults to `0`.
    open var bounceOffset: CGFloat { 0 }
    /// Absolute release velocity in points per second above which the default
    /// snap target uses a projected position. Defaults to `700`.
    open var skipPointVelocity: CGFloat { 700 }

    /// Layout, gesture, and animation settings. Changes update the loaded sheet.
    public var configuration = DKPullUpConfiguration() {
        didSet { configurationDidChange() }
    }

    /// Current bottom-layout height in points above the bottom inset. In side
    /// layout, this retains the bottom-layout height rather than the side height.
    public internal(set) var visibleHeight: CGFloat = 0
    /// The sheet's pan gesture after its view loads, or `nil` before then.
    /// Keep its target and delegate intact so sheet dragging continues to work.
    public var pullUpPanGestureRecognizer: UIPanGestureRecognizer? { sheetPan }
    /// Sorted, unique snap positions, including the initial and preferred heights.
    /// Non-finite values are excluded and positions are limited to the preferred height.
    public var snapPoints: [CGFloat] { physics.positions }

    var initialHeight: CGFloat = 0
    var host: SheetHostView?
    var sheetPan: UIPanGestureRecognizer?
    var panDelegate: SheetPanDelegate?
    private let defaultDragHandle = UIView()
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
        defaultDragHandle.isUserInteractionEnabled = false
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
        configurationDidChange()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.bringSubviewToFront(defaultDragHandle)
    }

    func updateDefaultDragHandle() {
        guard isViewLoaded else { return }
        defaultDragHandle.backgroundColor = configuration.defaultDragHandleColor
        defaultDragHandle.layer.cornerRadius = validHandleDimension(configuration.defaultDragHandleCornerRadius)
        defaultDragHandleWidth?.constant = validHandleDimension(configuration.defaultDragHandleWidth)
        defaultDragHandleHeight?.constant = validHandleDimension(configuration.defaultDragHandleHeight)
        defaultDragHandleTop?.constant = validHandleDimension(configuration.defaultDragHandleTopInset)
        defaultDragHandle.isHidden = usesCustomDragHandle || !configuration.showsDefaultDragHandle
    }

    private func validHandleDimension(_ value: CGFloat) -> CGFloat {
        value.isFinite ? max(0, value) : 0
    }

    /// Called before a programmatic or release movement begins.
    /// - Parameter visibleHeight: The destination in points above the bottom inset.
    open func pullUpWillMove(to visibleHeight: CGFloat) { }
    /// Called after a programmatic or release movement finishes successfully.
    /// - Parameter visibleHeight: The destination in points above the bottom inset.
    open func pullUpDidMove(to visibleHeight: CGFloat) { }
    /// Called as a gesture changes the sheet's visible height.
    /// - Parameter visibleHeight: The current height in points above the bottom inset.
    open func pullUpDidDrag(to visibleHeight: CGFloat) { }

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
        let available = SheetPhysics(initial: points.first ?? 0, maximum: points.last ?? 0, intermediate: points)
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
    open func snapAnimationDuration(
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
    open func shouldReceivePullUpTouch(_ touch: UITouch) -> Bool {
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
    open func shouldDragPullUp(from scrollView: UIScrollView, translation: CGFloat) -> Bool {
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
    open func animatePullUp(
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
    public func add(
        to parent: UIViewController, initialVisibleHeight: CGFloat, animated: Bool = true,
        completion: ((Bool) -> Void)? = nil
    ) {
        guard self.parent == nil, host == nil, !isRemoving, initialVisibleHeight.isFinite else {
            completion?(false)
            return
        }
        initialHeight = initialVisibleHeight
        parent.loadViewIfNeeded()
        parent.addChild(self)
        loadViewIfNeeded()
        let container = SheetHostView(frame: parent.view.bounds)
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.onResize = { [weak self] in self?.refreshLayout() }
        host = container
        parent.view.addSubview(container)
        container.addSubview(view)
        visibleHeight = physics.clamp(initialVisibleHeight)
        lastLayoutWasSide = usesSideLayout
        let destination = sheetFrame(in: container.bounds)
        view.frame = animated ? CGRect(x: destination.minX, y: container.bounds.maxY,
                                       width: destination.width, height: destination.height) : destination
        didMove(toParent: parent)
        updatePanAvailability()
        animatePullUp(action: .add, duration: animated ? validDuration(configuration.presentationDuration) : 0,
                      animations: { [weak self] in self?.view.frame = destination }, completion: completion)
    }

    /// Removes the sheet and restores the attached scroll view's bounce setting.
    /// - Parameters:
    ///   - animated: Whether to animate removal.
    ///   - completion: Receives the animation result, or `false` when the sheet
    ///     is not attached or a removal is already in progress.
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
        }, completion: { [weak self] finished in
            guard let self else {
                completion?(false)
                return
            }
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
    public func attach(scrollView: UIScrollView) {
        guard self.scrollView !== scrollView else { return }
        detachScrollView()
        self.scrollView = scrollView
        scrollView.panGestureRecognizer.addTarget(self, action: #selector(handleScrollPan(_:)))
    }

    /// Stops coordinating with the attached scroll view and restores its bounce
    /// setting. An in-progress sheet drag is settled when appropriate.
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
