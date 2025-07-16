import Vapor

func routes(_ app: Application) throws {
    // Authentication routes (public)
    try app.register(collection: AuthController())
    
    // API Routes (public for now, can be protected later)
    let api = app.grouped("api", "v1")
    
    // Book routes
    try api.register(collection: BookController())
    
    // Prakaran routes
    try api.register(collection: PrakaranController())
    
    // Chaupai routes
    try api.register(collection: ChaupaiController())
    
    // Protected Admin routes
    let admin = app.grouped("admin").grouped(AuthMiddleware())
    try admin.register(collection: AdminController())
    
    // Root redirect to admin
    app.get { req in
        req.redirect(to: "/admin")
    }
}
