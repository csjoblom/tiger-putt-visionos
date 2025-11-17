// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "xr-tiger-putt",
    products: [
        .library(
            name: "xr_tiger_putt",
            targets: ["xr_tiger_putt"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "xr_tiger_putt",
            path: "xr-tiger-putt",
            exclude: [
                "Assets.xcassets",
                "Info.plist",
                "ImmersiveView.swift",
                "ContentView.swift",
                "xr_tiger_puttApp.swift",
                "AppModel.swift",
                "TigerModeOverlaySystem.swift",
                "PuttVisionManager.swift",
                "ToggleImmersiveSpaceButton.swift"
            ],
            sources: [
                "PuttingSessionState.swift",
                "SwiftUICompatibility.swift"
            ]
        ),
        .testTarget(
            name: "xr_tiger_puttTests",
            dependencies: [
                "xr_tiger_putt"
            ],
            path: "xr-tiger-puttTests"
        )
    ]
)
