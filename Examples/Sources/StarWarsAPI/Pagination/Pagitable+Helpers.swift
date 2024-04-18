import Foundation
import Graphiti

// Helpers to map Graphiti Pagination/Connections to StarWars Schema

protocol StarWarsConnection {
    associatedtype Entity

    init(edges: [Edge<Entity>], pageInfo: PageInfo, totalCount: Int)
}

protocol PaginatableEntity {
    var cursor: String { get }
}

extension Array where Element: PaginatableEntity {
    func connection(from arguments: Paginatable) throws -> (
        edges: [Edge<Element>], pageInfo: PageInfo, total: Int
    ) {
        let connection = try connection(from: arguments, makeCursor: { $0.cursor })
        return (connection.edges, connection.pageInfo, count)
    }
}

extension PageInfo {
    var graphql: StarWarsSchema.PageInfo {
        StarWarsSchema.PageInfo(
            endCursor: endCursor,
            hasNextPage: hasNextPage,
            hasPreviousPage: hasPreviousPage,
            startCursor: startCursor
        )
    }
}
