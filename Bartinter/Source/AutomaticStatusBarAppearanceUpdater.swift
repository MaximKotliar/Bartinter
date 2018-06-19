//
//  Bartinter.swift
//  Yoga
//
//  Created by Maxim Kotliar on 6/15/18.
//  Copyright © 2018 Wikrgroup. All rights reserved.
//

import UIKit
import CoreImage

extension Bartinter {

    struct Configuration {
        static var defaultAnimationDuration: TimeInterval = 0.2
        static var defaultThrottleDelay: TimeInterval = 0.2
        static var defaultAnimationType: UIStatusBarAnimation = .fade
        static var defaultMidPoint: CGFloat = 0.5
        static var defaultAntiFlickRange: CGFloat = 0.1

        var animationDuration = defaultAnimationDuration
        var animationType = defaultAnimationType
        var midPoint = defaultMidPoint
        var antiFlickRange = defaultAntiFlickRange
        var throttleDelay = defaultThrottleDelay
    }
}

final class Bartinter: UIViewController {

    var configuration: Configuration {
        didSet {
            throttler.maxInterval = configuration.throttleDelay
        }
    }
    private lazy var throttler = {
        return Throttler(interval: self.configuration.throttleDelay)
    }()

    init(_ configuration: Configuration = Configuration()) {
        self.configuration = configuration
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func calculateStatusBarAreaAvgLuminance(_ completion: @escaping (CGFloat) -> Void) {
        guard let layer = parent?.view.layer else { return }
        let scale: CGFloat = 0.5
        let size = UIApplication.shared.statusBarFrame.size
        throttler.throttle {
            UIGraphicsBeginImageContextWithOptions(size, false, scale)
            guard let context = UIGraphicsGetCurrentContext() else { return }
            layer.render(in: context)
            let image = UIGraphicsGetImageFromCurrentImageContext()
            guard let averageLuminance = image?.averageLuminance else { return }
            UIGraphicsEndImageContext()
            DispatchQueue.main.async {
                completion(averageLuminance)
            }
        }
    }

    private var statusBarStyle: UIStatusBarStyle = .default {
        didSet {
            guard oldValue != statusBarStyle else { return }
            UIView.animate(withDuration: configuration.animationDuration) {
                self.parent?.setNeedsStatusBarAppearanceUpdate()
            }
        }
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return statusBarStyle
    }

    override var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return configuration.animationType
    }

    @objc func refreshStatusBarStyle() {
        calculateStatusBarAreaAvgLuminance { [weak self] avgLuminance in
            guard let strongSelf = self else { return }
            let antiFlick = strongSelf.configuration.antiFlickRange / 2
            if avgLuminance <= strongSelf.configuration.midPoint - antiFlick {
                strongSelf.statusBarStyle = .lightContent
            } else if avgLuminance >= strongSelf.configuration.midPoint + antiFlick {
                strongSelf.statusBarStyle = .default
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.isHidden = true
        view.frame = .zero
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        parent?.view.layoutIfNeeded()
        parent?.view.redrawDelegate = self
        refreshStatusBarStyle()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        view.subviews.forEach { $0.removeFromSuperview() }
        parent?.view.redrawDelegate = nil
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        refreshStatusBarStyle()
    }

    func attach(to viewController: UIViewController) {
        viewController.addChildViewController(self)
        viewController.view.addSubview(view)
        didMove(toParentViewController: viewController)
    }

    func detach() {
        willMove(toParentViewController: nil)
        view.removeFromSuperview()
        removeFromParentViewController()
    }
}

extension Bartinter: UIViewRedrawDelegate {
    func didLayoutSubviews() {
        refreshStatusBarStyle()
    }
}

private extension UIImage {
    var averageLuminance: CGFloat? {
        guard let inputImage = CIImage(image: self) else { return nil }
        let extentVector = CIVector(x: inputImage.extent.origin.x,
                                    y: inputImage.extent.origin.y,
                                    z: inputImage.extent.size.width,
                                    w: inputImage.extent.size.height)

        guard let filter = CIFilter(name: "CIAreaAverage",
                                    withInputParameters: [kCIInputImageKey: inputImage,
                                                          kCIInputExtentKey: extentVector]) else { return nil }
        guard let outputImage = filter.outputImage else { return nil }

        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: [kCIContextWorkingColorSpace: kCFNull])
        context.render(outputImage,
                       toBitmap: &bitmap,
                       rowBytes: 4,
                       bounds: CGRect(x: 0, y: 0,
                                      width: 1, height: 1),
                       format: kCIFormatRGBA8,
                       colorSpace: nil)

        let r = CGFloat(bitmap[0]) / 255
        let g = CGFloat(bitmap[1]) / 255
        let b = CGFloat(bitmap[2]) / 255
        // Luminance coeficents taken from https://en.wikipedia.org/wiki/Relative_luminance
        let luminance = 0.212 * r + 0.715 * g + 0.073 * b
        return luminance
    }
}
