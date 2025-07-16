import Vapor

func routes(_ app: Application) throws {
    // API Routes
    let api = app.grouped("api", "v1")
    
    // Book routes
    try api.register(collection: BookController())
    
    // Prakaran routes
    try api.register(collection: PrakaranController())
    
    // Chaupai routes
    try api.register(collection: ChaupaiController())
    
    // Admin routes
    let admin = app.grouped("admin")
    try admin.register(collection: AdminController())
    
    // Root redirect to admin
    app.get { req in
        req.redirect(to: "/admin")
    }
}
