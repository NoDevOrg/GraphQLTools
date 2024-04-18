import Foundation
import Graphiti

extension StarWarsSchema.Person: StarWarsSchema.Person.Resolver {
    typealias ContextType = Context

    func filmConnection(context: Context, args: FilmConnectionArguments) async throws -> StarWarsSchema.PersonFilmsConnection? {
        let connection = try context.database.films
            .filter { $0.characterIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.PersonFilmsConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            films: connection.edges.map { $0.node.graphql(database: context.database) },
            pageInfo: connection.pageInfo.graphql,
            totalCount: connection.total
        )
    }

    func starshipConnection(context: Context, args: StarshipConnectionArguments) async throws -> StarWarsSchema.PersonStarshipsConnection? {
        let connection = try context.database.starships
            .filter { $0.pilotIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.PersonStarshipsConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            pageInfo: connection.pageInfo.graphql,
            starships: connection.edges.map { $0.node.graphql(database: context.database) },
            totalCount: connection.total
        )
    }

    func vehicleConnection(context: Context, args: VehicleConnectionArguments) async throws -> StarWarsSchema.PersonVehiclesConnection? {
        let connection = try context.database.vehicles
            .filter { $0.pilotIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.PersonVehiclesConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            pageInfo: connection.pageInfo.graphql,
            totalCount: connection.total,
            vehicles: connection.edges.map { $0.node.graphql(database: context.database) }
        )
    }
}
