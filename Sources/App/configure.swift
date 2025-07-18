import Vapor
import Fluent
import FluentSQLiteDriver
import FluentPostgresDriver
import Leaf
import JWT

public func configure(_ app: Application) throws {
    // Configure database based on environment
    if let databaseURL = Environment.get("DATABASE_URL") {
        // Production: Use PostgreSQL
        try app.databases.use(.postgres(url: databaseURL), as: .psql)
    } else {
        // Development: Use SQLite
        app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    }
    
    // Configure Leaf templating
    app.views.use(.leaf)
    
    // Configure JWT with environment-based secret
    let jwtSecret = Environment.get("JWT_SECRET") ?? "secret-key"
    app.jwt.signers.use(.hs256(key: jwtSecret))
    
    // Configure file upload limits (allow up to 50MB for SQL imports)
    app.routes.defaultMaxBodySize = "50mb"
    
    // Configure sessions
    app.sessions.use(.memory)
    
    // Add migrations
    app.migrations.add(CreateBooks())
    app.migrations.add(CreatePrakarans())
    app.migrations.add(CreateChaupais())
    app.migrations.add(CreateUsers())
    app.migrations.add(SeedAdminUser())
    
    // Register middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    // Register routes
    try routes(app)
}
