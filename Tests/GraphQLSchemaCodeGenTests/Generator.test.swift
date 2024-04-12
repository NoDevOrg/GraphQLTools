import XCTest
import CustomDump
import GraphQL
@testable import GraphQLSchemaCodeGen

final class GeneratorTests: XCTestCase {
    func testGenerator() throws {
        let topicsSchema = try Bundle.module.contents(forResource: "Chat", withExtension: "graphqls")
        let federationSchema = try Bundle.module.contents(forResource: "Federation", withExtension: "graphqls")
        let expected = try Bundle.module.contents(forResource: "ChatSchema.swift", withExtension: "generated")

        let generator = try Generator(
            namespace: "Chat",
            additionalImports: [
                "Pioneer"
            ],
            typeMapping: [
                "DateTime": "Foundation.Date"
            ],
            schemas: [
                topicsSchema,
                federationSchema
            ]
        )

        XCTAssertNoDifference(generator.code, expected)
    }
}
