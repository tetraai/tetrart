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
                      url: "https://tetra-release.s3.us-west-2.amazonaws.com/TetraRT/apple/TetraRT.xcframework-0.5.0.zip",
                      checksum: "12031f5649553c8965654104fa9d577ebb80781281ae649dea27a71f7c20c530"),

        .executableTarget(name: "SmokeTest", dependencies: [.byName(name: "TetraRT")])
    ],
    cxxLanguageStandard: .cxx17
)
