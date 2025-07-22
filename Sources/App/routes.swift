import Vapor
import Fluent

func routes(_ app: Application) throws {
    // Health check endpoint (public)
    app.get("health") { req async throws in
        return [
            "status": "healthy",
            "timestamp": String(Date().timeIntervalSince1970),
            "version": "1.0.0"
        ]
    }
    
    // Authentication routes (public)
    try app.register(collection: AuthController())
    
    // API Routes (public for now, can be protected later)
    let api = app.grouped("api", "v1")
    
    // API Routes - public endpoints
    try api.register(collection: APIBookController())
    try api.register(collection: APIPrakaranController())
    try api.register(collection: APIChaupaiController())
    
    // Protected Admin routes - all admin functionality requires authentication
    let adminAuth = app.grouped(AuthMiddleware())
    let admin = adminAuth.grouped("admin")

    // Admin web routes
    try admin.register(collection: DashboardController())
    try admin.grouped("books").register(collection: WebBookController())
    try admin.grouped("prakarans").register(collection: WebPrakaranController())
    try admin.grouped("chaupais").register(collection: WebChaupaiController())
    try admin.register(collection: ExportController())
    
    // Root redirect to admin dashboard (also protected)
    app.grouped(AuthMiddleware()).get { req in
        req.redirect(to: "/admin/dashboard")
    }
}
