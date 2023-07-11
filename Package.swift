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
                      url: "https://tetra-biz-data-customer.s3.us-west-2.amazonaws.com/tetrart_binaries/apple/TetraRT.xcframework-0.1.1.zip",
                      checksum: "65eaca9bb41d62f57c1ca107808de0bf70be8e86bb7180c252296504d6b5f846")
    ]
)
