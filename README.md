[![Version](https://img.shields.io/cocoapods/v/Bartinter.svg?style=flat-square)](http://cocoapods.org/pods/Bartinter)
[![License](https://img.shields.io/cocoapods/l/Bartinter.svg?style=flat-square)](http://cocoapods.org/pods/Bartinter)
[![Platform](https://img.shields.io/cocoapods/p/Bartinter.svg?style=flat-square)](http://cocoapods.org/pods/Bartinter)

# Bartinter
Status bar apperance manager that make your status bar readable by dynamically changing it's color depending on content behind.

![alt tag](https://raw.githubusercontent.com/MaximKotliar/Bartinter/master/demo.gif)


## Installation
Add

`pod 'Bartinter'`

to your podfile, and run
`pod install`

## Usage

Set "View controller-based status bar appearance" (UIViewControllerBasedStatusBarAppearance) to YES in your Info.plist. 
Set ViewController's `updatesStatusBarAppearanceAutomatically = true`

That's it.

### Swizzling
By default, bartinter swizzles a couple methods for your convenience. (see: `UIKitSwizzling.swift`)
If you are not ok with method swizzling, you can disable it by following line: 
```swift
Bartinter.isSwizzlingEnabled = false
```
Without swizzling you need to do some things manually: 

Firstly, you need to provide `childViewControllerForStatusBarStyle`, in your ViewController subclass just add following: 
```swift
override var childViewControllerForStatusBarStyle: UIViewController? {
    return statusBarUpdater
}
```

Secondly, you need de decide, when you need to refresh status bar style, for example on tableView scroll, so add: 
```swift
func scrollViewDidScroll(_ scrollView: UIScrollView) {
    statusBarUpdater?.refreshStatusBarStyle()
}
```
