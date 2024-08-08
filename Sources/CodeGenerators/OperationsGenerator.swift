import Foundation
import SwiftProtobufPluginLibrary

public class OperationsGenerator: CodeGenerator {
    let options: Options
    let schemas: [String]
    let operations: [String]
    let data: OperationsGeneratorData
    var printer: CodePrinter

    /// Options passed in from the CLI
    public struct Options {
        let namespace: String
        let typeMapping: [String: String]
        let visibility: String

        public init(
            namespace: String = "Generated",
            typeMapping: [String: String] = [:],
            visibility: String = "package"
        ) {
            self.namespace = namespace
            self.typeMapping = typeMapping
            self.visibility = visibility
        }
    }

    public init(
        options: Options = Options(),
        schemas: [String] = [],
        operations: [String] = []
    ) throws {
        self.options = options
        self.schemas = schemas
        self.operations = operations
        self.data = try OperationsGeneratorData(
            options: options,
            schemas: schemas,
            operations: operations
        )
        self.printer = CodePrinter()
    }

    public var code: String { printer.content }
}
