import Foundation
import Pioneer

extension String {
    func entityId() -> String? {
        URL(string: self)?.lastPathComponent
    }
}

extension Database.Film {
    func graphql(database: Database) -> StarWarsSchema.Film {
        StarWarsSchema.Film(
            created: created,
            director: director,
            edited: edited,
            episodeID: episode_id,
            id: id.toID(),
            openingCrawl: opening_crawl,
            producers: producer.split(separator: ", ").map { String($0) },
            releaseDate: release_date,
            title: title
        )
    }
}

extension Database.Person {
    func graphql(database: Database) -> StarWarsSchema.Person {
        StarWarsSchema.Person(
            birthYear: birth_year,
            created: created,
            edited: edited,
            eyeColor: eye_color,
            gender: gender,
            hairColor: hair_color,
            height: Int(height),
            homeworld: database.planets.first(where: { $0.id == homeworld.entityId() })?.graphql(
                database: database),
            id: id.toID(),
            mass: Float(mass),
            name: name,
            skinColor: skin_color,
            species: database.species.first(where: { $0.id == species.first?.entityId() })?.graphql(
                database: database)
        )
    }
}

extension Database.Starship {
    func graphql(database: Database) -> StarWarsSchema.Starship {
        StarWarsSchema.Starship(
            MGLT: Int(MGLT),
            cargoCapacity: Float(cargo_capacity),
            consumables: consumables,
            costInCredits: Float(cost_in_credits),
            created: created,
            crew: crew,
            edited: edited,
            hyperdriveRating: Float(hyperdrive_rating),
            id: id.toID(),
            length: Float(length),
            manufacturers: manufacturer.split(separator: ", ").map { String($0) },
            maxAtmospheringSpeed: Int(max_atmosphering_speed),
            model: model,
            name: name,
            passengers: passengers,
            starshipClass: starship_class
        )
    }
}

extension Database.Vehicle {
    func graphql(database: Database) -> StarWarsSchema.Vehicle {
        StarWarsSchema.Vehicle(
            cargoCapacity: Float(cargo_capacity),
            consumables: consumables,
            costInCredits: Float(cost_in_credits),
            created: created,
            crew: crew,
            edited: edited,
            id: id.toID(),
            length: Float(length),
            manufacturers: manufacturer.split(separator: ", ").map { String($0) },
            maxAtmospheringSpeed: Int(max_atmosphering_speed),
            model: model,
            name: name,
            passengers: passengers,
            vehicleClass: vehicle_class
        )
    }
}

extension Database.Species {
    func graphql(database: Database) -> StarWarsSchema.Species {
        StarWarsSchema.Species(
            averageHeight: Float(average_height),
            averageLifespan: Int(average_lifespan),
            classification: classification,
            created: created,
            designation: designation,
            edited: edited,
            eyeColors: eye_colors.split(separator: ", ").map { String($0) },
            hairColors: hair_colors.split(separator: ", ").map { String($0) },
            homeworld: database.planets.first(where: { $0.id == homeworld?.entityId() })?.graphql(
                database: database),
            id: id.toID(),
            language: language,
            name: name,
            skinColors: skin_colors.split(separator: ", ").map { String($0) }
        )
    }
}

extension Database.Planet {
    func graphql(database: Database) -> StarWarsSchema.Planet {
        StarWarsSchema.Planet(
            climates: climate.split(separator: ", ").map { String($0) },
            created: created,
            diameter: Int(diameter),
            edited: edited,
            gravity: gravity,
            id: id.toID(),
            name: name,
            orbitalPeriod: Int(orbital_period),
            population: Float(population),
            rotationPeriod: Int(rotation_period),
            surfaceWater: Float(surface_water),
            terrains: terrain.split(separator: ", ").map { String($0) }
        )
    }
}
