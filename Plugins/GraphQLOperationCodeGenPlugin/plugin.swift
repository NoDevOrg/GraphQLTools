import Foundation

@main
struct GraphQLOperationCodeGenPlugin {
    /// Errors thrown by the `GraphQLSchemaCodeGenPlugin`
    enum PluginError: Error, CustomStringConvertible {
        /// Indicates that the target where the plugin was applied to was not `SourceModuleTarget`.
        case invalidTarget(Target)
        /// Indicates that the file extension of an input file was not `.graphqls`.
        case invalidSchemaFileExtension(String)
        /// Indicates that the file extension of an input file was not `.graphql`.
        case invalidOperationFileExtension(String)
        /// Indicated that an invalid file visibility was provided
        case invalidVisibility(String)
        /// Indicates that there was no configuration file at the required location.
        case noConfigFound(String)

        var description: String {
            switch self {
            case let .invalidTarget(target):
                return "Expected a SwiftSourceModuleTarget but got '\(type(of: target))'."
            case let .invalidSchemaFileExtension(path):
                return "The input file '\(path)' does not have a '.graphqls' extension."
            case let .invalidOperationFileExtension(path):
                return "The input file '\(path)' does not have a '.graphql' extension."
            case let .invalidVisibility(visibility):
                return "Invalid visibility provided: \(visibility)"
            case let .noConfigFound(path):
                return """
                    No configuration file found named '\(path)'. The file must not be listed in the \
                    'exclude:' argument for the target in Package.swift.
                    """
            }
        }
    }

    /// The configuration of the plugin.
    struct Configuration: Codable {
        /// Encapsulates a single invocation of GraphQLSchemaCodeGenCLI.
        struct Invocation: Codable {
            /// Namespace to use in generated code
            var namespace: String?

            /// Map generated types to custom types
            var typeMapping: [String: String]?

            /// An array of paths to `.graphqls` files for this invocation.
            var schemaFiles: [String]
            
            /// A path to where all operations are located for this invocation.
            var operationsPath: String

            /// Visibility for generated code
            var visibility: String?
        }

        /// A list of invocations of `GraphQLSchemaCodeGenPlugin` with the `GraphQLSchemaCodeGenCLI`.
        var invocations: [Invocation]
    }

    static let configurationFileName = "graphql-operation-codegen-config.json"

    func createBuildCommands(pluginWorkDirectory: PackagePlugin.Path, sourceFiles: FileList, tool: (String) throws -> PackagePlugin.PluginContext.Tool) throws -> [Command] {
        guard
            let configurationFilePath = sourceFiles.first(where: {
                $0.path.lastComponent == Self.configurationFileName
            })?.path
        else {
            throw PluginError.noConfigFound(Self.configurationFileName)
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: "\(configurationFilePath)"))
        let configuration = try JSONDecoder().decode(Configuration.self, from: data)

        try self.validateConfiguration(configuration)

        let inputsDirectory = configurationFilePath.removingLastComponent()
        let cli = try tool("graphql-operation-code-gen-cli").path

        return try configuration.invocations.map { invocation in
            try invokeCLI(invocation: invocation, cliPath: cli, inputDirectory: inputsDirectory, outputDirectory: pluginWorkDirectory)
        }
    }

    private func invokeCLI(
        invocation: Configuration.Invocation, cliPath: Path, inputDirectory: Path, outputDirectory: Path
    ) throws -> Command {
        var inputFiles: [Path] = []
        var outputFiles: [Path] = []
        var args: [String] = []

        inputFiles.append(cliPath)
        
        if let namespace = invocation.namespace {
            args.append("--namespace=\(namespace)")
            let outputPath = outputDirectory.appending("\(namespace)Operations.swift")
            outputFiles.append(outputPath)
            args.append("--output-path=\(outputPath.description)")
        } else {
            let outputPath = outputDirectory.appending("GeneratedOperations.swift")
            outputFiles.append(outputPath)
            args.append("--output-path=\(outputPath.description)")
        }

        if let typeMapping = invocation.typeMapping {
            for (key, value) in typeMapping {
                args.append("--type-mapping=\(key):\(value)")
            }
        }

        if let visibility = invocation.visibility {
            args.append("--visibility=\(visibility)")
        }

        for schemaFile in invocation.schemaFiles {
            let schemaFilePath = inputDirectory.appending(schemaFile)
            args.append("--schema-path=\(schemaFilePath.description)")
            inputFiles.append(schemaFilePath)
        }

        let operationsDirectoryContents = try FileManager.default.contentsOfDirectory(atPath: inputDirectory.appending(invocation.operationsPath).string)
            .filter { $0.hasSuffix("graphql") }

        for operation in operationsDirectoryContents {
            let operationFilePath = inputDirectory.appending([invocation.operationsPath, operation])
            args.append("--operation-path=\(operationFilePath.description)")
            inputFiles.append(operationFilePath)
        }

        return Command.buildCommand(
            displayName: "Generating GraphQL Operations",
            executable: cliPath,
            arguments: args,
            inputFiles: inputFiles,
            outputFiles: outputFiles
        )
    }

    /// Validates the configuration file for various user errors.
    private func validateConfiguration(_ configuration: Configuration) throws {
        for invocation in configuration.invocations {
            if let visibility = invocation.visibility {
                if !["public", "package", "internal"].contains(visibility) {
                    throw PluginError.invalidVisibility(visibility)
                }
            }
            for schemaFile in invocation.schemaFiles {
                if !schemaFile.hasSuffix(".graphqls") {
                    throw PluginError.invalidSchemaFileExtension(schemaFile)
                }
            }
        }
    }
}

#if canImport(PackagePlugin)
import PackagePlugin

extension GraphQLOperationCodeGenPlugin: BuildToolPlugin {
    func createBuildCommands(context: PluginContext, target: any Target) async throws -> [Command] {
        guard let swiftTarget = target as? SwiftSourceModuleTarget else {
            throw PluginError.invalidTarget(target)
        }
        return try self.createBuildCommands(
            pluginWorkDirectory: context.pluginWorkDirectory,
            sourceFiles: swiftTarget.sourceFiles,
            tool: context.tool
        )
    }
}
#endif

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension GraphQLOperationCodeGenPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        return try self.createBuildCommands(
            pluginWorkDirectory: context.pluginWorkDirectory,
            sourceFiles: target.inputFiles,
            tool: context.tool
        )
    }
}
#endif
