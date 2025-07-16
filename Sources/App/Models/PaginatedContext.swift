import Vapor

struct PaginatedContext<T>: Encodable where T: Encodable {
    let items: T
    let pagination: PaginationInfo
    let filters: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case items, pagination, filters
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(items, forKey: .items)
        try container.encode(pagination, forKey: .pagination)
        // Convert filters dictionary to strings
        try container.encode(filters.mapValues { "\($0)" }, forKey: .filters)
    }
}
