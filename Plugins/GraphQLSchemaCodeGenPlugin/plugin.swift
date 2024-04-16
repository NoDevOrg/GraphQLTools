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

            /// An array of paths to `.graphqls` files for this invocation.
            var schemaFiles: [String]
        }

        /// A list of invocations of `GraphQLSchemaCodeGenPlugin` with the `GraphQLSchemaCodeGenCLI`.
        var invocations: [Invocation]
    }

    static let configurationFileName = "graphql-schema-codegen-config.json"

    func createBuildCommands(
        pluginWorkDirectory: PackagePlugin.Path, sourceFiles: FileList,
        tool: (String) throws -> PackagePlugin.PluginContext.Tool
    ) throws -> [Command] {
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

        let inputDirectory = configurationFilePath.removingLastComponent()
        let graphQLSchemaCodeGenCLIPath = try tool("graphql-schema-code-gen-cli").path

        return configuration.invocations.map { invocation in
            invokeCLI(
                invocation: invocation,
                cliPath: graphQLSchemaCodeGenCLIPath,
                inputDirectory: inputDirectory,
                outputDirectory: pluginWorkDirectory
            )
        }
    }

    private func invokeCLI(
        invocation: Configuration.Invocation, cliPath: Path, inputDirectory: Path,
        outputDirectory: Path
    ) -> Command {
        var inputFiles = [Path]()
        var outputFiles = [Path]()
        var args = [String]()

        if let namespace = invocation.namespace {
            args.append("--namespace=\(namespace)")
            outputFiles.append(outputDirectory.appending("\(namespace)Schema.swift"))
            args.append(
                "--output-path=\(outputDirectory.appending("\(namespace)Schema.swift").description)"
            )
        } else {
            outputFiles.append(outputDirectory.appending("GeneratedSchema.swift"))
            args.append(
                "--output-path=\(outputDirectory.appending("GeneratedSchema.swift").description)")
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

        for schemaFile in invocation.schemaFiles {
            args.append("--schema-path=\(inputDirectory.appending(schemaFile).description)")
            inputFiles.append(inputDirectory.appending(schemaFile))
        }

        return Command.buildCommand(
            displayName: "Generating GraphQL Schema",
            executable: cliPath,
            arguments: args,
            inputFiles: inputFiles + [cliPath],
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
    import PackagePlugin

    extension GraphQLSchemaCodeGenPlugin: BuildToolPlugin {
        func createBuildCommands(context: PluginContext, target: any Target) async throws
            -> [Command]
        {
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

    extension GraphQLSchemaCodeGenPlugin: XcodeBuildToolPlugin {
        func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws
            -> [Command]
        {
            return try self.createBuildCommands(
                pluginWorkDirectory: context.pluginWorkDirectory,
                sourceFiles: target.inputFiles,
                tool: context.tool
            )
        }
    }
#endif
