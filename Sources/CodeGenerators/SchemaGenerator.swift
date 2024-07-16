import Foundation
import GraphQL
import SwiftProtobufPluginLibrary

public class SchemaGenerator: CodeGenerator {
    let schemas: [String]
    let options: Options
    let data: SchemaGeneratorData
    var printer: CodePrinter

    /// Options passed in from the CLI
    public struct Options {
        let namespace: String
        let additionalImports: [String]
        let typeMapping: [String: String]
        let generateDefaultImplementation: Bool

        public init(
            namespace: String = "Generated",
            additionalImports: [String] = [],
            typeMapping: [String: String] = [:],
            generateDefaultImplementation: Bool = true
        ) {
            self.namespace = namespace
            self.additionalImports = additionalImports
            self.typeMapping = typeMapping
            self.generateDefaultImplementation = generateDefaultImplementation
        }
    }

    public init(
        options: Options = Options(),
        schemas: [String] = []
    ) throws {
        self.schemas = schemas
        self.options = options
        self.data = try SchemaGeneratorData(
            options: options,
            schemas: schemas
        )
        self.printer = CodePrinter()
    }

    public var code: String { printer.content }
}
