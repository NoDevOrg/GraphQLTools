import Foundation
import Graphiti

extension StarWarsSchema.Planet: StarWarsSchema.Planet.Resolver {
    typealias ContextType = Context

    func filmConnection(context: ContextType, args: FilmConnectionArguments) async throws -> StarWarsSchema.PlanetFilmsConnection? {
        let connection = try context.database.films
            .filter { $0.planetIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.PlanetFilmsConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database))},
            films: connection.edges.map { $0.node.graphql(database: context.database)},
            pageInfo: connection.pageInfo.graphql,
            totalCount: connection.total
        )
    }

    func residentConnection(context: ContextType, args: ResidentConnectionArguments) async throws -> StarWarsSchema.PlanetResidentsConnection? {
        let connection = try context.database.people
            .filter { $0.homeworld.entityId() == self.id.string }
            .connection(from: args)

        return StarWarsSchema.PlanetResidentsConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database))},
            pageInfo: connection.pageInfo.graphql,
            residents: connection.edges.map { $0.node.graphql(database: context.database)},
            totalCount: connection.total
        )
    }
}
