import Foundation
#if canImport(FoundationNetworking)
    import FoundationNetworking
#endif
import PackagePlugin

@main
struct StarWarsAPIDownloadPlugin: CommandPlugin {
    let swapi = "https://swapi.dev/api"
    let decoder = JSONDecoder()
    let encoder = JSONEncoder()
    enum Resource: String, CaseIterable {
        case people
        case starships
        case vehicles
        case species
        case planets
        case films
    }

    func download<Content: Codable>(resource: Resource) async throws -> [Content] {
        var result: [Content] = []
        var hasNext = true
        var currentPage = 1
        while hasNext {
            guard let url = URL(string: "\(swapi)/\(resource.rawValue)/?page=\(currentPage)") else {
                throw StarWarsAPIDownloadPluginError(description: "Incorrect URL")
            }
            let request = URLRequest(url: url, cachePolicy: .reloadIgnoringCacheData)
            let (data, _) = try await URLSession.shared.data(for: request)
            let page = try decoder.decode(Page<Content>.self, from: data)
            hasNext = page.next != nil
            currentPage += 1
            result.append(contentsOf: page.results)
        }

        print("downloaded \(result.count) \(resource.rawValue)")
        return result
    }

    func performCommand(context: PluginContext, arguments: [String]) async throws {
        let database = try await Database(
            people: download(resource: .people),
            starships: download(resource: .starships),
            vehicles: download(resource: .vehicles),
            species: download(resource: .species),
            planets: download(resource: .planets),
            films: download(resource: .films)
        )

        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(database)
        try data.write(
            to: URL(
                filePath: context.package.directory.appending("Sources/StarWarsAPI/Database.json")
                    .string))
    }
}

struct StarWarsAPIDownloadPluginError: Error {
    let description: String
}

struct Page<Resource: Codable>: Codable {
    let count: Int
    let next: String?
    let previous: String?
    let results: [Resource]
}

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

struct Database: Codable {
    let people: [Person]
    let starships: [Starship]
    let vehicles: [Vehicle]
    let species: [Species]
    let planets: [Planet]
    let films: [Film]
}
