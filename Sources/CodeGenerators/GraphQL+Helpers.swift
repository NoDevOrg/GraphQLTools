import GraphQL

extension OperationType {
    var display: String {
        return switch self {
        case .query: "Query"
        case .mutation: "Mutation"
        case .subscription: "Subscription"
        }
    }
}

func underlyingTypeName(_ type: Type) throws -> String {
    switch type {
    case let type as NamedType:
        return type.name.value
    case let type as NonNullType:
        return try underlyingTypeName(type.type)
    case let type as ListType:
        return try underlyingTypeName(type.type)
    default:
        throw GeneratorError(description: "Unknown type \(type) to lookup underlying type")
    }
}

func swiftTypeName(_ type: Type, namespace: String = "", nestedInNonNull: Bool = false) throws
    -> String
{
    switch type {
    case let type as NamedType:
        if nestedInNonNull {
            return swiftTypeMapping(type.name.value, namespace: namespace)
        } else {
            return "\(swiftTypeMapping(type.name.value, namespace: namespace))?"
        }
    case let type as NonNullType:
        return try swiftTypeName(type.type, namespace: namespace, nestedInNonNull: true)
    case let type as ListType:
        return try "[\(swiftTypeName(type.type, namespace: namespace))]"
    default:
        throw GeneratorError(description: "Unknown type \(type) to convert to swift type")
    }
}

let wellKnownTypes = [
    "Int": "Int",
    "Float": "Float",
    "String": "String",
    "Boolean": "Bool",
]

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
