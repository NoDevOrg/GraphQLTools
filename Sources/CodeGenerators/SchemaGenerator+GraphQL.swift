import Foundation
import GraphQL

struct SchemaGeneratorData {
    let schemaName: String
    let resolverName: String
    let objects: [ObjectTypeDefinition]
    let inputs: [InputObjectTypeDefinition]
    let enums: [EnumTypeDefinition]
    let scalars: [ScalarTypeDefinition]
    let interfaces: [InterfaceTypeDefinition]
    let queryFields: [FieldDefinition]
    let mutationFields: [FieldDefinition]
    let subscriptionFields: [FieldDefinition]
    let objectsWithFederationKeys: [(object: ObjectTypeDefinition, keys: [(name: String, fields: [String])])]

    init(options: SchemaGenerator.Options, schemas: [String]) throws {
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

        self.queryFields = definitions.objects(named: queryObjectName).flatMap { $0.fields }
        self.mutationFields = definitions.objects(named: mutationObjectName).flatMap { $0.fields }
        self.subscriptionFields = definitions.objects(named: subscriptionObjectName).flatMap {
            $0.fields
        }
        self.objectsWithFederationKeys = try definitions.objects
            .map { try ($0, $0.federationKeys()) }
            .filter { !$0.keys.isEmpty }
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

    func objects(named: String) -> [ObjectTypeDefinition] {
        objects.filter { $0.name.value == named }
    }
}

extension ObjectTypeDefinition {
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

extension SchemaGenerator {
    func printThrowError(_ text: String) {
        println("throw \(data.schemaName)Error(description: \"\(text)\")")
    }
}
