import UIKit

final class BartinterContainerController: UIViewController {
    let content: UIViewController
    let bartinter: BartinterController

    init(content: UIViewController, configuration: Bartinter.Configuration) {
        self.content = content
        self.bartinter = BartinterController(configuration: configuration)
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }

    override var childForStatusBarStyle: UIViewController? { bartinter }

    override func viewDidLoad() {
        super.viewDidLoad()
        addChild(content)
        content.view.frame = view.bounds
        content.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(content.view)
        content.didMove(toParent: self)

        addChild(bartinter)
        bartinter.didMove(toParent: self)
        bartinter.tint(content)
    }
}
