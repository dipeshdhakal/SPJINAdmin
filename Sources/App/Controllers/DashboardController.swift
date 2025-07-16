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
        async let favouriteChaupaisCount = Chaupai.query(on: req.db)
            .filter(\.$favourite == true)
            .count()
        
        // Get recent chaupais
        async let recentChaupais = Chaupai.query(on: req.db)
            .with(\.$prakaran) { prakaran in
                prakaran.with(\.$book)
            }
            .sort(\.$id, .descending)
            .limit(5)
            .all()
        
        // Wait for all async operations
        let (books, prakarans, chaupais, favourites, recent) = try await (
            booksCount,
            prakaransCount,
            chaupaisCount,
            favouriteChaupaisCount,
            recentChaupais
        )
        
        struct DashboardContext: Encodable {
            struct Stats: Encodable {
                let books: Int
                let prakarans: Int
                let chaupais: Int
                let favourites: Int
            }
            let stats: Stats
            let recentChaupais: [Chaupai.Public]
        }
        
        let context = DashboardContext(
            stats: .init(
                books: books,
                prakarans: prakarans,
                chaupais: chaupais,
                favourites: favourites
            ),
            recentChaupais: recent.map { Chaupai.Public(from: $0) }
        )
        return try await req.view.render("admin/dashboard", context)
    }
}
