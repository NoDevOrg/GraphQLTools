import Foundation
import GraphQL
import Pioneer
import Vapor

struct Context {
    let request: Request
}

struct Resolver: StarWarsSchema.StarWarsResolver {
    typealias ContextType = Context
}
