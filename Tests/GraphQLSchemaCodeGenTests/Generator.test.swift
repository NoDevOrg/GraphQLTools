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
            schemas: [
                topicsSchema,
                federationSchema
            ]
        )

        XCTAssertNoDifference(generator.code, expected)
    }
}

struct BundleError: Error {
    let description: String
}

extension Bundle {
    func contents(forResource: String, withExtension: String) throws -> String {
        guard let url = url(forResource: forResource, withExtension: withExtension, subdirectory: "Mocks") else {
            throw BundleError(description: "Could not find url for \(forResource).\(withExtension)")
        }

        let data = try Data(contentsOf: url)

        guard let string = String(data: data, encoding: .utf8) else {
            throw BundleError(description: "Could not read data as utf8 string")
        }

        return string
    }
}
