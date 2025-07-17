import Vapor
import Fluent
import FluentSQLiteDriver
import Leaf
import JWT

public func configure(_ app: Application) throws {
    // Configure SQLite database
    app.databases.use(.sqlite(.file("db.sqlite")), as: .sqlite)
    
    // Configure Leaf templating
    app.views.use(.leaf)
    
    // Configure JWT
    app.jwt.signers.use(.hs256(key: "secret-key"))
    
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
    // app.migrations.add(SeedData())
    
    // Register middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    app.middleware.use(app.sessions.middleware)
    
    // Register routes
    try routes(app)
}
