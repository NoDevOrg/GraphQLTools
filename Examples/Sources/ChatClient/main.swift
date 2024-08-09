import Vapor

let application = try Application(.detect())

application.http.server.configuration.port = 9002

var encoder = JSONEncoder()
var decoder = JSONDecoder()

encoder.dateEncodingStrategy = .iso8601
decoder.dateDecodingStrategy = .iso8601

application.get("messages") { request in
    let query = Generated.ListMessagesQuery(room: "nodev")
    let response = try await request.client.graphql(url: "http://localhost:9001/graphql", operation: query, encoder: encoder, decoder: decoder)
    return response
}

extension Generated.ListMessagesQuery.Result: Content {}

defer { application.shutdown() }
try application.run()
