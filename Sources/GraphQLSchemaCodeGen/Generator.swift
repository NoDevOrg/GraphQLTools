import Foundation
import GraphQL
import SwiftProtobufPluginLibrary

struct GeneratorError: Error {
    let description: String
}

/// Options passed in from the CLI
public struct GeneratorOptions {
    let namespace: String
    let additionalImports: [String]
    let typeMapping: [String: String]
    let generateDefaultImplementation: Bool

    public init(namespace: String = "Generated", additionalImports: [String] = [], typeMapping: [String: String] = [:], generateDefaultImplementation: Bool = true) {
        self.namespace = namespace
        self.additionalImports = additionalImports
        self.typeMapping = typeMapping
        self.generateDefaultImplementation = generateDefaultImplementation
    }
}

public class Generator {
    let wellKnownTypes: [String: String]
    let schemas: [String]
    let options: GeneratorOptions
    let data: GeneratorData
    private var printer: CodePrinter

    public init(options: GeneratorOptions = GeneratorOptions(), schemas: [String] = []) throws {
        self.wellKnownTypes = [
            "Int": "Int",
            "Float": "Float",
            "String": "String",
            "Boolean": "Bool"
        ]
        self.schemas = schemas
        self.options = options
        self.data = try GeneratorData(options: options, schemas: schemas)
        self.printer = CodePrinter()
    }

    public var code: String { printer.content }
}

// MARK: - Printer Helpers
extension Generator {
    func println(_ text: String = "", newLine: Bool = true) {
        self.printer.print(text)
        
        if newLine {
            self.printer.print("\n")
        }
    }

    func comment(_ text: String) {
        println("// \(text)")
    }

    func mark(_ text: String) {
        comment("MARK: - \(text)")
    }

    func indent() {
        self.printer.indent()
    }

    func outdent() {
        self.printer.outdent()
    }

    func withIndentation(body: () throws -> Void) rethrows {
        self.indent()
        try body()
        self.outdent()
    }

    enum Scope {
        case none
        case curly

        var open: String {
            return switch self {
            case .none: ""
            case .curly: "{"
            }
        }

        var close: String {
            return switch self {
            case .none: ""
            case .curly: "}"
            }
        }
    }

    func scoped(_ header: String, scope: Scope, _ body: () throws -> Void) rethrows {
        self.println(header + "\(scope == .curly ? " " : "")" + scope.open)
        try self.withIndentation(body: body)
        self.println(scope.close)
    }

    func looped<T>(_ objects: [T], _ body: (T) throws -> Void) rethrows {
        for (index, object) in objects.enumerated() {
            try body(object)
            if index != (objects.count - 1) {
                println()
            }
        }
    }
}
