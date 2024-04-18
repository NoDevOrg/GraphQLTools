import Foundation
import Graphiti

extension StarWarsSchema.Vehicle: StarWarsSchema.Vehicle.Resolver {
    typealias ContextType = Context

    func filmConnection(context: Context, args: FilmConnectionArguments) async throws -> StarWarsSchema.VehicleFilmsConnection? {
        let connection = try context.database.films
            .filter { $0.vehicleIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.VehicleFilmsConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            films: connection.edges.map { $0.node.graphql(database: context.database) },
            pageInfo: connection.pageInfo.graphql,
            totalCount: connection.total
        )
    }

    func pilotConnection(context: Context, args: PilotConnectionArguments) async throws -> StarWarsSchema.VehiclePilotsConnection? {
        let connection = try context.database.people
            .filter { $0.vehicleIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.VehiclePilotsConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            pageInfo: connection.pageInfo.graphql,
            pilots: connection.edges.map { $0.node.graphql(database: context.database) },
            totalCount: connection.total
        )
    }
}
