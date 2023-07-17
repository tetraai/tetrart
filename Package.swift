// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TetraRT",
    platforms: [
        .iOS(.v12),
        .macOS(.v12)
    ],
    products: [
        .library(name: "TetraRT", targets: ["TetraRT"])
    ],
    targets: [
        .binaryTarget(name: "TetraRT",
                      url: "https://tetra-release.s3.us-west-2.amazonaws.com/TetraRT/apple/TetraRT.xcframework-0.2.0.zip",
                      checksum: "1f61fd6200dff5ac570de544807ce434032d1e5042fda227f234b0104d9a6b1b"),

        .executableTarget(name: "SmokeTest", dependencies: [.byName(name: "TetraRT")])
    ],
    cxxLanguageStandard: .cxx17
)
