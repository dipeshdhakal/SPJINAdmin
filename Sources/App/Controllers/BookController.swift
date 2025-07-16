import Vapor
import Fluent

struct BookController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let books = routes.grouped("books")
        
        books.get(use: index)
        books.get(":bookID", use: show)
        books.post(use: create)
        books.put(":bookID", use: update)
        books.delete(":bookID", use: delete)
        
        // Get prakarans for a book
        books.get(":bookID", "prakarans", use: getPrakarans)
        
        // Get chaupais for a book (with filtering)
        books.get(":bookID", "chaupais", use: getChaupais)
    }
    
    func index(req: Request) async throws -> [Book.Public] {
        let books = try await Book.query(on: req.db)
            .with(\.$prakarans)
            .all()
        
        return books.map { book in
            Book.Public(from: book, prakaranCount: book.prakarans.count)
        }
    }
    
    func show(req: Request) async throws -> Book.Public {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await book.$prakarans.load(on: req.db)
        return Book.Public(from: book, prakaranCount: book.prakarans.count)
    }
    
    func create(req: Request) async throws -> Book.Public {
        try Book.Create.validate(content: req)
        let create = try req.content.decode(Book.Create.self)
        
        // Find next available ID
        let maxID = try await Book.query(on: req.db)
            .max(\.$id) ?? -1
        
        let book = Book(
            id: maxID + 1,
            bookOrder: create.bookOrder,
            bookName: create.bookName
        )
        
        try await book.save(on: req.db)
        return Book.Public(from: book)
    }
    
    func update(req: Request) async throws -> Book.Public {
        try Book.Update.validate(content: req)
        let update = try req.content.decode(Book.Update.self)
        
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        if let bookOrder = update.bookOrder {
            book.bookOrder = bookOrder
        }
        if let bookName = update.bookName {
            book.bookName = bookName
        }
        
        try await book.save(on: req.db)
        return Book.Public(from: book)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await book.delete(on: req.db)
        return .noContent
    }
    
    func getPrakarans(req: Request) async throws -> [Prakaran.Public] {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        let prakarans = try await book.$prakarans.query(on: req.db)
            .with(\.$chaupais)
            .sort(\.$prakaranOrder)
            .all()
        
        return prakarans.map { prakaran in
            Prakaran.Public(from: prakaran, chaupaiCount: prakaran.chaupais.count)
        }
    }
    
    func getChaupais(req: Request) async throws -> [Chaupai.Public] {
        guard let book = try await Book.find(req.parameters.get("bookID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        var query = Chaupai.query(on: req.db)
            .join(Prakaran.self, on: \Chaupai.$prakaran.$id == \Prakaran.$id)
            .filter(Prakaran.self, \.$book.$id == book.id!)
        
        // Apply filters
        if let favourite = req.query[Bool.self, at: "favourite"] {
            query = query.filter(\.$favourite == favourite)
        }
        
        if let search = req.query[String.self, at: "search"] {
            query = query.group(.or) { group in
                group.filter(\.$chaupaiName ~~ search)
                if let meaning = req.query[String.self, at: "searchMeaning"], meaning.lowercased() == "true" {
                    group.filter(\.$chaupaiMeaning ~~ search)
                }
            }
        }
        
        let chaupais = try await query
            .sort(\.$chaupaiNumber)
            .all()
        
        return chaupais.map(Chaupai.Public.init)
    }
}
