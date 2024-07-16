import Foundation
import GraphQL

extension SchemaGenerator {
    public func generate() throws {
        printHeader()
        printImports()
        printNamespace()
        printError()
        printSDL()
        printTypeMapping()
        try printObjectTypes()
        try printObjectResolverDefaultImplementation()
        try printResolverArguments()
        try printResolverProtocol()
        try printResolverProtocolDefaultImplemention()
        try printSchemaBuilder()
    }

    func printHeader() {
        println(
            """
            //
            // DO NOT EDIT.
            // swift-format-ignore-file
            //
            // Generated by GraphQLSchemaCodeGen
            //
            """)
    }

    func printImports() {
        println()
        println(
            """
            import Foundation
            import GraphQL
            import Graphiti
            """)

        for additionalImport in options.additionalImports {
            println("import \(additionalImport)")
        }
    }

    func printNamespace() {
        println()
        println("enum \(data.schemaName) {}")
    }

    func printError() {
        println()
        mark("Error")
        scoped("struct \(data.schemaName)Error: Error", scope: .curly) {
            println("let description: String")
        }
    }

    // TODO: Add support to Graphiti for printing SDL automatically
    func printSDL() {
        let sdl =
            schemas
            .joined(separator: "\n")
            .replacingOccurrences(of: "\"\"\"", with: "\\\"\"\"")

        println()
        mark("SDL")
        scoped("extension \(data.schemaName)", scope: .curly) {
            println("static let sdl: String =")
            println("\"\"\"")
            println(sdl, newLine: false)
            println("\"\"\"")
        }
    }

    func printTypeMapping() {
        guard !options.typeMapping.isEmpty else { return }
        println()
        mark("Type Mapping")
        scoped("extension \(data.schemaName)", scope: .curly) {
            for (key, value) in options.typeMapping.sorted(by: { $0.key < $1.key }) {
                println("typealias \(key) = \(value)")
            }
        }
    }

    func printObjectTypes() throws {
        guard !data.objects.isEmpty || !data.inputs.isEmpty else { return }
        println()
        mark("Types")
        try scoped("extension \(data.schemaName)", scope: .curly) {
            try looped(data.objects) { object in
                let objectInterfaces = object.interfaces.map { $0.name.value } + ["Codable"]
                try scoped(
                    "struct \(object.name.value): \(objectInterfaces.joined(separator: ", "))",
                    scope: .curly
                ) {
                    let basicFields = object.fields.filter { $0.arguments.isEmpty }
                    let computedFields = object.fields.filter { !$0.arguments.isEmpty }

                    for field in basicFields {
                        try println("let \(field.name.value): \(swiftTypeName(field.type))")
                    }

                    if !computedFields.isEmpty {
                        println()

                        try looped(computedFields) { field in
                            try scoped(
                                "struct \(field.name.value.capitalizeFirst)Arguments: Codable",
                                scope: .curly
                            ) {
                                for argument in field.arguments {
                                    try println(
                                        "let \(argument.name.value): \(swiftTypeName(argument.type))"
                                    )
                                }
                            }
                            println()
                            try scoped(
                                "func _\(field.name.value)<ContextType>(context: ContextType, args: \(field.name.value.capitalizeFirst)Arguments) async throws -> \(swiftTypeName(field.type))",
                                scope: .curly
                            ) {
                                scoped(
                                    "guard let resolver = self as? any \(data.schemaName).\(object.name.value).Resolver<ContextType> else",
                                    scope: .curly
                                ) {
                                    printThrowError(
                                        "\(object.name.value).\(field.name.value) is unimplemented")
                                }
                                println()
                                println(
                                    "return try await resolver.\(field.name.value)(context: context, args: args)"
                                )
                            }
                        }

                        println()

                        try scoped("protocol Resolver<ContextType>", scope: .curly) {
                            println("associatedtype ContextType")
                            println()
                            for field in computedFields {
                                try println(
                                    "func \(field.name.value)(context: ContextType, args: \(field.name.value.capitalizeFirst)Arguments) async throws -> \(swiftTypeName(field.type))"
                                )
                            }
                        }
                    }

                    if try !object.federationKeys().isEmpty { println() }
                    try looped(object.federationKeys()) { key in
                        try scoped("struct \(key.name): Codable", scope: .curly) {
                            for field in key.fields {
                                let objectField = try object.field(named: field)
                                try println(
                                    "let \(objectField.name.value): \(swiftTypeName(objectField.type))"
                                )
                            }
                        }
                    }
                }
            }
            if !data.inputs.isEmpty {
                println()
                try looped(data.inputs) { object in
                    try scoped("struct \(object.name.value): Codable", scope: .curly) {
                        for field in object.fields {
                            try println("let \(field.name.value): \(swiftTypeName(field.type))")
                        }
                    }
                }
            }
            if !data.enums.isEmpty {
                println()
                looped(data.enums) { object in
                    scoped("enum \(object.name.value): String, Codable", scope: .curly) {
                        for value in object.values {
                            println(
                                "case \(value.name.value.lowercased()) = \"\(value.name.value)\"")
                        }
                    }
                }
            }
            if !data.interfaces.isEmpty {
                println()
                try looped(data.interfaces) { interface in
                    try scoped("protocol \(interface.name.value)", scope: .curly) {
                        for field in interface.fields {
                            try println(
                                "var \(field.name.value): \(swiftTypeName(field.type)) { get }")
                        }
                    }
                }
            }
        }
    }

    func printObjectResolverDefaultImplementation() throws {
        guard options.generateDefaultImplementation else { return }
        for object in data.objects {
            let computedFields = object.fields.filter { !$0.arguments.isEmpty }
            guard !computedFields.isEmpty else { continue }
            println()
            try scoped("extension \(data.schemaName).\(object.name.value).Resolver", scope: .curly) {
                try looped(computedFields) { field in
                    try scoped(
                        "func \(field.name.value)(context: ContextType, args: \(data.schemaName).\(object.name.value).\(field.name.value.capitalizeFirst)Arguments) async throws -> \(swiftTypeName(field.type, namespace: data.schemaName))",
                        scope: .curly
                    ) {
                        printThrowError(
                            "\(object.name.value).\(field.name.value) is unimplemented.")
                    }
                }
            }
        }
    }

    func printResolverArguments() throws {
        println()
        mark("Resolver Arguments")
        try scoped("extension \(data.schemaName)", scope: .curly) {
            try looped(data.queryFields + data.mutationFields + data.subscriptionFields) { field in
                try scoped(
                    "struct \(field.name.value.capitalizeFirst)Arguments: Codable", scope: .curly
                ) {
                    for argument in field.arguments {
                        try println("let \(argument.name.value): \(swiftTypeName(argument.type))")
                    }
                }
            }
        }
    }

    func printResolverProtocol() throws {
        println()
        mark("Resolver Protocol")
        try scoped("extension \(data.schemaName)", scope: .curly) {
            try scoped("protocol \(data.resolverName)", scope: .curly) {
                println("associatedtype ContextType")
                println()
                for field in (data.queryFields + data.mutationFields) {
                    try println(
                        "func \(field.name.value)(context: ContextType, args: \(field.name.value.capitalizeFirst)Arguments) async throws -> \(swiftTypeName(field.type))"
                    )
                }
                for field in data.subscriptionFields {
                    try println(
                        "func \(field.name.value)(context: ContextType, args: \(field.name.value.capitalizeFirst)Arguments) async throws -> EventStream<\(swiftTypeName(field.type))>"
                    )
                }
                for (object, keys) in data.objectsWithFederationKeys {
                    for key in keys {
                        println(
                            "func \(object.name.value.lowercased())(context: ContextType, key: \(object.name.value).\(key.name)) async throws -> \(object.name.value)?"
                        )
                    }
                }
            }
        }
    }

    func printResolverProtocolDefaultImplemention() throws {
        guard options.generateDefaultImplementation else { return }
        println()
        mark("Resolver Default Implemention")
        try scoped("extension \(data.schemaName).\(data.resolverName)", scope: .curly) {
            try looped(data.queryFields) { field in
                try scoped(
                    "func \(field.name.value)(context: ContextType, args: \(data.schemaName).\(field.name.value.capitalizeFirst)Arguments) async throws -> \(swiftTypeName(field.type, namespace: data.schemaName))",
                    scope: .curly
                ) {
                    printThrowError("Resolver for query.\(field.name.value) is unimplemented.")
                }
            }
            if !data.mutationFields.isEmpty {
                println()
            }
            try looped(data.mutationFields) { field in
                try scoped(
                    "func \(field.name.value)(context: ContextType, args: \(data.schemaName).\(field.name.value.capitalizeFirst)Arguments) async throws -> \(swiftTypeName(field.type, namespace: data.schemaName))",
                    scope: .curly
                ) {
                    printThrowError("Resolver for mutation.\(field.name.value) is unimplemented.")
                }
            }
            if !data.subscriptionFields.isEmpty {
                println()
            }
            try looped(data.subscriptionFields) { field in
                try scoped(
                    "func \(field.name.value)(context: ContextType, args: \(data.schemaName).\(field.name.value.capitalizeFirst)Arguments) async throws -> EventStream<\(swiftTypeName(field.type, namespace: data.schemaName))>",
                    scope: .curly
                ) {
                    printThrowError(
                        "Resolver for subscription.\(field.name.value) is unimplemented.")
                }
            }
            if !data.objectsWithFederationKeys.isEmpty {
                println()
            }
            looped(data.objectsWithFederationKeys) { (object, keys) in
                for key in keys {
                    scoped(
                        "func \(object.name.value.lowercased())(context: ContextType, key: \(data.schemaName).\(object.name.value).\(key.name)) async throws -> \(data.schemaName).\(object.name.value)?",
                        scope: .curly
                    ) {
                        printThrowError(
                            "Resolver for federation.\(object.name.value).\(key.name) is unimplemented."
                        )
                    }
                }
            }
        }
    }

    func printSchemaBuilder() throws {
        println()
        mark("Schema Builder")
        try scoped("extension \(data.schemaName)", scope: .curly) {
            try scoped(
                "static func schema<Resolver>(coders: Coders = Coders()) throws -> Schema<Resolver, Resolver.ContextType> where Resolver: \(data.resolverName)",
                scope: .curly
            ) {
                println("try SchemaBuilder(Resolver.self, Resolver.ContextType.self)")
                indent()
                println(".setCoders(to: coders)")
                println(".setFederatedSDL(to: sdl)")
                try printSchemaBuilderTypes()
                printSchemaBuilderQuery()
                printSchemaBuilderMutation()
                try printSchemaBuilderSubscription()
                println(".build()")
                outdent()
            }
        }
    }

    func printSchemaBuilderTypes() throws {
        try scoped(".add", scope: .curly) {
            for scalar in data.scalars {
                println("Scalar(\(scalar.name.value).self, as: \"\(scalar.name.value)\")")
                if let description = scalar.description?.value {
                    indent()
                    println(".description(\"\(description)\")")
                    outdent()
                }
            }
            for object in data.objects {
                let objectInterfaces = object.interfaces.map { "\($0.name.value).self" }
                let typeDeclaration: String
                if objectInterfaces.isEmpty {
                    typeDeclaration =
                        "Type(\(object.name.value).self, as: \"\(object.name.value)\")"
                } else {
                    typeDeclaration =
                        "Type(\(object.name.value).self, as: \"\(object.name.value)\", interfaces: [\(objectInterfaces.joined(separator: ", "))])"
                }

                scoped(typeDeclaration, scope: .curly) {
                    for field in object.fields {
                        if field.arguments.isEmpty {
                            println("Field(\"\(field.name.value)\", at: \\.\(field.name.value))")
                        } else {
                            scoped(
                                "Field(\"\(field.name.value)\", at: \(object.name.value)._\(field.name.value))",
                                scope: .curly
                            ) {
                                for argument in field.arguments {
                                    println(
                                        "Argument(\"\(argument.name.value)\", at: \\.\(argument.name.value))"
                                    )
                                }
                            }
                        }
                    }
                }
                for keys in try object.federationKeys() {
                    scoped(".key(at: Resolver.\(object.name.value.lowercased()))", scope: .curly) {
                        for field in keys.fields {
                            println("Argument(\"\(field)\", at: \\.\(field))")
                        }
                    }
                }
            }
            for input in data.inputs {
                scoped(
                    "Input(\(input.name.value).self, as: \"\(input.name.value)\")", scope: .curly
                ) {
                    for field in input.fields {
                        println("InputField(\"\(field.name.value)\", at: \\.\(field.name.value))")
                    }
                }
            }
            for object in data.enums {
                scoped("Enum(\(object.name.value).self)", scope: .curly) {
                    for value in object.values {
                        println("Value(.\(value.name.value.lowercased()))")
                    }
                }
            }
            for interface in data.interfaces {
                scoped("Interface(\(interface.name.value).self)", scope: .curly) {
                    for field in interface.fields {
                        println("Field(\"\(field.name.value)\", at: \\.\(field.name.value))")
                    }
                }
            }
        }
    }

    func printSchemaBuilderQuery() {
        guard !data.queryFields.isEmpty else { return }
        scoped(".addQuery", scope: .curly) {
            for field in data.queryFields {
                scoped(
                    "Field(\"\(field.name.value)\", at: Resolver.\(field.name.value))",
                    scope: .curly
                ) {
                    for argument in field.arguments {
                        println(
                            "Argument(\"\(argument.name.value)\", at: \\.\(argument.name.value))")
                    }
                }
            }
        }
    }

    func printSchemaBuilderMutation() {
        guard !data.mutationFields.isEmpty else { return }
        scoped(".addMutation", scope: .curly) {
            for field in data.mutationFields {
                scoped(
                    "Field(\"\(field.name.value)\", at: Resolver.\(field.name.value))",
                    scope: .curly
                ) {
                    for argument in field.arguments {
                        println(
                            "Argument(\"\(argument.name.value)\", at: \\.\(argument.name.value))")
                    }
                }
            }
        }
    }

    func printSchemaBuilderSubscription() throws {
        guard !data.subscriptionFields.isEmpty else { return }
        try scoped(".addSubscription", scope: .curly) {
            for field in data.subscriptionFields {
                try scoped(
                    "SubscriptionField(\"\(field.name.value)\", as: \(swiftTypeName(field.type)).self, atSub: Resolver.\(field.name.value))",
                    scope: .curly
                ) {
                    for argument in field.arguments {
                        println(
                            "Argument(\"\(argument.name.value)\", at: \\.\(argument.name.value))")
                    }
                }
            }
        }
    }
}
