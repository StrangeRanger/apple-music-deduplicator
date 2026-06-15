import ProjectDescription

let project = Project(
    name: "AppleMusicDeduplicator",
    organizationName: "Hunter",
    targets: [
        .target(
            name: "AppleMusicDeduplicator",
            destinations: .macOS,
            product: .app,
            bundleId: "com.hunter.applemusicdeduplicator",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Apple Music Deduplicator",
                "LSApplicationCategoryType": "public.app-category.music",
                "NSAppleEventsUsageDescription": "Apple Music Deduplicator needs access to Music to read playlists and remove selected playlist entries."
            ]),
            sources: ["Sources/AppleMusicDeduplicator/**"],
            settings: .settings(base: [
                "CODE_SIGN_STYLE": "Automatic",
                "ENABLE_APP_SANDBOX": "NO",
                "MACOSX_DEPLOYMENT_TARGET": "14.0",
                "SWIFT_OBJC_BRIDGING_HEADER": "Sources/AppleMusicDeduplicator/MusicBridge-Bridging-Header.h",
                "SWIFT_STRICT_CONCURRENCY": "minimal",
                "SWIFT_VERSION": "6.0"
            ])
        ),
        .target(
            name: "AppleMusicDeduplicatorTests",
            destinations: .macOS,
            product: .unitTests,
            bundleId: "com.hunter.applemusicdeduplicator.tests",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .default,
            sources: ["Tests/AppleMusicDeduplicatorTests/**"],
            dependencies: [
                .target(name: "AppleMusicDeduplicator")
            ],
            settings: .settings(base: [
                "MACOSX_DEPLOYMENT_TARGET": "14.0",
                "SWIFT_STRICT_CONCURRENCY": "minimal",
                "SWIFT_VERSION": "6.0"
            ])
        )
    ]
)
