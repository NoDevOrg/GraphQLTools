import Foundation
import Vapor

extension Application {
    struct DatabaseKey: StorageKey {
        typealias Value = Database
    }

    var database: Database {
        guard let existing = storage[DatabaseKey.self] else {
            let database = createDatabase()
            storage[DatabaseKey.self] = database
            return database
        }
        return existing
    }

    private func createDatabase() -> Database {
        guard
            let url = Bundle.module.url(forResource: "Database", withExtension: "json"),
            let data = try? Data(contentsOf: url),
            let database = try? JSONDecoder().decode(Database.self, from: data)
        else {
            return Database(
                people: [], starships: [], vehicles: [], species: [], planets: [], films: [])
        }

        return database
    }
}

extension Request {
    var database: Database { application.database }
}

struct Database: Codable {
    let people: [Person]
    let starships: [Starship]
    let vehicles: [Vehicle]
    let species: [Species]
    let planets: [Planet]
    let films: [Film]

    struct Person: Codable {
        let name: String
        let height: String
        let mass: String
        let hair_color: String
        let skin_color: String
        let eye_color: String
        let birth_year: String
        let gender: String
        let homeworld: String
        let films: [String]
        let species: [String]
        let vehicles: [String]
        let starships: [String]
        let created: String
        let edited: String
        let url: String
    }

    struct Starship: Codable {
        let name: String
        let model: String
        let manufacturer: String
        let cost_in_credits: String
        let length: String
        let max_atmosphering_speed: String
        let crew: String
        let passengers: String
        let cargo_capacity: String
        let consumables: String
        let hyperdrive_rating: String
        let MGLT: String
        let starship_class: String
        let pilots: [String]
        let films: [String]
        let created: String
        let edited: String
        let url: String
    }

    struct Vehicle: Codable {
        let name: String
        let model: String
        let manufacturer: String
        let cost_in_credits: String
        let length: String
        let max_atmosphering_speed: String
        let crew: String
        let passengers: String
        let cargo_capacity: String
        let consumables: String
        let vehicle_class: String
        let pilots: [String]
        let films: [String]
        let created: String
        let edited: String
        let url: String
    }

    struct Species: Codable {
        let name: String
        let classification: String
        let designation: String
        let average_height: String
        let skin_colors: String
        let hair_colors: String
        let eye_colors: String
        let average_lifespan: String
        let homeworld: String?
        let language: String
        let people: [String]
        let films: [String]
        let created: String
        let edited: String
        let url: String
    }

    struct Planet: Codable {
        let name: String
        let rotation_period: String
        let orbital_period: String
        let diameter: String
        let climate: String
        let gravity: String
        let terrain: String
        let surface_water: String
        let population: String
        let residents: [String]
        let films: [String]
        let created: String
        let edited: String
        let url: String
    }

    struct Film: Codable {
        let title: String
        let episode_id: Int
        let opening_crawl: String
        let director: String
        let producer: String
        let release_date: String
        let characters: [String]
        let planets: [String]
        let starships: [String]
        let vehicles: [String]
        let species: [String]
        let created: String
        let edited: String
        let url: String
    }
}
