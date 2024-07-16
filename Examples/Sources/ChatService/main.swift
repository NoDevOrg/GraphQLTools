import Graphiti
import Pioneer
import Vapor

let application = try Application(.detect())

application.http.server.configuration.port = 9001

// Custom encoding/decoding strategies. Provided by Graphiti
let coders = Coders()
coders.encoder.dateEncodingStrategy = .iso8601
coders.decoder.dateDecodingStrategy = .iso8601

let pioneer = Pioneer(
    schema: try ChatSchema.schema(coders: coders),
    resolver: Resolver()
)

// A custom context could be used where properties of the request
// such as headers or references to Vapor's database connection pools.
application.middleware.use(
    pioneer.vaporMiddleware(
        context: { _, _ in
            NoContext()
        },
        websocketContext: { request, _, _ in
            NoContext()
        }
    )
)

defer { application.shutdown() }
try application.run()
