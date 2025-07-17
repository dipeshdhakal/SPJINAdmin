import Vapor
import Fluent

struct PrakaranListContext: Encodable {
    let prakarans: [Prakaran.Public]
    let books: [Book]
    let selectedBookID: Int?
    let search: String?
    let enableAddDelete: Bool
    let metadata: PageMetadata
}

struct PrakaranFormContext: Encodable {
    let prakaran: Prakaran?
    let books: [Book]
}

struct WebPrakaranController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
        routes.get("new", use: create)
        routes.post(use: store)
        routes.get(":id", "edit", use: edit)
        routes.post(":id", use: update)
        routes.post(":id", "delete", use: delete)
    }
    
    func index(req: Request) async throws -> View {
        let books = try await Book.query(on: req.db).all()
        
        var query = Prakaran.query(on: req.db)
            .with(\.$book)
        
        if let bookID = req.query[Int.self, at: "bookID"] {
            query = query.filter(\.$book.$id == bookID)
        }
        
        if let search = req.query[String.self, at: "search"] {
            query = query.group(.or) { group in
                group.filter(\.$prakaranName ~~ search)
                group.filter(\.$prakaranDetails ~~ search)
            }
        }
        
        let page = try await query.paginate(PageRequest(page: req.query[Int.self, at: "page"] ?? 1, per: 20))
        let prakarans = page.items
        
        let context = PrakaranListContext(
            prakarans: prakarans.map { Prakaran.Public(from: $0) },
            books: books,
            selectedBookID: req.query[Int.self, at: "bookID"],
            search: req.query[String.self, at: "search"],
            enableAddDelete: AdminConfig.enableAddDelete,
            metadata: page.metadata
        )
        
        return try await req.view.render("admin/prakarans/index", context)
    }
    
    func create(req: Request) async throws -> View {
        let books = try await Book.query(on: req.db).all()
        let context = PrakaranFormContext(prakaran: nil, books: books)
        return try await req.view.render("admin/prakarans/form", context)
    }
    
    func store(req: Request) async throws -> Response {
        let input = try req.content.decode(Prakaran.Create.self)
        
        guard let _ = try await Book.find(input.bookID, on: req.db) else {
            throw Abort(.badRequest, reason: "Book not found")
        }
        
        let maxID = try await Prakaran.query(on: req.db)
            .max(\.$id) ?? -1
        
        let prakaran = Prakaran(
            id: maxID + 1,
            prakaranOrder: input.prakaranOrder,
            prakaranName: input.prakaranName,
            prakaranDetails: input.prakaranDetails,
            bookID: input.bookID
        )
        
        try await prakaran.save(on: req.db)
        return req.redirect(to: "/admin/prakarans")
    }
    
    func edit(req: Request) async throws -> View {
        guard let id = req.parameters.get("id", as: Int.self),
              let prakaran = try await Prakaran.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let books = try await Book.query(on: req.db).all()
        let context = PrakaranFormContext(prakaran: prakaran, books: books)
        return try await req.view.render("admin/prakarans/form", context)
    }
    
    func update(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: Int.self),
              let prakaran = try await Prakaran.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let input = try req.content.decode(Prakaran.Update.self)
        
        if let prakaranOrder = input.prakaranOrder {
            prakaran.prakaranOrder = prakaranOrder
        }
        if let prakaranName = input.prakaranName {
            prakaran.prakaranName = prakaranName
        }
        if let prakaranDetails = input.prakaranDetails {
            prakaran.prakaranDetails = prakaranDetails
        }
        if let bookID = input.bookID {
            prakaran.$book.id = bookID
        }
        
        try await prakaran.save(on: req.db)
        return req.redirect(to: "/admin/prakarans")
    }
    
    func delete(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: Int.self),
              let prakaran = try await Prakaran.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await prakaran.delete(on: req.db)
        return req.redirect(to: "/admin/prakarans")
    }
}
