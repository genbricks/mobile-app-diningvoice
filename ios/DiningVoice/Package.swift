// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "DiningVoice",
    platforms: [
        .iOS(.v17),
    ],
    products: [
        .library(
            name: "DiningVoice",
            targets: ["DiningVoice"]
        ),
    ],
    targets: [
        .target(
            name: "DiningVoice",
            path: "DiningVoice"
        ),
    ]
)
