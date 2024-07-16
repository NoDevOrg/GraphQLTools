import Vapor

extension Client {
    func graphql<Operation: GraphQLOperation>(url: URI, operation: Operation, encoder: JSONEncoder, decoder: JSONDecoder) async throws -> GraphQLResponse<Operation> {
        let response = try await post(url) { request in
            request.headers.contentType = .json
            request.body = ByteBuffer(data: try encode(operation: operation, encoder: encoder))
        }

        guard let data = response.body else { throw Abort(.internalServerError) }

        return try decode(operation: operation, data: Data(buffer: data), decoder: decoder)
    }
}
