import Fluent

struct CreateChaupais: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("chaupais")
            .field("chaupaiID", .int, .identifier(auto: false))
            .field("chaupaiNumber", .int, .required)
            .field("chaupaiName", .string, .required)
            .field("chaupaiMeaning", .string)
            .field("prakaranID", .int, .required, .references("prakarans", "prakaranID", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("chaupais").delete()
    }
}
