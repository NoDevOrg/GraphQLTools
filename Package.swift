// swift-tools-version: 5.10
import PackageDescription

let package = Package(name: "GraphQLTools")

package.platforms = [
    .macOS(.v13)
]

package.dependencies = [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.0.0"),
    .package(url: "https://github.com/apple/swift-protobuf", from: "1.0.0"),
    .package(url: "https://github.com/GraphQLSwift/GraphQL", from: "2.0.0"),
    .package(url: "https://github.com/pointfreeco/swift-custom-dump", from: "1.0.0"),
]

package.targets = [
    .target(
        name: "GraphQLSchemaCodeGen",
        dependencies: [
            .product(name: "GraphQL", package: "GraphQL"),
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
