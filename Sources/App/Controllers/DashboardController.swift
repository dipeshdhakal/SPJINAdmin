import Vapor
import Fluent

struct DashboardController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get("dashboard", use: index)
    }
    
    func index(req: Request) async throws -> View {
        // Get counts for various entities
        async let booksCount = Book.query(on: req.db).count()
        async let prakaransCount = Prakaran.query(on: req.db).count()
        async let chaupaisCount = Chaupai.query(on: req.db).count()
        
        // Wait for all async operations
        let (books, prakarans, chaupais) = try await (
            booksCount,
            prakaransCount,
            chaupaisCount
        )
        
        struct DashboardContext: Encodable {
            struct Stats: Encodable {
                let books: Int
                let prakarans: Int
                let chaupais: Int
            }
            let stats: Stats
            let success: String?
            let error: String?
        }
        
        // Get and clear session messages
        let successMessage = req.session.data["success"]
        let errorMessage = req.session.data["error"]
        req.session.data["success"] = nil
        req.session.data["error"] = nil
        
        let context = DashboardContext(
            stats: .init(
                books: books,
                prakarans: prakarans,
                chaupais: chaupais
            ),
            success: successMessage,
            error: errorMessage
        )
        return try await req.view.render("admin/dashboard", context)
    }
}
