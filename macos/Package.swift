// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "TexterifyRenamer",
    platforms: [.macOS("27.0")],
    products: [
        .library(name: "RenamerCore", targets: ["RenamerCore"]),
        .executable(name: "TexterifyRenamer", targets: ["TexterifyRenamer"])
    ],
    dependencies: [
        .package(url: "https://github.com/weichsel/ZIPFoundation.git", exact: "0.9.20"),
        .package(url: "https://github.com/sparkle-project/Sparkle", exact: "2.10.0")
    ],
    targets: [
        .target(name: "RenamerCore", dependencies: ["ZIPFoundation"], resources: [.process("Resources")]),
        .executableTarget(name: "TexterifyRenamer", dependencies: ["RenamerCore", "Sparkle"],
                          linkerSettings: [.unsafeFlags(["-Xlinker", "-rpath", "-Xlinker", "@executable_path/../Frameworks"])]),
        .testTarget(name: "RenamerCoreTests", dependencies: ["RenamerCore", "ZIPFoundation"])
    ]
)
