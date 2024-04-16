import Graphiti
import Pioneer
import Vapor

let application = try Application(.detect())

let pioneer = Pioneer(
    schema: try StarWarsSchema.schema(),
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
