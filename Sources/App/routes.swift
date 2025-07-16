import Vapor

func routes(_ app: Application) throws {
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
    try admin.register(collection: WebBookController())
    try admin.register(collection: WebPrakaranController())
    try admin.register(collection: WebChaupaiController())
    
    // Root redirect to admin dashboard (also protected)
    app.grouped(AuthMiddleware()).get { req in
        req.redirect(to: "/admin/dashboard")
    }
}
