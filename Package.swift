// swift-tools-version: 6.1
import PackageDescription

let package = Package(name: "GraphQLTools")

package.platforms = [
    .macOS(.v14)
]

package.dependencies = [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-protobuf", from: "1.26.0"),
    .package(url: "https://github.com/GraphQLSwift/GraphQL", from: "2.9.0"),
    .package(url: "https://github.com/apple/swift-nio.git", from: "2.62.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.3.0"),
]

package.targets = [
    .target(
        name: "GraphQLSchemaCodeGen",
        dependencies: [
            .product(name: "GraphQL", package: "GraphQL"),
            .product(name: "NIO", package: "swift-nio"),
            .product(name: "SwiftProtobufPluginLibrary", package: "swift-protobuf"),
        ]
    ),
    .testTarget(
        name: "GraphQLSchemaCodeGenTests",
        dependencies: [
            .target(name: "GraphQLSchemaCodeGen"),
            .product(name: "CustomDump", package: "swift-custom-dump"),
        ],
        resources: [
            .copy("Mocks")
        ]
    ),
    .executableTarget(
        name: "graphql-schema-code-gen-cli",
        dependencies: [
            .target(name: "GraphQLSchemaCodeGen"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ]
    ),
    .plugin(
        name: "GraphQLSchemaCodeGenPlugin",
        capability: .buildTool(),
        dependencies: [
            .target(name: "graphql-schema-code-gen-cli")
        ]),
]

package.products = [
    .library(name: "GraphQLSchemaCodeGen", targets: ["GraphQLSchemaCodeGen"]),
    .executable(name: "graphql-schema-code-gen-cli", targets: ["graphql-schema-code-gen-cli"]),
    .plugin(name: "GraphQLSchemaCodeGenPlugin", targets: ["GraphQLSchemaCodeGenPlugin"]),
]
