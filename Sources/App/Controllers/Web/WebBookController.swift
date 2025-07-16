import Vapor
import Fluent

struct BookListContext: Encodable {
    let books: [Book.Public]
    let enableAddDelete: Bool
    let metadata: PageMetadata
}

struct BookFormContext: Encodable {
    let book: Book?
}

struct WebBookController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: index)
        routes.get("new", use: create)
        routes.post(use: store)
        routes.get(":id", "edit", use: edit)
        routes.post(":id", use: update)
        routes.post(":id", "delete", use: delete)
    }
    
    func index(req: Request) async throws -> View {
        let page = try await Book.query(on: req.db)
            .with(\.$prakarans)
            .paginate(for: req)
            
        let books = page.items
        
        let context = BookListContext(
            books: books.map { Book.Public(from: $0, prakaranCount: $0.prakarans.count) },
            enableAddDelete: AdminConfig.enableAddDelete,
            metadata: page.metadata
        )
        
        return try await req.view.render("admin/books/index", context)
    }
    
    func create(req: Request) async throws -> View {
        let context = BookFormContext(book: nil)
        return try await req.view.render("admin/books/form", context)
    }
    
    func store(req: Request) async throws -> Response {
        let input = try req.content.decode(Book.Create.self)
        
        let maxID = try await Book.query(on: req.db)
            .max(\.$id) ?? -1
        
        let book = Book(
            id: maxID + 1,
            bookOrder: input.bookOrder,
            bookName: input.bookName
        )
        
        try await book.save(on: req.db)
        return req.redirect(to: "/admin/books")
    }
    
    func edit(req: Request) async throws -> View {
        guard let id = req.parameters.get("id", as: Int.self),
              let book = try await Book.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let context = BookFormContext(book: book)
        return try await req.view.render("admin/books/form", context)
    }
    
    func update(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: Int.self),
              let book = try await Book.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let input = try req.content.decode(Book.Update.self)
        
        if let bookOrder = input.bookOrder {
            book.bookOrder = bookOrder
        }
        if let bookName = input.bookName {
            book.bookName = bookName
        }
        
        try await book.save(on: req.db)
        return req.redirect(to: "/admin/books")
    }
    
    func delete(req: Request) async throws -> Response {
        guard let id = req.parameters.get("id", as: Int.self),
              let book = try await Book.find(id, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await book.delete(on: req.db)
        return req.redirect(to: "/admin/books")
    }
}
