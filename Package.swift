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
                      checksum: "39ad3ec8d97c9d0bf27ffa782219fd8f891a8861d75bb2db34e275d7276e6b1d"),

        .executableTarget(name: "SmokeTest", dependencies: [.byName(name: "TetraRT")])
    ],
    cxxLanguageStandard: .cxx17
)
