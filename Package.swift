// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "BlazeFleet",
    defaultLocalization: "es",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "BlazeFleetKit",
            targets: ["BlazeFleetKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "BlazeFleetKit",
            path: "BlazeFleet"
        ),
    ]
)
