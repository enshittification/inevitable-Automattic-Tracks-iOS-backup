// swift-tools-version:5.4
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AutomatticTracksiOS",
    platforms: [.macOS(.v10_14), .iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "AutomatticTracks",
            targets: ["AutomatticTracksEventLogging",
                      "AutomatticRemoteLogging",
                      "AutomatticExperiments",
                      "AutomatticCrashLoggingUI",
                      "AutomatticTracks"
            ]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/CocoaLumberjack/CocoaLumberjack", from: "3.0.0"),
        .package(name: "Sentry", url: "https://github.com/getsentry/sentry-cocoa", from: "6.0.0"),
        .package(name: "Sodium", url: "https://github.com/jedisct1/swift-sodium", from: "0.9.1"),
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.0.0"),
        .package(url: "https://github.com/squarefrog/UIDeviceIdentifier", from: "1.7.0"),
        .package(name: "OCMock", url: "https://github.com/erikdoe/ocmock", .branch("master"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "AutomatticTracksModelObjC",
            dependencies: ["UIDeviceIdentifier", "CocoaLumberjack"],
            path: "Sources/Model/ObjC",
            publicHeadersPath: ".",
            cSettings: [.headerSearchPath("../../Event Logging/private")]),
        
        .target(
            name: "AutomatticTracksModel",
            dependencies: [
                "AutomatticTracksModelObjC",
                "Sentry",
                "CocoaLumberjack"
            ],
            path: "Sources/Model/Swift"),


        .target(
            name: "AutomatticExperiments",
            dependencies: [.product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")],
            path: "Sources/Experiments"
        ),

        .target(
            name: "AutomatticTracksEventLogging",
            dependencies: ["AutomatticTracksModel", "AutomatticExperiments"],
            path: "Sources/Event Logging",
            publicHeadersPath: ".",
            cSettings: [.headerSearchPath("private")]),

        .target(
            name: "AutomatticRemoteLogging",
            dependencies: ["Sentry",
                           .product(name: "Clibsodium", package: "Sodium"),
                           "Sodium",
                           .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack"),
                           "AutomatticTracksModel",
                           "AutomatticTracksEventLogging"],
            path: "Sources/Remote Logging"),



        .target(
            name: "AutomatticCrashLoggingUI",
            dependencies: ["AutomatticRemoteLogging"],
            path: "Sources/UI"),

        .target(
            name: "AutomatticTracks",
            dependencies: [
                "AutomatticExperiments",
                "AutomatticTracksEventLogging",
                "AutomatticRemoteLogging",
                "AutomatticCrashLoggingUI"
            ],
            path: "Sources/AutomatticTracks"
        ),

        .testTarget(
            name: "AutomatticTracksTests",
            dependencies: [
                "AutomatticTracks",
                "AutomatticTracksEventLogging",
                "AutomatticTracksModel",
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
                .product(name: "CocoaLumberjackSwift", package: "CocoaLumberjack")
            ],
            path: "Tests",
            exclude: ["Tests/ObjC"],
            resources: [.process("Mock Data")]),
        
        .testTarget(
            name: "AutomatticTracksTestsObjC",
            dependencies: ["AutomatticTracksEventLogging",
                           "OCMock"
            ],
            path: "Tests/Tests/ObjC"
        )
    ]
)
