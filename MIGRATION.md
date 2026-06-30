# Migrating to Bartinter 1.0

1.0 is a clean rewrite. It is SPM-only (iOS 15+), removes all method swizzling, and
decides strictly between `.lightContent` and `.darkContent` (fixing Dark Mode).

## Install

Add the package in Xcode: **File → Add Package Dependencies →**
`https://github.com/MaximKotliar/Bartinter`

CocoaPods and Carthage are no longer supported.

## API changes

| 0.0.x | 1.0 |
| --- | --- |
| `vc.updatesStatusBarAppearanceAutomatically = true` | `Bartinter.install(in: windowScene)` (app-wide) |
| swizzled `childForStatusBarStyle` | `override var childForStatusBarStyle: UIViewController? { bartinter }` (explicit) |
| `statusBarUpdater?.refreshStatusBarStyle()` | `bartinter.setNeedsStatusBarTintUpdate()` |
| (none) | SwiftUI: `ContentView().tintsStatusBar()` |
| `Bartinter.isSwizzlingEnabled = false` | removed — no swizzling at all |

## Behavior change

The old library toggled between `.default` and `.lightContent`, which broke under Dark Mode
because `.default` adapts to the system appearance.

1.0 decides strictly between `.lightContent` (use over dark content) and `.darkContent`
(use over light content), so both appearances are handled correctly.

## Per-screen UIKit pattern

If you need per-screen control instead of the app-wide install:

```swift
final class MyViewController: UIViewController {
    private let bartinter = BartinterController()

    override var childForStatusBarStyle: UIViewController? { bartinter }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(bartinter)
        bartinter.didMove(toParent: self)
        bartinter.tint(self)
        // Optional: re-sample when a scroll view scrolls
        bartinter.observe(tableView)
    }
}
```

## Container view controllers

If your root is a `UINavigationController` or other container, forward the status-bar
query to the top child:

```swift
final class TintingNavigationController: UINavigationController {
    override var childForStatusBarStyle: UIViewController? { topViewController }
}
```
