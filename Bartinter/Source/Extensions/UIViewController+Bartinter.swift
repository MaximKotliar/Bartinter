//
//  UIViewController+Bartinter.swift
//
//  Created by Maxim Kotliar on 6/19/18.
//

import UIKit.UIViewController

private var statusBarUpdaterHandle = "statusBarUpdaterHandle"
public extension UIViewController {

    private(set) var statusBarUpdater: Bartinter? {
        get {
            return objc_getAssociatedObject(self,
                                            &statusBarUpdaterHandle) as? Bartinter
        }

        set {
            // Dispatching to next runloop iteration
            DispatchQueue.main.async {
                self.statusBarUpdater?.detach()
                newValue?.attach(to: self)
            }
            objc_setAssociatedObject(self,
                                     &statusBarUpdaterHandle,
                                     newValue,
                                     .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }

    /// Updates StatusBar Appearance Automatically
    @IBInspectable var updatesStatusBarAppearanceAutomatically: Bool {
        get {
            return statusBarUpdater != nil
        }
        set {
            switch newValue {
            case true:
                statusBarUpdater = Bartinter()
            case false:
                statusBarUpdater = nil
            }
        }
    }
}

private var redrawDelegateHandle = "redrawDelegateHandle"
extension UIView {
    weak var redrawDelegate: UIViewRedrawDelegate? {
        get {
            return objc_getAssociatedObject(self,
                                            &redrawDelegateHandle) as? UIViewRedrawDelegate
        }

        set {
            objc_setAssociatedObject(self,
                                     &redrawDelegateHandle,
                                     newValue,
                                     .OBJC_ASSOCIATION_ASSIGN)
        }
    }
}
