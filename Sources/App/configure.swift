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
    
    // Add migrations
    app.migrations.add(CreateBooks())
    app.migrations.add(CreatePrakarans())
    app.migrations.add(CreateChaupais())
    app.migrations.add(CreateUsers())
    app.migrations.add(SeedData())
    app.migrations.add(SeedAdminUser())
    
    // Register middleware
    app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))
    
    // Register routes
    try routes(app)
}
