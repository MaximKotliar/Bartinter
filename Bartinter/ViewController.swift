//
//  ViewController.swift
//  Bartinter
//
//  Created by Maxim Kotliar on 6/19/18.
//  Copyright © 2018 Maxim Kotliar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    let colors = [#colorLiteral(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0), #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1), #colorLiteral(red: 0.6000000238, green: 0.6000000238, blue: 0.6000000238, alpha: 1), #colorLiteral(red: 0.501960814, green: 0.501960814, blue: 0.501960814, alpha: 1), #colorLiteral(red: 0.2549019754, green: 0.2745098174, blue: 0.3019607961, alpha: 1), #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1)]

    @IBOutlet private var label: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = colors.first
    }

    private func updateLabel() {
        switch childViewControllerForStatusBarStyle!.preferredStatusBarStyle {
        case .default:
            label.text = "dark"
        case .lightContent:
            label.text = "light"
        case .blackOpaque:
            label.text = "dark"
        }
    }

    @IBAction func nextColor() {
        guard let currentColor = view.backgroundColor else { return }
        let color: UIColor?
        if currentColor == colors.last {
            color = colors.first
        } else {
            guard let colorIndex = colors.index(of: currentColor) else { return }
            color = colors[colorIndex + 1]
        }
        view.backgroundColor = color
        statusBarUpdater?.refreshStatusBarStyle()
    }

    override func setNeedsStatusBarAppearanceUpdate() {
        super.setNeedsStatusBarAppearanceUpdate()
        loadViewIfNeeded()
        updateLabel()
    }
}

