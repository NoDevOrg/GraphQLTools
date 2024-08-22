import Foundation
import GraphQL

struct OperationsGeneratorData {
    let namespace: String
    let schemaDefinitions: [any Definition]
    let operationDefinitionAndFile: [(OperationDefinition, String)]
    let queryFields: [FieldDefinition]
    let mutationFields: [FieldDefinition]
    let subscriptionFields: [FieldDefinition]
    let enumsNeeded: [EnumTypeDefinition]
    let inputsNeeded: [InputObjectTypeDefinition]

    init(options: OperationsGenerator.Options, schemas: [String], operations: [String]) throws {
        self.namespace = options.namespace

        do {
            let documents = try schemas.map { try parse(source: Source(body: $0)) }
            self.schemaDefinitions = documents.flatMap { $0.definitions }
        } catch {
            throw GeneratorError(description: "Parsing schemas failed. Underlying error: \(error)")
        }

        do {
            var operationDefinitionAndFile: [(OperationDefinition, String)] = []
            for file in operations {
                let definitions = try parse(source: Source(body: file)).definitions

                // TODO: Supporting multiple operations per file requires printing of just the operation and fragments
                // instead of using the file as the body of the request.
                guard definitions.count == 1, let definition = definitions.first as? OperationDefinition else {
                    throw GeneratorError(description: "Only 1 operation per file is supported.")
                }

                operationDefinitionAndFile.append((definition, file))
            }
            self.operationDefinitionAndFile = operationDefinitionAndFile
        } catch {
            throw GeneratorError(description: "Parsing operations failed. Underlying error: \(error)")
        }

        let operationTypes = schemaDefinitions.schemas
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

        self.queryFields = schemaDefinitions.objects(named: queryObjectName).flatMap { $0.fields }
        self.mutationFields = schemaDefinitions.objects(named: mutationObjectName).flatMap { $0.fields }
        self.subscriptionFields = schemaDefinitions.objects(named: subscriptionObjectName).flatMap {
            $0.fields
        }

        let allInputs = schemaDefinitions.compactMap { $0 as? InputObjectTypeDefinition }
        let allEnums = schemaDefinitions.compactMap { $0 as? EnumTypeDefinition }
        
        var inputsNeeded = Set<String>()
        var enumsNeeded = Set<String>()

        for (operation, file) in operationDefinitionAndFile {
            for variableDefinition in operation.variableDefinitions {
                let underlyingName = try underlyingTypeName(variableDefinition.type)
                guard !wellKnownTypes.keys.contains(underlyingName) else { continue }
                guard let input = allInputs.first(where: { $0.name.value == underlyingName }) else { continue }
                inputsNeeded.insert(input.name.value)
            }
        }
        
        var inputsToCheck = inputsNeeded
        while !inputsToCheck.isEmpty {
            let name = inputsToCheck.removeFirst()
            guard let input = allInputs.first(where: { $0.name.value == name }) else { continue }
            for field in input.fields {
                let underlyingName = try underlyingTypeName(field.type)
                guard !wellKnownTypes.keys.contains(underlyingName) else { continue }
                if let next = allInputs.first(where: { $0.name.value == underlyingName }) {
                    let (inserted, _) = inputsNeeded.insert(underlyingName)
                    if inserted {
                        inputsToCheck.insert(underlyingName)
                    }
                }
                if let next = allEnums.first(where: { $0.name.value == underlyingName }) {
                    enumsNeeded.insert(underlyingName)
                }
            }
        }

        self.enumsNeeded = enumsNeeded
            .compactMap { name in allEnums.first(where: { $0.name.value == name }) }
            .sorted(by: { $0.name.value < $1.name.value })
        self.inputsNeeded = inputsNeeded
            .compactMap { name in allInputs.first(where: { $0.name.value == name }) }
            .sorted(by: { $0.name.value < $1.name.value })
    }
}
