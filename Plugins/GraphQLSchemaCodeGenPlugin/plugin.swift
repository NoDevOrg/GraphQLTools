import Foundation

@main
struct GraphQLSchemaCodeGenPlugin {
    /// Errors thrown by the `GraphQLSchemaCodeGenPlugin`
    enum PluginError: Error, CustomStringConvertible {
        /// Indicates that the target where the plugin was applied to was not `SourceModuleTarget`.
        case invalidTarget(Target)
        /// Indicates that the file extension of an input file was not `.graphqls`.
        case invalidInputFileExtension(String)
        /// Indicates that there was no configuration file at the required location.
        case noConfigFound(String)

        var description: String {
            switch self {
            case let .invalidTarget(target):
                return "Expected a SwiftSourceModuleTarget but got '\(type(of: target))'."
            case let .invalidInputFileExtension(path):
                return "The input file '\(path)' does not have a '.graphqls' extension."
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

            /// Additional modules to import during code generation
            var additionalImports: [String]?

            /// Map generated types to custom types
            var typeMapping: [String: String]?

            /// Custom fields to treat as computed fields
            var computedFields: [String: [String]]?

            /// An array of paths to `.graphqls` files for this invocation.
            var schemaFiles: [String]
        }

        /// A list of invocations of `GraphQLSchemaCodeGenPlugin` with the `GraphQLSchemaCodeGenCLI`.
        var invocations: [Invocation]
    }

    static let configurationFileName = "graphql-schema-codegen-config.json"

    func createBuildCommands(
        pluginWorkDirectory: String, sourceFiles: FileList,
        tool: (String) throws -> PackagePlugin.PluginContext.Tool
    ) throws -> [Command] {
        guard
            let configurationFilePath = sourceFiles.first(where: {
                $0.url.lastPathComponent == Self.configurationFileName
            })?.url.path
        else {
            throw PluginError.noConfigFound(Self.configurationFileName)
        }

        let data = try Data(contentsOf: URL(fileURLWithPath: configurationFilePath))
        let configuration = try JSONDecoder().decode(Configuration.self, from: data)

        try self.validateConfiguration(configuration)

        let inputDirectoryURL = URL(fileURLWithPath: configurationFilePath).deletingLastPathComponent()
        let graphQLSchemaCodeGenCLITool = try tool("graphql-schema-code-gen-cli")

        return configuration.invocations.map { invocation in
            invokeCLI(
                invocation: invocation,
                cliToolURL: graphQLSchemaCodeGenCLITool.url,
                inputDirectoryURL: inputDirectoryURL,
                outputDirectoryURL: URL(fileURLWithPath: pluginWorkDirectory)
            )
        }
    }

    private func invokeCLI(
        invocation: Configuration.Invocation, cliToolURL: URL, inputDirectoryURL: URL,
        outputDirectoryURL: URL
    ) -> Command {
        var inputFiles = [URL]()
        var outputFiles = [URL]()
        var args = [String]()

        if let namespace = invocation.namespace {
            args.append("--namespace=\(namespace)")
            let outputFileURL = outputDirectoryURL.appendingPathComponent("\(namespace)Schema.swift")
            outputFiles.append(outputFileURL)
            args.append("--output-path=\(outputFileURL.path)")
        } else {
            let outputFileURL = outputDirectoryURL.appendingPathComponent("GeneratedSchema.swift")
            outputFiles.append(outputFileURL)
            args.append("--output-path=\(outputFileURL.path)")
        }

        if let additionalImports = invocation.additionalImports {
            for additionalImport in additionalImports {
                args.append("--additional-imports=\(additionalImport)")
            }
        }

        if let typeMapping = invocation.typeMapping {
            for (key, value) in typeMapping {
                args.append("--type-mapping=\(key):\(value)")
            }
        }

        if let computedFields = invocation.computedFields {
            for (object, fields) in computedFields {
                for field in fields {
                    args.append("--computed-fields=\(object):\(field)")
                }
            }
        }

        for schemaFile in invocation.schemaFiles {
            let schemaFileURL = inputDirectoryURL.appendingPathComponent(schemaFile)
            args.append("--schema-path=\(schemaFileURL.path)")
            inputFiles.append(schemaFileURL)
        }

        return Command.buildCommand(
            displayName: "Generating GraphQL Schema",
            executable: cliToolURL,
            arguments: args,
            inputFiles: inputFiles + [cliToolURL],
            outputFiles: outputFiles
        )
    }

    /// Validates the configuration file for various user errors.
    private func validateConfiguration(_ configuration: Configuration) throws {
        for invocation in configuration.invocations {
            for schemaFile in invocation.schemaFiles {
                if !schemaFile.hasSuffix(".graphqls") {
                    throw PluginError.invalidInputFileExtension(schemaFile)
                }
            }
        }
    }
}

#if canImport(PackagePlugin)
    @preconcurrency import PackagePlugin

    extension GraphQLSchemaCodeGenPlugin: BuildToolPlugin {
        func createBuildCommands(context: PluginContext, target: any Target) async throws
            -> [Command]
        {
            guard let swiftTarget = target as? SwiftSourceModuleTarget else {
                throw PluginError.invalidTarget(target)
            }
            return try self.createBuildCommands(
                pluginWorkDirectory: context.pluginWorkDirectoryURL.path,
                sourceFiles: swiftTarget.sourceFiles,
                tool: context.tool
            )
        }
    }
#endif

#if canImport(XcodeProjectPlugin)
    @preconcurrency import XcodeProjectPlugin

    extension GraphQLSchemaCodeGenPlugin: XcodeBuildToolPlugin {
        func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws
            -> [Command]
        {
            return try self.createBuildCommands(
                pluginWorkDirectory: context.pluginWorkDirectoryURL.path,
                sourceFiles: target.inputFiles,
                tool: context.tool
            )
        }
    }
#endif
