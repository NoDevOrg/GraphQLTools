import Pioneer
import Graphiti
import Vapor

let application = try Application(.detect())

// Too lazy to set up a database for this example
var messageHistory = [String: [ChatSchema.Message]]()

// Custom coders
let coders = Coders()
coders.encoder.dateEncodingStrategy = .iso8601
coders.decoder.dateDecodingStrategy = .iso8601

let pioneer = Pioneer(
    schema: try ChatSchema.schema(coders: coders),
    resolver: Resolver()
)

application.middleware.use(
    pioneer.vaporMiddleware(
        context: { request, _ in
            Context(request: request)
        },
        websocketContext: { request, _, _ in
            Context(request: request)
        }
    )
)

defer { application.shutdown() }
try application.run()
