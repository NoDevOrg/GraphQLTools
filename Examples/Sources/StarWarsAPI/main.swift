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
            Context(database: request.database)
        }
    )
)

defer { application.shutdown() }
try application.run()
