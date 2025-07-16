import Fluent
import Vapor

struct SeedAdminUser: AsyncMigration {
    func prepare(on database: Database) async throws {
        let logger = database.logger
        logger.debug("Starting admin user seeding...")
        
        // Check if admin user already exists
        let existingAdmin = try await User.query(on: database)
            .filter(\.$username == "admin")
            .first()
        
        guard existingAdmin == nil else {
            logger.debug("Admin user already exists, skipping creation")
            return
        }
        
        // Create default admin user
        logger.debug("Creating new admin user...")
        let password = "admin123"
        let adminPasswordHash = try Bcrypt.hash(password)
        let adminUser = User(username: "admin", passwordHash: adminPasswordHash)
        try await adminUser.save(on: database)
        logger.debug("Admin user created successfully")
    }
    
    func revert(on database: Database) async throws {
        try await User.query(on: database)
            .filter(\.$username == "admin")
            .delete()
    }
}
