import Vapor
import Fluent

struct PaginationInfo: Content {
    let currentPage: Int
    let totalPages: Int
    let total: Int
    let perPage: Int
    let hasNextPage: Bool
    let hasPreviousPage: Bool
}

protocol Paginatable where Self: Model {
    static func paginate(
        on database: Database,
        page: Int,
        per: Int,
        filter: (QueryBuilder<Self>) -> QueryBuilder<Self>
    ) async throws -> (items: [Self], info: PaginationInfo)
}

extension Paginatable where Self: Model {
    static func paginate(
        on database: Database,
        page: Int = 1,
        per: Int = 10,
        filter: (QueryBuilder<Self>) -> QueryBuilder<Self> = { $0 }
    ) async throws -> (items: [Self], info: PaginationInfo) {
        let query = filter(Self.query(on: database))
        let total = try await query.count()
        let totalPages = Int(ceil(Double(total) / Double(per)))
        
        let items = try await query
            .limit(per)
            .offset((page - 1) * per)
            .all()
        
        let info = PaginationInfo(
            currentPage: page,
            totalPages: totalPages,
            total: total,
            perPage: per,
            hasNextPage: page < totalPages,
            hasPreviousPage: page > 1
        )
        
        return (items: items, info: info)
    }
}
