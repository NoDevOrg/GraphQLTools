import GraphQL
import Vapor

extension Client {
    func graphql<Operation: GraphQLOperation>(url: URI, operation: Operation, encoder: JSONEncoder, decoder: JSONDecoder) async throws -> Operation.Result {
        let response = try await post(url, content: operation.request(encoder: encoder, decoder: decoder))
        let result = try response.content.decode(GraphQLResult.self)
        return try Operation.data(from: result, encoder: encoder, decoder: decoder)
    }
}

extension GraphQLRequest: Content {}
