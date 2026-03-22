import Foundation
import GraphQL

struct GeneratorData {
    let schemaName: String
    let resolverName: String
    let objects: [ObjectTypeDefinition]
    let inputs: [InputObjectTypeDefinition]
    let enums: [EnumTypeDefinition]
    let scalars: [ScalarTypeDefinition]
    let interfaces: [InterfaceTypeDefinition]
    let unions: [UnionTypeDefinition]
    let queryFields: [FieldDefinition]
    let mutationFields: [FieldDefinition]
    let subscriptionFields: [FieldDefinition]
    let objectsWithFederationKeys: [(object: ObjectTypeDefinition, keys: [(name: String, fields: [String])])]

    /// Merged computed fields map: user overrides + auto-detected (union-typed fields, cycle-breaking).
    /// Key = object type name, Value = set of field names that should be computed.
    let effectiveComputedFields: [String: Set<String>]

    /// Map from union name to its member type names.
    let unionMembers: [String: [String]]

    /// Set of all union type names for quick lookup.
    let unionTypeNames: Set<String>

    /// Set of all interface type names for quick lookup.
    let interfaceTypeNames: Set<String>

    /// Input types that must be emitted as `class` instead of `struct` to break cycles.
    let classInputTypes: Set<String>

    init(options: GeneratorOptions, schemas: [String]) throws {
        self.schemaName = options.namespace + "Schema"
        self.resolverName = options.namespace + "Resolver"

        let definitions: [any Definition]
        do {
            let documents = try schemas.map { try parse(source: Source(body: $0)) }
            definitions = documents.flatMap { $0.definitions }
        } catch {
            throw GeneratorError(description: "Parsing schemas failed. Underlying error: \(error)")
        }

        let operationTypes = definitions.schemas
            .flatMap { $0.operationTypes }

        let possibleQueryTypeNames =
            operationTypes
            .filter { $0.operation == .query }
            .map { $0.type.name.value }

        guard possibleQueryTypeNames.count <= 1 else {
            throw GeneratorError(
                description:
                    "schema.query type is defined multiple times as: \(possibleQueryTypeNames)")
        }

        let possibleMutationTypeNames =
            operationTypes
            .filter { $0.operation == .mutation }
            .map { $0.type.name.value }

        guard possibleMutationTypeNames.count <= 1 else {
            throw GeneratorError(
                description:
                    "schema.mutation type is defined multiple times as: \(possibleMutationTypeNames)"
            )
        }

        let possibleSubscriptionTypeNames =
            operationTypes
            .filter { $0.operation == .subscription }
            .map { $0.type.name.value }

        guard possibleSubscriptionTypeNames.count <= 1 else {
            throw GeneratorError(
                description:
                    "schema.subscription is defined multiple times as: \(possibleSubscriptionTypeNames)"
            )
        }

        let queryObjectName = possibleQueryTypeNames.first ?? "Query"
        let mutationObjectName = possibleMutationTypeNames.first ?? "Mutation"
        let subscriptionObjectName = possibleSubscriptionTypeNames.first ?? "Subscription"

        self.objects = definitions.objects
            .filter {
                ![queryObjectName, mutationObjectName, subscriptionObjectName].contains(
                    $0.name.value)
            }

        self.inputs = definitions.inputs
        self.enums = definitions.enums
        self.scalars = definitions.scalars
        self.interfaces = definitions.interfaces
        self.unions = definitions.unions

        self.queryFields = definitions.objects(named: queryObjectName).flatMap { $0.fields }
        self.mutationFields = definitions.objects(named: mutationObjectName).flatMap { $0.fields }
        self.subscriptionFields = definitions.objects(named: subscriptionObjectName).flatMap {
            $0.fields
        }
        self.objectsWithFederationKeys = try definitions.objects
            .map { try ($0, $0.federationKeys()) }
            .filter { !$0.keys.isEmpty }

        // Build union lookup tables
        var unionMembers: [String: [String]] = [:]
        var unionTypeNames: Set<String> = []
        for union in self.unions {
            let memberNames = union.types.map { $0.name.value }
            unionMembers[union.name.value] = memberNames
            unionTypeNames.insert(union.name.value)
        }
        self.unionMembers = unionMembers
        self.unionTypeNames = unionTypeNames
        self.interfaceTypeNames = Set(self.interfaces.map { $0.name.value })

        // Build effective computed fields: start with user overrides
        var effective: [String: Set<String>] = [:]
        for (objectName, fields) in options.computedFields {
            effective[objectName] = Set(fields)
        }

        // Auto-promote union-typed and interface-typed fields to computed
        // (can't be stored as protocol existentials — Codable synthesis fails)
        let protocolTypeNames = unionTypeNames.union(self.interfaceTypeNames)
        for object in self.objects {
            for field in object.fields {
                let referencedType = Self.deepNamedTypeName(field.type)
                if let typeName = referencedType, protocolTypeNames.contains(typeName) {
                    effective[object.name.value, default: []].insert(field.name.value)
                }
            }
        }

        // Detect cycles in object types and auto-break them
        let objectTypeNames = Set(self.objects.map { $0.name.value })
        let cycleBreakers = Self.detectCycleBreakingFields(
            types: self.objects.map { ($0.name.value, $0.fields) },
            knownTypeNames: objectTypeNames,
            existingComputed: effective
        )
        for (typeName, fieldName) in cycleBreakers {
            effective[typeName, default: []].insert(fieldName)
            fputs(
                "warning: Auto-promoting \(typeName).\(fieldName) to computed field to break type cycle\n",
                stderr
            )
        }

        self.effectiveComputedFields = effective

        // Detect cycles in input types — these use `class` instead of `struct`
        let inputTypeNames = Set(self.inputs.map { $0.name.value })
        let inputCycleTypes = Self.detectCycleBreakingTypes(
            types: self.inputs.map { ($0.name.value, $0.fields) },
            knownTypeNames: inputTypeNames
        )
        self.classInputTypes = inputCycleTypes
        for typeName in inputCycleTypes {
            fputs(
                "warning: Emitting input type \(typeName) as class to break type cycle\n",
                stderr
            )
        }
    }

    /// Extracts the named type from a (potentially wrapped) GraphQL type, ignoring lists.
    /// Returns nil for list types since arrays break cycles naturally.
    static func namedTypeName(_ type: Type) -> String? {
        switch type {
        case let named as NamedType:
            return named.name.value
        case let nonNull as NonNullType:
            return namedTypeName(nonNull.type)
        case is ListType:
            // Arrays store on heap — no infinite-size issue
            return nil
        default:
            return nil
        }
    }

    /// Extracts the named type from a (potentially wrapped) GraphQL type, including through lists.
    /// Used for detecting protocol existential references (union/interface types) where Codable
    /// synthesis fails regardless of list wrapping.
    static func deepNamedTypeName(_ type: Type) -> String? {
        switch type {
        case let named as NamedType:
            return named.name.value
        case let nonNull as NonNullType:
            return deepNamedTypeName(nonNull.type)
        case let list as ListType:
            return deepNamedTypeName(list.type)
        default:
            return nil
        }
    }

    /// Detect fields that need to become computed to break cycles in object types.
    /// Returns pairs of (typeName, fieldName) to promote.
    static func detectCycleBreakingFields(
        types: [(name: String, fields: [FieldDefinition])],
        knownTypeNames: Set<String>,
        existingComputed: [String: Set<String>]
    ) -> [(String, String)] {
        // Build adjacency: type -> [(referencedType, fieldName, isOptional)]
        var adjacency: [String: [(target: String, field: String, optional: Bool)]] = [:]
        for (typeName, fields) in types {
            for field in fields {
                // Skip fields already marked as computed
                if existingComputed[typeName]?.contains(field.name.value) == true {
                    continue
                }
                // Skip fields with arguments (already computed)
                if !field.arguments.isEmpty {
                    continue
                }
                if let referencedType = namedTypeName(field.type),
                   knownTypeNames.contains(referencedType)
                {
                    let isOptional = !(field.type is NonNullType)
                    adjacency[typeName, default: []].append(
                        (target: referencedType, field: field.name.value, optional: isOptional)
                    )
                }
            }
        }

        var result: [(String, String)] = []
        var visited: Set<String> = []
        var inStack: Set<String> = []
        var removedEdges: Set<String> = [] // "TypeName.fieldName" keys for removed edges

        func edgeKey(_ typeName: String, _ fieldName: String) -> String {
            "\(typeName).\(fieldName)"
        }

        func dfs(_ node: String, path: [(type: String, field: String, optional: Bool)]) {
            if inStack.contains(node) {
                // Found cycle — find the back edge in the path and break it
                guard let cycleStart = path.firstIndex(where: { $0.type == node }) else { return }
                let cycle = Array(path[cycleStart...])

                // Prefer breaking at an optional field
                let breakIdx: Int
                if let optIdx = cycle.firstIndex(where: { $0.optional }) {
                    breakIdx = optIdx
                } else {
                    breakIdx = cycle.count - 1
                }

                let edge = cycle[breakIdx]
                let key = edgeKey(edge.type, edge.field)
                if !removedEdges.contains(key) {
                    removedEdges.insert(key)
                    result.append((edge.type, edge.field))
                }
                return
            }

            if visited.contains(node) { return }
            visited.insert(node)
            inStack.insert(node)

            for edge in adjacency[node, default: []] {
                let key = edgeKey(node, edge.field)
                if removedEdges.contains(key) { continue }
                dfs(edge.target, path: path + [(type: node, field: edge.field, optional: edge.optional)])
            }

            inStack.remove(node)
        }

        for (typeName, _) in types {
            dfs(typeName, path: [])
        }

        return result
    }

    /// Detect input types that need to be emitted as `class` to break cycles.
    /// Returns a set of type names that should use `class`.
    static func detectCycleBreakingTypes(
        types: [(name: String, fields: [InputValueDefinition])],
        knownTypeNames: Set<String>
    ) -> Set<String> {
        // Build adjacency for input types
        var adjacency: [String: [String]] = [:]
        for (typeName, fields) in types {
            for field in fields {
                if let referencedType = namedTypeName(field.type),
                   knownTypeNames.contains(referencedType)
                {
                    adjacency[typeName, default: []].append(referencedType)
                }
            }
        }

        // Find all types involved in cycles using DFS
        var visited: Set<String> = []
        var inStack: Set<String> = []
        var cycleTypes: Set<String> = []

        func dfs(_ node: String, path: [String]) {
            if inStack.contains(node) {
                // Found cycle — mark the node that completes the cycle as class
                // (breaking the cycle at one point is sufficient)
                cycleTypes.insert(node)
                return
            }
            if visited.contains(node) { return }
            visited.insert(node)
            inStack.insert(node)

            for neighbor in adjacency[node, default: []] {
                dfs(neighbor, path: path + [node])
            }

            inStack.remove(node)
        }

        for (typeName, _) in types {
            dfs(typeName, path: [])
        }

        return cycleTypes
    }
}

extension [any Definition] {
    var schemas: [SchemaDefinition] {
        self.compactMap {
            if let schema = $0 as? SchemaDefinition { return schema }
            if let schemaExtension = $0 as? SchemaExtensionDefinition {
                return schemaExtension.definition
            }
            return nil
        }
    }

    var objects: [ObjectTypeDefinition] {
        self.compactMap {
            if let object = $0 as? ObjectTypeDefinition { return object }
            if let objectExtension = $0 as? TypeExtensionDefinition {
                return objectExtension.definition
            }
            return nil
        }
    }

    var inputs: [InputObjectTypeDefinition] {
        self.compactMap {
            if let input = $0 as? InputObjectTypeDefinition { return input }
            if let inputExtension = $0 as? InputObjectExtensionDefinition {
                return inputExtension.definition
            }
            return nil
        }
    }

    var enums: [EnumTypeDefinition] {
        self.compactMap {
            if let `enum` = $0 as? EnumTypeDefinition { return `enum` }
            if let enumExtension = $0 as? EnumExtensionDefinition {
                return enumExtension.definition
            }
            return nil
        }
    }

    var scalars: [ScalarTypeDefinition] {
        self.compactMap {
            if let scalar = $0 as? ScalarTypeDefinition { return scalar }
            if let scalarExtension = $0 as? ScalarExtensionDefinition {
                return scalarExtension.definition
            }
            return nil
        }
    }

    var interfaces: [InterfaceTypeDefinition] {
        self.compactMap {
            if let interface = $0 as? InterfaceTypeDefinition { return interface }
            if let interfaceExtension = $0 as? InterfaceExtensionDefinition {
                return interfaceExtension.definition
            }
            return nil
        }
    }

    var unions: [UnionTypeDefinition] {
        self.compactMap {
            if let union = $0 as? UnionTypeDefinition { return union }
            if let unionExtension = $0 as? UnionExtensionDefinition {
                return unionExtension.definition
            }
            return nil
        }
    }

    func objects(named: String) -> [ObjectTypeDefinition] {
        objects.filter { $0.name.value == named }
    }
}

extension ObjectTypeDefinition {
    func basicFields(options: GeneratorOptions) -> [FieldDefinition] {
        let overrides = options.computedFields[name.value, default: []]
        return fields.filter {
            $0.arguments.isEmpty && !overrides.contains($0.name.value)
        }
    }

    func basicFields(effectiveComputed: [String: Set<String>]) -> [FieldDefinition] {
        let overrides = effectiveComputed[name.value, default: []]
        return fields.filter {
            $0.arguments.isEmpty && !overrides.contains($0.name.value)
        }
    }

    func computedFields(options: GeneratorOptions) -> [FieldDefinition] {
        let overrides = options.computedFields[name.value, default: []]
        return fields.filter {
            !$0.arguments.isEmpty || overrides.contains($0.name.value)
        }
    }

    func computedFields(effectiveComputed: [String: Set<String>]) -> [FieldDefinition] {
        let overrides = effectiveComputed[name.value, default: []]
        return fields.filter {
            !$0.arguments.isEmpty || overrides.contains($0.name.value)
        }
    }

    func field(named: String) throws -> FieldDefinition {
        guard let field = fields.first(where: { $0.name.value == named }) else {
            throw GeneratorError(description: "Field \(named) not found on object \(name.value)")
        }
        return field
    }

    func federationKeys() throws -> [(name: String, fields: [String])] {
        let keyDirectives = directives.filter { $0.name.value == "key" }

        if keyDirectives.count == 1 {
            return try [("Key", keyDirectives[0].federationKeyFields())]
        } else {
            return try keyDirectives.enumerated().map {
                try ("Key\($0.offset)", $0.element.federationKeyFields())
            }
        }
    }
}

extension Directive {
    func federationKeyFields() throws -> [String] {
        guard let argument = arguments.first(where: { $0.name.value == "fields" }) else {
            throw GeneratorError(description: "Key directive missing fields argument")
        }

        guard let value = (argument.value as? StringValue)?.value else {
            throw GeneratorError(description: "Key directive fields argument not a string")
        }

        guard !value.contains("{"), !value.contains("}") else {
            throw GeneratorError(description: "Key directive does not support nested keys")
        }

        let fields = value.split(separator: " ")
        guard !fields.isEmpty else {
            throw GeneratorError(description: "Key directive fields argument is empty")
        }

        return fields.map { String($0) }
    }
}

extension Generator {
    func printThrowError(_ text: String) {
        println("throw \(data.schemaName)Error(description: \"\(text)\")")
    }

    func swiftTypeName(_ type: Type, namespace: String = "", nestedInNonNull: Bool = false) throws
        -> String
    {
        switch type {
        case let type as NamedType:
            let name = swiftTypeMapping(type.name.value, namespace: namespace)
            let isProtocolType = data.unionTypeNames.contains(type.name.value)
                || data.interfaceTypeNames.contains(type.name.value)
            if isProtocolType {
                return nestedInNonNull ? "any \(name)" : "(any \(name))?"
            } else {
                return nestedInNonNull ? name : "\(name)?"
            }
        case let type as NonNullType:
            return try swiftTypeName(type.type, namespace: namespace, nestedInNonNull: true)
        case let type as ListType:
            return try "[\(swiftTypeName(type.type, namespace: namespace))]"
        default:
            throw GeneratorError(description: "Unknown type \(type) to convert to swift type")
        }
    }

    private func swiftTypeMapping(_ name: String, namespace: String) -> String {
        if let knownType = wellKnownTypes[name] {
            return knownType
        } else {
            if namespace.isEmpty {
                return name
            } else {
                return "\(namespace).\(name)"
            }
        }
    }
}
