# DKPullUpController

A UIKit child controller for a draggable sheet with configurable snap positions and scroll-view coordination.

## Requirements

- iOS 17 or later
- Swift 5.9 or later
- Xcode 15 or later

## Installation

Add this package to an Xcode project using **File > Add Package Dependencies**. For a local Swift package, use a path dependency:

```swift
dependencies: [
    .package(path: "../DKPullUpController")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [.product(name: "DKPullUpController", package: "DKPullUpController")]
    )
]
```

The path and package identifier must match the package's location in your project. After publishing, use your repository URL and an appropriate version instead.

## Usage

Subclass the controller and provide the sheet's content. The controller does not create its own handle or content views.

```swift
import DKPullUpController
import UIKit

final class DetailsSheet: DKPullUpController {
    override var preferredPullUpSize: CGSize {
        CGSize(width: 360, height: 600)
    }

    override var middleSnapPoints: [CGFloat] { [300] }
}

let sheet = DetailsSheet()
sheet.configuration.layoutMode = .bottom
sheet.add(to: self, initialVisibleHeight: 140)
```

Visible heights are measured above the configured bottom inset. The initial height, middle points, and preferred height are sorted, deduplicated, and limited to the sheet's height. Safe-area insets are not applied automatically.

Call `move(to:animated:completion:)` to move the sheet, `updatePreferredFrame(animated:)` after changing overridden dimensions, and `remove(animated:completion:)` to remove it. Attach a content view with `attach(scrollView:)`; call `detachScrollView()` when coordination is no longer needed.

For content shorter than the scroll view, set `alwaysBounceVertical = true` on the scroll view if it should still initiate sheet drags.

The sheet's own pan gesture starts on its root view. Use `setDragHandleView(_:)` to restrict it to a descendant, or pass `nil` to restore it to the root view. The gesture is available as `pullUpPanGestureRecognizer` after the view loads; keep its delegate and target intact.

## Configuration

Set `configuration` before or after adding the sheet. Changes update its layout and interaction settings.

| Setting | Default | Description |
| --- | --- | --- |
| `layoutMode` | `.automatic` | Use bottom layout in portrait-shaped parents and side layout in landscape-shaped parents. `.bottom` and `.side` force either mode. |
| `horizontalAlignment` | `.center` | Align the bottom sheet to the leading edge, center, or trailing edge. |
| `horizontalOffset`, `bottomInset` | `0` | Position the bottom sheet within its parent. |
| `isDraggingEnabled` | `true` | Enable the sheet's own pan gesture. |
| `isScrollDraggingEnabled` | `true` | Allow an attached scroll view to move the sheet. |
| `isSnappingEnabled` | `true` | Settle on a snap position when a drag ends. |
| `allowsScrollDragBounce` | `false` | Allow scroll-driven movement beyond snap positions by `bounceOffset`. |
| `maximumNumberOfTouches` | `1` | Maximum touches accepted by the sheet pan gesture. |
| `presentationDuration`, `dismissalDuration`, `movementDuration` | `0.3` | Animation durations in seconds. |
| `minimumSnapDuration`, `maximumSnapDuration` | `0.08`, `0.3` | Duration bounds in seconds for release animations. |
| `usesVelocityForSnapDuration` | `true` | Scale release duration by distance and speed. When false or velocity is zero, use the maximum duration. |
| `scrollTopTolerance` | `0.5` | Allowance in points when determining whether the scroll view is at its adjusted top. |

Side layout uses `preferredLandscapeFrame` and disables dragging. Returning to bottom layout restores the closest snap position when snapping is enabled. In bottom layout, `bounceOffset` controls the additional drag range, and `skipPointVelocity` controls when the release position is projected along the swipe direction.

Override `pullUpWillMove(to:)`, `pullUpDidMove(to:)`, and `pullUpDidDrag(to:)` to observe movement. Override `targetSnapPoint(for:velocity:points:)`, `snapAnimationDuration(from:to:velocity:)`, `shouldReceivePullUpTouch(_:)`, or `shouldDragPullUp(from:translation:)` to customize gesture behavior. Override `animatePullUp(action:duration:animations:completion:)` for custom animations; run the animations and call the supplied completion, including for zero-duration requests.

All controller operations must run on the main actor.

## Example

Open [DKPullUpExample.xcodeproj](Example/DKPullUpExample.xcodeproj) and run the `DKPullUpExample` scheme. The project references this package locally. A physical device requires a signing team configured in Xcode.

## License

Distributed under the [MIT license](LICENSE).