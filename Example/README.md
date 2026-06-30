# BartinterExample

A minimal SwiftUI demo that exercises `.tintsStatusBar()` by cycling through six grey
shades, causing the status bar to flip between light and dark content styles.

The source files (`BartinterExampleApp.swift`, `ContentView.swift`) are already in this
directory. You need to create the Xcode project in the GUI — a `.pbxproj` cannot be
reliably hand-written and is therefore not committed here.

## Creating the project in Xcode (one-time setup)

1. **New project** — Xcode → File → New → Project → **iOS App**
   - Product Name: `BartinterExample`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Save into the `Example/` folder (so the project lives at
     `Example/BartinterExample.xcodeproj`).

2. **Replace the generated sources** — Xcode scaffolds its own `BartinterExampleApp.swift`
   and `ContentView.swift`. Delete them and use the files already in this directory
   (or let Xcode overwrite during creation and then replace with these files).

3. **Add the local Bartinter package**
   - In the Project navigator select the project → **Package Dependencies** tab → **+**
   - Choose **Add Local…** and navigate to the **repo root** (the folder that contains
     `Package.swift`, one level above `Example/`).
   - Add the **Bartinter** library to the **BartinterExample** target.

4. **Deployment target** — set to **iOS 15.0** (or higher).

5. **Info.plist** — confirm `UIViewControllerBasedStatusBarAppearance` is `YES`.
   Xcode-generated projects default to `YES`; verify in the target's Info tab.

6. **Build and run** on an iOS 15+ simulator or device. Tap **Next** to cycle through
   the grey shades; the status bar icons should flip between dark and light.

## Optional: add the smoke UI test

1. File → New → Target → **UI Testing Bundle**, name it `BartinterExampleUITests`.
2. Create `BartinterExampleUITests/SmokeUITest.swift`:

```swift
import XCTest

final class SmokeUITest: XCTestCase {
    func testTogglingBackgroundDoesNotCrash() {
        let app = XCUIApplication()
        app.launch()
        let next = app.buttons["nextButton"]
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        for _ in 0..<6 { next.tap() }
        XCTAssertTrue(next.exists)
    }
}
```

3. Run from Xcode (Product → Test) or from the command line:

```bash
xcodebuild test \
  -project Example/BartinterExample.xcodeproj \
  -scheme BartinterExample \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -quiet
```

Expected result: `** TEST SUCCEEDED **`

## What this demo does NOT commit

- `BartinterExample.xcodeproj` — created locally in Xcode; not version-controlled here
  because a hand-written `.pbxproj` is fragile and Xcode regenerates GUIDs on every open.
- Derived data, build products.
