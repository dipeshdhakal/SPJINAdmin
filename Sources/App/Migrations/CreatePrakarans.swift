import Fluent

struct CreatePrakarans: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("prakarans")
            .field("prakaranID", .int, .identifier(auto: false))
            .field("prakaranOrder", .int, .required)
            .field("prakaranName", .string, .required)
            .field("prakaranDetails", .string)
            .field("bookID", .int, .required, .references("books", "bookID", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("prakarans").delete()
    }
}
