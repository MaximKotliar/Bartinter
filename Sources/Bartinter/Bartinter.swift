import Foundation
import UIKit

/// Bartinter namespace. Expanded in later tasks.
public enum Bartinter {}

extension Bartinter {
    /// Installs app-wide status bar tinting by wrapping the scene's key-window root.
    @MainActor
    public static func install(in scene: UIWindowScene,
                               configuration: Bartinter.Configuration = .default) {
        let window = scene.windows.first(where: \.isKeyWindow) ?? scene.windows.first
        guard let window, let root = window.rootViewController,
              (root is BartinterContainerController) == false else { return }
        window.rootViewController = BartinterContainerController(content: root, configuration: configuration)
    }
}
