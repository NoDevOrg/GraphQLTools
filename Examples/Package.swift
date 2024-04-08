// swift-tools-version: 5.10
import PackageDescription

let package = Package(name: "Examples")

package.platforms = [
    .macOS(.v13),
]

package.dependencies = [
    .package(name: "GraphQLTools", path: "../"),
    .package(url: "https://github.com/d-exclaimation/pioneer", from: "1.0.0"),
]

package.targets = [
    .executableTarget(
        name: "ChatService",
        dependencies: [
            .product(name: "Pioneer", package: "pioneer"),
        ],
        resources: [
            .copy("Schemas"),
            .copy("graphql-schema-codegen-config.json")
        ],
        plugins: [
            .plugin(name: "GraphQLSchemaCodeGenPlugin", package: "GraphQLTools"),
        ]
    ),
]

package.products = [
    .executable(name: "ChatService", targets: ["ChatService"]),
]
