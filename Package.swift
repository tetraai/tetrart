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
                      url: "https://tetra-release.s3.us-west-2.amazonaws.com/TetraRT/apple/TetraRT.xcframework-0.3.0.zip",
                      checksum: "1e1be1735b0e0a9c1d09250c829cd95637a789dbe0cc9d3bbd567bc9bc6b95cf"),

        .executableTarget(name: "SmokeTest", dependencies: [.byName(name: "TetraRT")])
    ],
    cxxLanguageStandard: .cxx17
)
