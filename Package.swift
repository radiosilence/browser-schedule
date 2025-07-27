// swift-tools-version: 5.7
import PackageDescription

let package = Package(
    name: "BrowserSchedule",
    platforms: [.macOS(.v11)],
    dependencies: [
        .package(url: "https://github.com/LebJe/TOMLKit.git", from: "0.6.0")
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
        .testTarget(
            name: "BrowserScheduleTests",
            dependencies: ["BrowserScheduleCore", "TOMLKit"],
            path: "Tests/BrowserScheduleTests"
        )
    ]
)