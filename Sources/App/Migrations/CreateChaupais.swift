import Fluent

struct CreateChaupais: AsyncMigration {
    func prepare(on database: Database) async throws {
        try await database.schema("chaupais")
            .field("chaupaiID", .int, .identifier(auto: false))
            .field("chaupaiNumber", .int, .required)
            .field("chaupaiName", .string, .required)
            .field("chaupaiMeaning", .string)
            .field("favourite", .bool, .required, .custom("DEFAULT 0 CHECK(favourite IN (0,1))"))
            .field("prakaranID", .int, .required, .references("prakarans", "prakaranID", onDelete: .cascade))
            .create()
    }
    
    func revert(on database: Database) async throws {
        try await database.schema("chaupais").delete()
    }
}
