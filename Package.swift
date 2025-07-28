// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BrowserSchedule",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.6.0")
    ],
    targets: [
        .target(
            name: "BrowserScheduleCore",
            dependencies: ["TOMLKit"],
            path: "Sources/BrowserScheduleCore"
        ),
        .executableTarget(
            name: "BrowserSchedule",
            dependencies: ["BrowserScheduleCore"],
            path: "Sources/BrowserSchedule"
        ),
        .executableTarget(
            name: "BrowserScheduleCLI", 
            dependencies: ["BrowserScheduleCore", .product(name: "ArgumentParser", package: "swift-argument-parser")],
            path: "Sources/BrowserScheduleCLI"
        ),
        .testTarget(
            name: "BrowserScheduleTests",
            dependencies: ["BrowserScheduleCore", "TOMLKit"],
            path: "Tests/BrowserScheduleTests"
        )
    ]
)