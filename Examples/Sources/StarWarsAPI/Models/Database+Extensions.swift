import Foundation
import Pioneer

// Data from swapi.dev does not have an id field

extension Database.Person: Identifiable, PaginatableEntity {
    var id: String { URL(string: url)?.lastPathComponent ?? "X" }
    var cursor: String { url.base64String() }
    var filmIds: [String] { films.compactMap { $0.entityId() }}
    var speciesIds: [String] { species.compactMap { $0.entityId() }}
    var vehicleIds: [String] { vehicles.compactMap { $0.entityId() }}
    var starshipIds: [String] { starships.compactMap { $0.entityId() }}
}

extension Database.Film: Identifiable, PaginatableEntity {
    var id: String { URL(string: url)?.lastPathComponent ?? "X" }
    var cursor: String { String(url.hashValue) }
    var characterIds: [String] { characters.compactMap { $0.entityId() }}
    var planetIds: [String] { planets.compactMap { $0.entityId() }}
    var starshipIds: [String] { starships.compactMap { $0.entityId() }}
    var vehicleIds: [String] { vehicles.compactMap { $0.entityId() }}
    var specieIds: [String] { species.compactMap { $0.entityId() }}
}

extension Database.Starship: Identifiable, PaginatableEntity {
    var id: String { URL(string: url)?.lastPathComponent ?? "X" }
    var cursor: String { String(url.hashValue) }
    var pilotIds: [String] { pilots.compactMap { $0.entityId() }}
    var filmIds: [String] { films.compactMap { $0.entityId() }}
}

extension Database.Vehicle: Identifiable, PaginatableEntity {
    var id: String { URL(string: url)?.lastPathComponent ?? "X" }
    var cursor: String { String(url.hashValue) }
    var pilotIds: [String] { pilots.compactMap { $0.entityId() }}
    var filmIds: [String] { films.compactMap { $0.entityId() }}
}

extension Database.Species: Identifiable, PaginatableEntity {
    var id: String { URL(string: url)?.lastPathComponent ?? "X" }
    var cursor: String { String(url.hashValue) }
    var peopleIds: [String] { people.compactMap { $0.entityId() }}
    var filmIds: [String] { films.compactMap { $0.entityId() }}

}

extension Database.Planet: Identifiable, PaginatableEntity {
    var id: String { URL(string: url)?.lastPathComponent ?? "X" }
    var cursor: String { String(url.hashValue) }
    var residentIds: [String] { residents.compactMap { $0.entityId() }}
    var filmIds: [String] { films.compactMap { $0.entityId() }}
}
