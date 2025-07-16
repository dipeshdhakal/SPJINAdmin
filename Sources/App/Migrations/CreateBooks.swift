import Fluent

struct CreateBooks: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("books")
            .field("bookID", .int, .identifier(auto: false))
            .field("bookOrder", .int, .required)
            .field("bookName", .string, .required)
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("books").delete()
    }
}
