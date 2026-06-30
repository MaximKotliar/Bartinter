// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Bartinter",
    platforms: [.iOS(.v15)],
    products: [
        .library(name: "Bartinter", targets: ["Bartinter"])
    ],
    targets: [
        .target(name: "Bartinter"),
        .testTarget(name: "BartinterTests", dependencies: ["Bartinter"])
    ]
)
