import Foundation
import Graphiti

extension StarWarsSchema.AllFilmsArguments: Paginatable {}
extension StarWarsSchema.AllPeopleArguments: Paginatable {}
extension StarWarsSchema.AllPlanetsArguments: Paginatable {}
extension StarWarsSchema.AllSpeciesArguments: Paginatable {}
extension StarWarsSchema.AllStarshipsArguments: Paginatable {}
extension StarWarsSchema.AllVehiclesArguments: Paginatable {}

extension StarWarsSchema.Film.PlanetConnectionArguments: Paginatable {}
extension StarWarsSchema.Film.SpeciesConnectionArguments: Paginatable {}
extension StarWarsSchema.Film.VehicleConnectionArguments: Paginatable {}
extension StarWarsSchema.Film.StarshipConnectionArguments: Paginatable {}
extension StarWarsSchema.Film.CharacterConnectionArguments: Paginatable {}
extension StarWarsSchema.Person.FilmConnectionArguments: Paginatable {}
extension StarWarsSchema.Person.VehicleConnectionArguments: Paginatable {}
extension StarWarsSchema.Person.StarshipConnectionArguments: Paginatable {}
extension StarWarsSchema.Planet.FilmConnectionArguments: Paginatable {}
extension StarWarsSchema.Planet.ResidentConnectionArguments: Paginatable {}
extension StarWarsSchema.Species.FilmConnectionArguments: Paginatable {}
extension StarWarsSchema.Species.PersonConnectionArguments: Paginatable {}
extension StarWarsSchema.Starship.FilmConnectionArguments: Paginatable {}
extension StarWarsSchema.Starship.PilotConnectionArguments: Paginatable {}
extension StarWarsSchema.Vehicle.FilmConnectionArguments: Paginatable {}
extension StarWarsSchema.Vehicle.PilotConnectionArguments: Paginatable {}
