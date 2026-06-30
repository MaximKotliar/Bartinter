import SwiftUI
import UIKit

extension View {
    /// Tints the window's status bar based on the content behind it while this view is shown.
    public func tintsStatusBar(_ configuration: Bartinter.Configuration = .default,
                               isActive: Bool = true) -> some View {
        background(BartinterInstallerView(configuration: configuration, isActive: isActive))
    }
}

private struct BartinterInstallerView: UIViewControllerRepresentable {
    let configuration: Bartinter.Configuration
    let isActive: Bool

    func makeUIViewController(context: Context) -> _BartinterInstaller {
        _BartinterInstaller(configuration: configuration, isActive: isActive)
    }

    func updateUIViewController(_ controller: _BartinterInstaller, context: Context) {
        controller.isActiveTinting = isActive
        controller.installIfPossible()
    }
}

final class _BartinterInstaller: UIViewController {
    private let configuration: Bartinter.Configuration
    var isActiveTinting: Bool

    init(configuration: Bartinter.Configuration, isActive: Bool) {
        self.configuration = configuration
        self.isActiveTinting = isActive
        super.init(nibName: nil, bundle: nil)
        view.isHidden = true
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override func didMove(toParent parent: UIViewController?) {
        super.didMove(toParent: parent)
        installIfPossible()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        installIfPossible()
    }

    func installIfPossible() {
        guard let scene = view.window?.windowScene else { return }
        Bartinter.install(in: scene, configuration: configuration)
    }
}
