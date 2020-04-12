// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "PublicSuffixUpdater",
  products: [
    // Products define the executables and libraries produced by a package, and make them visible to other packages.
    .library(name: "SwiftPublicSuffixUpdater", targets: ["PublicSuffixUpdater"]),
    .executable(name: "Updater", targets: ["Updater"]),
  ],
  dependencies: [
    // Dependencies declare other packages that this package depends on.
    .package(url: "https://github.com/YOCKOW/SwiftStringComposition.git", from: "1.1.0"),
    .package(url: "https://github.com/YOCKOW/ySwiftCodeUpdater.git", from: "1.3.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package. A target can define a module or a test suite.
    // Targets can depend on other targets in this package, and on products in packages which this package depends on.
    .target(
      name: "PublicSuffixUpdater",
      dependencies: [
        "SwiftStringComposition",
        "ySwiftCodeUpdater",
      ]
    ),
    .target(
      name: "Updater",
      dependencies: [
        "PublicSuffixUpdater",
        "ySwiftCodeUpdater",
      ]
    ),
    .testTarget(
      name: "PublicSuffixUpdaterTests",
      dependencies: [
        "PublicSuffixUpdater",
      ]
    ),
  ]
)


import Foundation
if ProcessInfo.processInfo.environment["YOCKOW_USE_LOCAL_PACKAGES"] != nil {
  func localPath(with url: String) -> String {
    guard let url = URL(string: url) else { fatalError("Unexpected URL.") }
    let dirName = url.deletingPathExtension().lastPathComponent
    return "../../../\(dirName)"
  }
  package.dependencies = package.dependencies.map { .package(path: localPath(with: $0.url)) }
}
