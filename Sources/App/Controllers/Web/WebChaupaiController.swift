import Vapor
import Fluent

struct ChaupaiListContext: Encodable {
    let chaupais: [Chaupai.Public]
    let books: [Book.Public]
    let prakarans: [Prakaran.Public]
    let selectedBookID: Int?
    let selectedPrakaranID: Int?
    let search: String?
    let enableAddDelete: Bool
    let metadata: PaginationMetadata
}

struct PaginationMetadata: Encodable {
    let page: Int
    let per: Int
    let total: Int
    let totalPages: Int
    
    init(from pageMetadata: PageMetadata) {
        self.page = pageMetadata.page
        self.per = pageMetadata.per
        self.total = pageMetadata.total
        self.totalPages = (pageMetadata.total + pageMetadata.per - 1) / pageMetadata.per
    }
}

struct ChaupaiFormContext: Encodable {
    let chaupai: Chaupai?
    let prakarans: [Prakaran.Public]
}

struct WebChaupaiController: RouteCollection {
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
        
        // Always fetch all prakarans for frontend filtering
        let allPrakarans = try await Prakaran.query(on: req.db)
            .with(\.$book)
            .sort(\Prakaran.$book.$id)
            .sort(\Prakaran.$prakaranOrder)
            .all()
        
        var query = Chaupai.query(on: req.db)
            .with(\.$prakaran) { prakaran in
                prakaran.with(\.$book)
            }
            .join(Prakaran.self, on: \Chaupai.$prakaran.$id == \Prakaran.$id)
            .join(Book.self, on: \Prakaran.$book.$id == \Book.$id)
            .sort(Book.self, \.$id)
            .sort(Prakaran.self, \.$prakaranOrder)
            .sort(\.$chaupaiNumber)
        
        if let bookID = req.query[Int.self, at: "bookID"] {
            query = query.filter(Book.self, \.$id == bookID)
        }
        
        if let prakaranID = req.query[Int.self, at: "prakaranID"] {
            query = query.filter(\.$prakaran.$id == prakaranID)
        }
        
        if let search = req.query[String.self, at: "search"] {
            query = query.group(.or) { group in
                group.filter(\.$chaupaiName ~~ search)
            }
        }
        
        let page = try await query.paginate(PageRequest(page: req.query[Int.self, at: "page"] ?? 1, per: 20))
        let chaupais = page.items
        
        let context = ChaupaiListContext(
            chaupais: chaupais.map { Chaupai.Public(from: $0) },
            books: books.map { Book.Public(from: $0) },
            prakarans: allPrakarans.map { Prakaran.Public(from: $0) },
            selectedBookID: req.query[Int.self, at: "bookID"],
            selectedPrakaranID: req.query[Int.self, at: "prakaranID"],
            search: req.query[String.self, at: "search"],
            enableAddDelete: AdminConfig.enableAddDelete,
            metadata: PaginationMetadata(from: page.metadata)
        )
        
        return try await req.view.render("admin/chaupais/index", context)
    }
    
    func create(req: Request) async throws -> View {
        let prakarans = try await Prakaran.query(on: req.db)
            .with(\.$book)
            .all()
        
        let context = ChaupaiFormContext(
            chaupai: nil,
            prakarans: prakarans.map { Prakaran.Public(from: $0) }
        )
        
        return try await req.view.render("admin/chaupais/form", context)
    }
    
    func store(req: Request) async throws -> Response {
        let input = try req.content.decode(Chaupai.Create.self)
        
        guard let _ = try await Prakaran.find(input.prakaranID, on: req.db) else {
            throw Abort(.badRequest, reason: "Prakaran not found")
        }
        
        let maxID = try await Chaupai.query(on: req.db)
            .max(\.$id) ?? -1
        
        let chaupai = Chaupai(
            id: maxID + 1,
            chaupaiNumber: input.chaupaiNumber,
            chaupaiName: input.chaupaiName,
            chaupaiMeaning: input.chaupaiMeaning,
            prakaranID: input.prakaranID
        )
        
        try await chaupai.save(on: req.db)
        return req.redirect(to: "/admin/chaupais")
    }
    
    func edit(req: Request) async throws -> View {
        guard let id = req.parameters.get("id", as: Int.self),
              let chaupai = try await Chaupai.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let prakarans = try await Prakaran.query(on: req.db)
            .with(\.$book)
            .all()
        
        let context = ChaupaiFormContext(
            chaupai: chaupai,
            prakarans: prakarans.map { Prakaran.Public(from: $0) }
        )
        
        return try await req.view.render("admin/chaupais/form", context)
    }
    
    func update(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: Int.self),
              let chaupai = try await Chaupai.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let input = try req.content.decode(Chaupai.Update.self)
        
        if let chaupaiNumber = input.chaupaiNumber {
            chaupai.chaupaiNumber = chaupaiNumber
        }
        if let chaupaiName = input.chaupaiName {
            chaupai.chaupaiName = chaupaiName
        }
        if let chaupaiMeaning = input.chaupaiMeaning {
            chaupai.chaupaiMeaning = chaupaiMeaning
        }
        if let prakaranID = input.prakaranID {
            chaupai.$prakaran.id = prakaranID
        }
        
        try await chaupai.save(on: req.db)
        return req.redirect(to: "/admin/chaupais")
    }
    
    func delete(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: Int.self),
              let chaupai = try await Chaupai.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await chaupai.delete(on: req.db)
        return req.redirect(to: "/admin/chaupais")
    }
}
