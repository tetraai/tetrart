// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TetraRT",
    products: [
        .library(name: "TetraRT", targets: ["TetraRT"])
    ],
    targets: [
        .binaryTarget(name: "TetraRT",
                      url: "https://tetra-biz-data-customer.s3.us-west-2.amazonaws.com/tetrart_binaries/apple/TetraRT.xcframework-0.1.0-with-dsyms.zip",
                      checksum: "1f61fd6200dff5ac570de544807ce434032d1e5042fda227f234b0104d9a6b1b")
    ]
)
