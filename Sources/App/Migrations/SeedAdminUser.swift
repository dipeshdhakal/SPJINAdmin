import Fluent
import Vapor

struct SeedAdminUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Check if admin user already exists
        let existingAdmin = try await User.query(on: database)
            .filter(\.$username == "admin")
            .first()
        
        guard existingAdmin == nil else {
            return // Admin user already exists
        }
        
        // Create default admin user
        let adminPasswordHash = try Bcrypt.hash("admin123")
        let adminUser = User(username: "admin", passwordHash: adminPasswordHash)
        try await adminUser.save(on: database)
    }
    
    func revert(on database: Database) async throws {
        try await User.query(on: database)
            .filter(\.$username == "admin")
            .delete()
    }
}
