import ArgumentParser
import Foundation
import GraphQLSchemaCodeGen

@main
struct Command: AsyncParsableCommand {
    @Option(help: "Namespace to use during code generation.")
    var namespace: String = "Generated"

    @Option(help: "Additional modules to import during code generation.")
    var additionalImports: [String] = []

    @Option(
        help: "Map generated types to custom types, formatted as `GeneratedTypeName:CustomType`.",
        transform: { argument in
            guard !argument.contains(" ") else {
                throw ValidationError("type mapping contains space")
            }
            let parts = argument.split(separator: ":")
            guard parts.count == 2 else {
                throw ValidationError("type mapping must be expressed as key:value")
            }
            return (String(parts[0]), String(parts[1]))
        }
    )
    var typeMapping: [(String, String)] = []

    @Option(
        help: "Create computed fields for the given object type. Format as `ObjectType:FieldName`.",
        transform: { argument in
            guard !argument.contains(" ") else {
                throw ValidationError("computed field contains space")
            }
            let parts = argument.split(separator: ":")
            guard parts.count == 2 else {
                throw ValidationError("computed field must be expressed as key:value")
            }
            return (String(parts[0]), String(parts[1]))
        }
    )
    var computedFields: [(String, String)] = []

    @Option(
        help:
            "Path to GraphQL schema file. Multiple files can be used but they will be treated as a single schema.",
        completion: .file(),
        transform: URL.init(fileURLWithPath:)
    )
    var schemaPath: [URL]

    @Option(
        help: "Output File Path, if left empty generated code will print to standard out.",
        completion: .file(),
        transform: URL.init(fileURLWithPath:)
    )
    var outputPath: URL?

    func run() async throws {
        let schemas = try schemaPath.map { path in
            guard let file = try FileHandle(forReadingFrom: path).readToEnd() else {
                throw ValidationError("Could not read file at \(path)")
            }

            guard let value = String(data: file, encoding: .utf8) else {
                throw ValidationError("Schema file could not be decoded as utf8")
            }

            return value
        }

        let typeMapping = Dictionary(uniqueKeysWithValues: self.typeMapping)
        var computedFields: [String: [String]] = [:]
        for (objectType, fieldName) in self.computedFields {
            computedFields[objectType, default: []].append(fieldName)
        }

        let generator: Generator
        do {
            generator = try Generator(
                options: GeneratorOptions(
                    namespace: namespace,
                    additionalImports: additionalImports,
                    computedFields: computedFields,
                    typeMapping: typeMapping
                ),
                schemas: schemas
            )
            try generator.generate()
        } catch {
            throw ValidationError("Generator Error - underlying error: \(error)")
        }

        guard let outputPath = outputPath else {
            print(generator.code)
            return
        }

        do {
            try generator.code.write(to: outputPath, atomically: true, encoding: .utf8)
        } catch {
            throw ValidationError("Could not write file to \(outputPath).")
        }
    }
}
