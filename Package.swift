// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "ist-schon-wieder-dom",
    platforms: [
        // Platform Dependencies for `SwiftCompilerPlugin`
        .macOS(.v10_15),
        .iOS(.v13),
    ],
    dependencies: [
        // Straightforward, type-safe argument parsing for Swift
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.2.0"),
        // A set of Swift libraries for parsing, inspecting, generating, and transforming Swift source code
        .package(url: "https://github.com/apple/swift-syntax.git", from: "510.0.0"),
    ],
    targets: [
        // This is where we'll implement the logic of the macros.
        .target(name: "DateMacros", dependencies: [
            "DateMacrosImplementation",
        ]),
        // This is what the compiler uses to load and execute maros
        .macro(name: "DateMacrosImplementation", dependencies: [
            .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
            .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
        ]),
        // Of course, we want to test our stuff.
        .testTarget(name: "UnitTests", dependencies: [
            "DateMacrosImplementation",
            .product(name: "SwiftSyntaxMacrosTestSupport", package: "swift-syntax"),
        ]),
        .executableTarget(
            name: "ist-schon-wieder-dom",
            dependencies: [
                "DateMacros",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
    ]
)
