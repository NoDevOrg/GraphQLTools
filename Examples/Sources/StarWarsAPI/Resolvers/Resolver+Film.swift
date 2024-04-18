import Foundation
import Graphiti

extension StarWarsSchema.Film: StarWarsSchema.Film.Resolver {
    typealias ContextType = Context

    func characterConnection(context: Context, args: CharacterConnectionArguments) async throws -> StarWarsSchema.FilmCharactersConnection? {
        let connection = try context.database.people
            .filter { $0.filmIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.FilmCharactersConnection(
            characters: connection.edges.map { $0.node.graphql(database: context.database) },
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            pageInfo: connection.pageInfo.graphql,
            totalCount: connection.total
        )
    }

    func planetConnection(context: Context, args: PlanetConnectionArguments) async throws -> StarWarsSchema.FilmPlanetsConnection? {
        let connection = try context.database.planets
            .filter { $0.filmIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.FilmPlanetsConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            pageInfo: connection.pageInfo.graphql,
            planets: connection.edges.map { $0.node.graphql(database: context.database) },
            totalCount: connection.total
        )
    }

    func speciesConnection(context: Context, args: SpeciesConnectionArguments) async throws -> StarWarsSchema.FilmSpeciesConnection? {
        let connection = try context.database.species
            .filter { $0.filmIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.FilmSpeciesConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            pageInfo: connection.pageInfo.graphql,
            species: connection.edges.map { $0.node.graphql(database: context.database) },
            totalCount: connection.total
        )
    }

    func starshipConnection(context: Context, args: StarshipConnectionArguments) async throws -> StarWarsSchema.FilmStarshipsConnection? {
        let connection = try context.database.starships
            .filter { $0.filmIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.FilmStarshipsConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            pageInfo: connection.pageInfo.graphql,
            starships: connection.edges.map { $0.node.graphql(database: context.database) },
            totalCount: connection.total
        )
    }

    func vehicleConnection(context: Context, args: VehicleConnectionArguments) async throws -> StarWarsSchema.FilmVehiclesConnection? {
        let connection = try context.database.vehicles
            .filter { $0.filmIds.contains(self.id.string) }
            .connection(from: args)

        return StarWarsSchema.FilmVehiclesConnection(
            edges: connection.edges.map { .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database)) },
            pageInfo: connection.pageInfo.graphql,
            totalCount: connection.total,
            vehicles: connection.edges.map { $0.node.graphql(database: context.database) }
        )
    }
}
