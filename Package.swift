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
                      checksum: "dffa329feae37828f1695b69dcd535ca4ca198f687ab96a46bba56e0425f6829"),

        .executableTarget(name: "SmokeTest", dependencies: [.byName(name: "TetraRT")])
    ],
    cxxLanguageStandard: .cxx17
)
