import ArgumentParser
import Foundation
import GraphQLSchemaCodeGen

@main
struct Command: AsyncParsableCommand {
    @Option(help: "Namespace to use during code generation")
    var namespace: String = "GraphQL"

    @Option(help: "Additional modules to import during code generation")
    var importModules: String?

    @Argument(
        help: "Output File Path",
        transform: URL.init(fileURLWithPath:)
    )
    var outputPath: URL

    @Argument(
        help: "Path to GraphQL schema files",
        completion: .file(),
        transform: URL.init(fileURLWithPath:)
    )
    var schemaPaths: [URL]

    func run() async throws {
        let schemas = try schemaPaths.map { path in
            guard let file = try FileHandle(forReadingFrom: path).readToEnd() else {
                throw ValidationError("Could not read file at \(path)")
            }

            guard let value = String(data: file, encoding: .utf8) else {
                throw ValidationError("Schema file could not be decoded as utf8")
            }

            return value
        }

        let additionalImports = (importModules ?? "").split(separator: " ").map { String($0) }

        let generator = try Generator(namespace: namespace, additionalImports: additionalImports, schemas: schemas)

        if let data = generator.code.data(using: .utf8) {
            do {
                if !FileManager.default.fileExists(atPath: outputPath.path()) {
                    FileManager.default.createFile(atPath: outputPath.path, contents: data)
                } else {
                    try FileManager.default.removeItem(atPath: outputPath.path())
                    FileManager.default.createFile(atPath: outputPath.path, contents: data)
                }
            } catch {
                throw ValidationError("Could not write file")
            }
        } else {
            throw ValidationError("Could not convert generated code to utf8")
        }
    }
}
