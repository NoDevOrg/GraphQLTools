import Foundation
import GraphQL

extension Generator {
    func swift(_ type: Type, namespace: String = "", nestedInNonNull: Bool = false) throws -> String {
        return switch type {
        case let type as NamedType:
            if nestedInNonNull {
                swiftTypeMapping(type.name.value, namespace: namespace)
            } else {
                "\(swiftTypeMapping(type.name.value, namespace: namespace))?"
            }
        case let type as NonNullType:
            try swift(type.type, namespace: namespace, nestedInNonNull: true)
        case let type as ListType:
            try "[\(swift(type.type, namespace: namespace))]"
        default:
            throw GeneratorError(description: "Cannot convert to swift type")
        }
    }

    func swiftTypeMapping(_ name: String, namespace: String) -> String {
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

    var objects: [ObjectTypeDefinition] {
        definitions
            .compactMap { $0 as? ObjectTypeDefinition }
            .filter { !["Query", "Mutation", "Subscription"].contains($0.name.value) }
    }
    
    var objectsWithFederationKey: [(object: ObjectTypeDefinition, keys: [Directive])] {
        objects
            .map { ($0, $0.directives.filter { directive in directive.name.value == "key" }) }
            .filter { !$0.keys.isEmpty}
    }
    
    var scalars: [ScalarTypeDefinition] {
        definitions
            .compactMap { $0 as? ScalarTypeDefinition }
    }
    
    // TODO: Support SchemeDefinition.OperationTypes for custom query object names
    var queryObjects: [ObjectTypeDefinition] {
        definitions
            .compactMap { $0 as? ObjectTypeDefinition }
            .filter { $0.name.value == "Query" }
    }

    // TODO: Support SchemeDefinition.OperationTypes for custom mutation object names
    var mutationObjects: [ObjectTypeDefinition] {
        definitions
            .compactMap { $0 as? ObjectTypeDefinition }
            .filter { $0.name.value == "Mutation" }
    }

    // TODO: Support SchemeDefinition.OperationTypes for custom subscription object names
    var subscriptionObjects: [ObjectTypeDefinition] {
        definitions
            .compactMap { $0 as? ObjectTypeDefinition }
            .filter { $0.name.value == "Subscription" }
    }

    var queryResolverFields: [FieldDefinition] {
        queryObjects.flatMap { $0.fields }
    }

    var mutationResolverFields: [FieldDefinition] {
        mutationObjects.flatMap { $0.fields }
    }

    var subscriptionResolverFields: [FieldDefinition] {
        subscriptionObjects.flatMap { $0.fields }
    }

    var allResolverFields: [FieldDefinition] {
       queryResolverFields + mutationResolverFields + subscriptionResolverFields
    }
}

