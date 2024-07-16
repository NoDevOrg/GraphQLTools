// swift-tools-version: 5.10
import PackageDescription

let package = Package(name: "Examples")

package.platforms = [
    .macOS(.v13)
]

package.dependencies = [
    .package(name: "GraphQLTools", path: "../"),
    .package(url: "https://github.com/d-exclaimation/pioneer", from: "1.0.0"),
]

package.targets = [
    .executableTarget(
        name: "ChatClient",
        dependencies: [
            .product(name: "Pioneer", package: "pioneer")
        ],
        resources: [
            .copy("GraphQL"),
            .copy("graphql-operation-codegen-config.json"),
        ],
        plugins: [
            .plugin(name: "GraphQLOperationCodeGenPlugin", package: "GraphQLTools")
        ]
    ),
    .executableTarget(
        name: "ChatService",
        dependencies: [
            .product(name: "Pioneer", package: "pioneer")
        ],
        resources: [
            .copy("Schemas"),
            .copy("graphql-schema-codegen-config.json"),
        ],
        plugins: [
            .plugin(name: "GraphQLSchemaCodeGenPlugin", package: "GraphQLTools")
        ]
    ),
    .executableTarget(
        name: "StarWarsAPI",
        dependencies: [
            .product(name: "Pioneer", package: "pioneer")
        ],
        resources: [
            .copy("Schemas"),
            .copy("Database.json"),
            .copy("graphql-schema-codegen-config.json"),
        ],
        plugins: [
            .plugin(name: "GraphQLSchemaCodeGenPlugin", package: "GraphQLTools")
        ]
    ),
    .plugin(
        name: "StarWarsAPIDownload",
        capability: .command(
            intent: .custom(
                verb: "download-swapi",
                description: "Downloads data from swapi.dev to use in StarWarsAPI example"
            ),
            permissions: [
                .writeToPackageDirectory(
                    reason: "Writes a file to act as a data for StarWarsAPI example"
                ),
                .allowNetworkConnections(
                    scope: .all(ports: [443]),
                    reason: "Need to connect to swapi.dev to download data"
                ),
            ]
        )
    ),
]

package.products = [
    .executable(name: "ChatService", targets: ["ChatService"]),
    .executable(name: "StarWarsAPI", targets: ["StarWarsAPI"]),
    .plugin(name: "StarWarsAPIDownload", targets: ["StarWarsAPIDownload"]),
]
