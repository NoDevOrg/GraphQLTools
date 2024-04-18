import Foundation
import Graphiti

extension Resolver: StarWarsSchema.StarWarsResolver {
    func allFilms(context: Context, args: StarWarsSchema.AllFilmsArguments) async throws
        -> StarWarsSchema.FilmsConnection?
    {
        let connection = try context.database.films.connection(from: args)

        return StarWarsSchema.FilmsConnection(
            edges: connection.edges.map {
                .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database))
            },
            films: connection.edges.map { $0.node.graphql(database: context.database) },
            pageInfo: connection.pageInfo.graphql,
            totalCount: connection.total
        )
    }

    func allPeople(context: Context, args: StarWarsSchema.AllPeopleArguments) async throws
        -> StarWarsSchema.PeopleConnection?
    {
        let connection = try context.database.people.connection(from: args)

        return .init(
            edges: connection.edges.map {
                .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database))
            },
            pageInfo: connection.pageInfo.graphql,
            people: connection.edges.map { $0.node.graphql(database: context.database) },
            totalCount: connection.total
        )
    }

    func allPlanets(context: Context, args: StarWarsSchema.AllPlanetsArguments) async throws
        -> StarWarsSchema.PlanetsConnection?
    {
        let connection = try context.database.planets.connection(from: args)

        return .init(
            edges: connection.edges.map {
                .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database))
            },
            pageInfo: connection.pageInfo.graphql,
            planets: connection.edges.map { $0.node.graphql(database: context.database) },
            totalCount: connection.total
        )
    }

    func allSpecies(context: Context, args: StarWarsSchema.AllSpeciesArguments) async throws
        -> StarWarsSchema.SpeciesConnection?
    {
        let connection = try context.database.species.connection(from: args)

        return .init(
            edges: connection.edges.map {
                .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database))
            },
            pageInfo: connection.pageInfo.graphql,
            species: connection.edges.map { $0.node.graphql(database: context.database) },
            totalCount: connection.total
        )
    }

    func allStarships(context: Context, args: StarWarsSchema.AllStarshipsArguments) async throws
        -> StarWarsSchema.StarshipsConnection?
    {
        let connection = try context.database.starships.connection(from: args)

        return .init(
            edges: connection.edges.map {
                .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database))
            },
            pageInfo: connection.pageInfo.graphql,
            starships: connection.edges.map { $0.node.graphql(database: context.database) },
            totalCount: connection.total
        )
    }

    func allVehicles(context: Context, args: StarWarsSchema.AllVehiclesArguments) async throws
        -> StarWarsSchema.VehiclesConnection?
    {
        let connection = try context.database.vehicles.connection(from: args)

        return .init(
            edges: connection.edges.map {
                .init(cursor: $0.cursor, node: $0.node.graphql(database: context.database))
            },
            pageInfo: connection.pageInfo.graphql,
            totalCount: connection.total,
            vehicles: connection.edges.map { $0.node.graphql(database: context.database) }
        )
    }

    func film(context: Context, args: StarWarsSchema.FilmArguments) async throws -> StarWarsSchema
        .Film?
    {
        context.database.films.first(where: {
            args.id?.string == $0.id || args.filmID?.string == String($0.episode_id)
        })?.graphql(database: context.database)
    }

    func person(context: Context, args: StarWarsSchema.PersonArguments) async throws
        -> StarWarsSchema.Person?
    {
        context.database.people.first(where: {
            args.id?.string == $0.id || args.personID?.string == $0.id
        })?.graphql(database: context.database)
    }

    func planet(context: Context, args: StarWarsSchema.PlanetArguments) async throws
        -> StarWarsSchema.Planet?
    {
        context.database.planets.first(where: {
            args.id?.string == $0.id || args.planetID?.string == $0.id
        })?.graphql(database: context.database)
    }

    func species(context: Context, args: StarWarsSchema.SpeciesArguments) async throws
        -> StarWarsSchema.Species?
    {
        context.database.species.first(where: {
            args.id?.string == $0.id || args.speciesID?.string == $0.id
        })?.graphql(database: context.database)
    }

    func starship(context: Context, args: StarWarsSchema.StarshipArguments) async throws
        -> StarWarsSchema.Starship?
    {
        context.database.starships.first(where: {
            args.id?.string == $0.id || args.starshipID?.string == $0.id
        })?.graphql(database: context.database)
    }

    func vehicle(context: Context, args: StarWarsSchema.VehicleArguments) async throws
        -> StarWarsSchema.Vehicle?
    {
        context.database.vehicles.first(where: {
            args.id?.string == $0.id || args.vehicleID?.string == $0.id
        })?.graphql(database: context.database)
    }
}
