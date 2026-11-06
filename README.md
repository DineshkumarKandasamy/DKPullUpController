# DKPullUpController

A UIKit child controller for a draggable sheet with configurable snap positions and scroll-view coordination.

## Requirements

- iOS 17 or later
- Swift 5.9 or later
- Xcode 15 or later

## Installation

### Add the package in Xcode

These steps apply to both Swift and Objective-C app targets:

1. In Xcode, choose **File > Add Package Dependencies**.
2. Enter the repository URL:

```text
https://github.com/DineshkumarKandasamy/DKPullUpController
```

3. Select the version or branch you want to use.
4. Add the `DKPullUpController` product to your app target. For Objective-C, select the Objective-C app target as well.
5. Wait for Xcode to resolve and link the package.

### Swift Package Manager manifest

For a project managed with a `Package.swift` manifest, add the package to `dependencies` and the product to your app target's dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/DineshkumarKandasamy/DKPullUpController", from: "1.0.0")
],
targets: [
    .target(
        name: "YourTarget",
        dependencies: [.product(name: "DKPullUpController", package: "DKPullUpController")]
    )
]
```

The version requirement needs a matching release tag in the repository. Then:

1. Import the package in a Swift source file:

   ```swift
   import DKPullUpController
   ```
2. Subclass `DKPullUpController` or instantiate it and configure its content.

### Objective-C target

The package implementation is written in Swift, with an Objective-C-compatible controller API. After adding and linking the package product to your Objective-C app target:

1. Ensure **Build Settings > Enable Modules (CLANG_ENABLE_MODULES)** is `Yes`.
2. Import the module in each Objective-C file that uses the controller:

   ```objc
   @import DKPullUpController;
   ```
3. Instantiate `DKPullUpController`, configure its content and sizing, and add it to a parent controller:

   ```objc
   DKPullUpController *sheet = [DKPullUpController new];
   sheet.pullUpContentView = contentView;
   sheet.pullUpPreferredSize = CGSizeMake(360, 600);
   sheet.pullUpIntermediateSnapPoints = @[@300];
   [sheet addToParent:self initialVisibleHeight:140 animated:YES completion:nil];
   ```

Objective-C clients configure the sheet through its exposed properties and methods; the Swift `configuration` struct is not directly available in Objective-C. See [Objective-C usage](#objective-c) for a complete example.

## Usage

Subclass the controller and provide the sheet's content. A default drag handle is shown at the top of the sheet.

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

The default handle is centered at the top of the sheet and does not reserve space for content. Its appearance can be changed before or after presentation:

```swift
sheet.configuration.defaultDragHandleColor = .systemTeal
sheet.configuration.defaultDragHandleWidth = 48
sheet.configuration.defaultDragHandleHeight = 6
sheet.configuration.defaultDragHandleCornerRadius = 3
sheet.configuration.defaultDragHandleTopInset = 10
```

Set `showsDefaultDragHandle` to `false` to hide it. The sheet's own pan gesture starts on its root view. Use `setDragHandleView(_:)` to hide the default handle and restrict the gesture to a custom descendant, or pass `nil` to return to the configured default handle and the root-view gesture. The gesture is available as `pullUpPanGestureRecognizer` after the view loads; keep its delegate and target intact.

## Objective-C

Import the package module and provide the sheet's content view and sizing in Objective-C:

```objc
@import DKPullUpController;

DKPullUpController *sheet = [DKPullUpController new];
UIView *contentView = [[UIView alloc] init];
contentView.backgroundColor = UIColor.secondarySystemBackgroundColor;
sheet.pullUpContentView = contentView;
sheet.pullUpPreferredSize = CGSizeMake(360, 600);
sheet.pullUpIntermediateSnapPoints = @[@300];
sheet.layoutMode = DKPullUpLayoutModeBottom;
sheet.pullUpDefaultDragHandleColor = UIColor.systemTealColor;
[sheet addToParent:self initialVisibleHeight:140 animated:YES completion:nil];
```

`configuration` remains the Swift configuration value. Objective-C code can configure its settings through the controller's matching properties, including `layoutMode`, `horizontalAlignment`, `horizontalOffset`, `bottomInset`, the drag and snapping options, and animation durations. Drag-handle settings use the `pullUpDefaultDragHandle...` property prefix. The preferred side frame is set with `pullUpPreferredLandscapeFrame`; current snap positions are available through `pullUpSnapPoints`.

The controller's `moveToVisibleHeight:animated:completion:`, `removeAnimated:completion:`, `attachScrollView:`, and `detachScrollView` methods are also available. Objective-C clients configure the controller by composition; customize override hooks in a Swift subclass when behavior beyond the exposed settings is needed.

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
| `showsDefaultDragHandle` | `true` | Show the built-in handle when no custom handle is selected. |
| `defaultDragHandleColor` | `.tertiaryLabel` | Color of the built-in handle. |
| `defaultDragHandleWidth`, `defaultDragHandleHeight` | `40`, `5` | Size of the built-in handle in points. |
| `defaultDragHandleCornerRadius` | `2.5` | Corner radius of the built-in handle in points. |
| `defaultDragHandleTopInset` | `10` | Distance from the sheet's top edge in points. |
| `presentationDuration`, `dismissalDuration`, `movementDuration` | `0.3` | Animation durations in seconds. |
| `minimumSnapDuration`, `maximumSnapDuration` | `0.08`, `0.3` | Duration bounds in seconds for release animations. |
| `usesVelocityForSnapDuration` | `true` | Scale release duration by distance and speed. When false or velocity is zero, use the maximum duration. |
| `scrollTopTolerance` | `0.5` | Allowance in points when determining whether the scroll view is at its adjusted top. |

Side layout uses `preferredLandscapeFrame` and disables dragging. Returning to bottom layout restores the closest snap position when snapping is enabled. In bottom layout, `bounceOffset` controls the additional drag range, and `skipPointVelocity` controls when the release position is projected along the swipe direction.

Override `pullUpWillMove(to:)`, `pullUpDidMove(to:)`, and `pullUpDidDrag(to:)` to observe movement. Override `targetSnapPoint(for:velocity:points:)`, `snapAnimationDuration(from:to:velocity:)`, `shouldReceivePullUpTouch(_:)`, or `shouldDragPullUp(from:translation:)` to customize gesture behavior. Override `animatePullUp(action:duration:animations:completion:)` for custom animations; run the animations and call the supplied completion, including for zero-duration requests.

All controller operations must run on the main actor.

## Example

Open [DKPullUpExample.xcodeproj](Example/DKPullUpExample.xcodeproj) and choose either the `DKPullUpExample` (Swift) or `DKPullUpObjCExample` (Objective-C) scheme. Both targets reference this package locally. A physical device requires a signing team configured in Xcode.

## License

Distributed under the [MIT license](LICENSE).
