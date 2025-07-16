import Fluent
import SQLKit
import Foundation

struct SeedData: AsyncMigration {
    func prepare(on database: Database) async throws {
        guard let sql = database as? SQLDatabase else {
            fatalError("Database must be SQL compatible")
        }
        
        // Read SQL file content
        let fileURL = URL(fileURLWithPath: #file)
            .deletingLastPathComponent() // Migrations directory
            .deletingLastPathComponent() // App directory
            .deletingLastPathComponent() // Sources directory
            .deletingLastPathComponent() // SPJIN directory
            .appendingPathComponent("Resources")
            .appendingPathComponent("seed.sql")
        
        let seedSQL = try String(contentsOf: fileURL, encoding: .utf8)
        
        // Split SQL into individual statements
        let statements = seedSQL
            .components(separatedBy: ";")
            .map { $0.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        
        // Execute each statement
        for statement in statements {
            try await sql.raw(SQLQueryString(statement)).run()
        }
    }

    func revert(on database: Database) async throws {
        // Remove seed data in reverse order to respect foreign key constraints
        try await Chaupai.query(on: database).delete()
        try await Prakaran.query(on: database).delete()
        try await Book.query(on: database).delete()
    }
}
