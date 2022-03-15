// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "MMMTestCase",
    platforms: [
        .iOS(.v11),
        .tvOS(.v10)
    ],
    products: [
        .library(
            name: "MMMTestCase",
            targets: ["MMMTestCase"]
		)
    ],
    dependencies: [
		.package(url: "https://github.com/mediamonks/MMMLoadable", .upToNextMajor(from: "1.6.3")),
		.package(url: "https://github.com/mediamonks/ios-snapshot-test-case", .upToNextMajor(from: "2.2.0"))
    ],
    targets: [
        .target(
            name: "MMMTestCaseObjC",
            dependencies: [
				.product(name: "FBSnapshotTestCase", package: "ios-snapshot-test-case")
            ],
            path: "Sources/MMMTestCaseObjC"
		),
        .target(
            name: "MMMTestCase",
            dependencies: [
				"MMMTestCaseObjC",
				"MMMLoadable"
			],
            path: "Sources/MMMTestCase"
		),
        .testTarget(
            name: "MMMTestCaseTests",
            dependencies: ["MMMTestCase"],
            path: "Tests"
		)
    ]
)

