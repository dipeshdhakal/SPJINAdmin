import Fluent
import Vapor

struct SeedAdminUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        let logger = database.logger
        
        // Check if admin user already exists
        let existingAdmin = try await User.query(on: database)
            .filter(\.$username == "spjin@adminuser.com")
            .first()
        
        guard existingAdmin == nil else {
            logger.debug("Admin user already exists, skipping creation")
            return
        }
        
        // Create default admin user
        let password = "SPj!n@Pass124" // Use a secure password
        let adminPasswordHash = try Bcrypt.hash(password)
        let adminUser = User(username: "spjin@adminuser.com", passwordHash: adminPasswordHash)
        try await adminUser.save(on: database)
    }
    
    func revert(on database: Database) async throws {
        try await User.query(on: database)
            .filter(\.$username == "admin")
            .delete()
    }
}
