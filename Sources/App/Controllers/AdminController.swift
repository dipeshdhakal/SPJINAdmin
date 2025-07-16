import Vapor
import Fluent
import Leaf

struct AdminController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        routes.get(use: dashboard)
        
        // Books
        routes.get("books", use: booksIndex)
        routes.get("books", "new", use: bookForm)
        routes.get("books", ":bookID", "edit", use: bookForm)  // Reuse same form handler
        routes.post("books", use: bookCreate)
        routes.post("books", ":bookID", use: bookUpdate)
        routes.post("books", ":bookID", "delete", use: bookDelete)
        
        // Prakarans
        routes.get("prakarans", use: prakaransIndex)
        routes.get("prakarans", "new", use: prakaranForm)
        routes.get("prakarans", ":prakaranID", "edit", use: prakaranForm)  // Reuse same form handler
        routes.post("prakarans", use: prakaranCreate)
        routes.post("prakarans", ":prakaranID", use: prakaranUpdate)
        routes.post("prakarans", ":prakaranID", "delete", use: prakaranDelete)
        
        // Chaupais
        routes.get("chaupais", use: chaupaisIndex)
        routes.get("chaupais", "new", use: chaupaiForm)
        routes.get("chaupais", ":chaupaiID", "edit", use: chaupaiForm)  // Reuse same form handler
        routes.post("chaupais", use: chaupaiCreate)
        routes.post("chaupais", ":chaupaiID", use: chaupaiUpdate)
        routes.post("chaupais", ":chaupaiID", "delete", use: chaupaiDelete)
    }
    
    // MARK: - Dashboard
    func dashboard(req: Request) async throws -> View {
        let bookCount = try await Book.query(on: req.db).count()
        let prakaranCount = try await Prakaran.query(on: req.db).count()
        let chaupaiCount = try await Chaupai.query(on: req.db).count()
        let favouriteCount = try await Chaupai.query(on: req.db).filter(\.$favourite == true).count()
        
        let context = DashboardContext(
            bookCount: bookCount,
            prakaranCount: prakaranCount,
            chaupaiCount: chaupaiCount,
            favouriteCount: favouriteCount
        )
        
        return try await req.view.render("dashboard", context)
    }
    
    // MARK: - Books
    func booksIndex(req: Request) async throws -> View {
        var query = Book.query(on: req.db).with(\.$prakarans)
        
        if let search = req.query[String.self, at: "search"] {
            query = query.filter(\.$bookName ~~ search)
        }
        
        let books = try await query.sort(\.$bookOrder).all()
        let booksData = books.map { book in
            BookData(from: book, prakaranCount: book.prakarans.count)
        }
        
        let context = BooksIndexContext(
            books: booksData,
            search: req.query[String.self, at: "search"]
        )
        
        return try await req.view.render("books/index", context)
    }
    
    func bookForm(req: Request) async throws -> View {
        let book: Book?
        if let bookID = req.parameters.get("bookID", as: Int.self),
           bookID > 0 {
            book = try await Book.find(bookID, on: req.db)
        } else {
            book = nil
        }
        
        let context = BookFormContext(
            book: book.map { BookData(from: $0) }
        )
        
        return try await req.view.render("books/form", context)
    }
    
    func bookCreate(req: Request) async throws -> Response {
        let formData = try req.content.decode(BookFormData.self)
        
        let maxID = try await Book.query(on: req.db).max(\.$id) ?? -1
        let book = Book(
            id: maxID + 1,
            bookOrder: formData.bookOrder,
            bookName: formData.bookName
        )
        
        try await book.save(on: req.db)
        return req.redirect(to: "/admin/books")
    }
    
    func bookUpdate(req: Request) async throws -> Response {
        guard let bookID = req.parameters.get("bookID", as: Int.self),
              let book = try await Book.find(bookID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let formData = try req.content.decode(BookFormData.self)
        book.bookOrder = formData.bookOrder
        book.bookName = formData.bookName
        
        try await book.save(on: req.db)
        return req.redirect(to: "/admin/books")
    }
    
    func bookDelete(req: Request) async throws -> Response {
        guard let bookID = req.parameters.get("bookID", as: Int.self),
              let book = try await Book.find(bookID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await book.delete(on: req.db)
        return req.redirect(to: "/admin/books")
    }
    
    // MARK: - Prakarans
    func prakaransIndex(req: Request) async throws -> View {
        var query = Prakaran.query(on: req.db).with(\.$book).with(\.$chaupais)
        
        if let bookID = req.query[Int.self, at: "bookID"] {
            query = query.filter(\.$book.$id == bookID)
        }
        
        if let search = req.query[String.self, at: "search"] {
            query = query.group(.or) { group in
                group.filter(\.$prakaranName ~~ search)
                group.filter(\.$prakaranDetails ~~ search)
            }
        }
        
        let prakarans = try await query.sort(\.$prakaranOrder).all()
        let books = try await Book.query(on: req.db).sort(\.$bookOrder).all()
        
        let prakaransData = prakarans.map { prakaran in
            PrakaranData(from: prakaran, chaupaiCount: prakaran.chaupais.count)
        }
        
        let context: PrakaransIndexContext = PrakaransIndexContext(
            prakarans: prakaransData,
            books: books.map { BookData(from: $0) },
            selectedBookID: req.query[Int.self, at: "bookID"],
            search: req.query[String.self, at: "search"]
        )
        
        return try await req.view.render("prakarans/index", context)
    }
    
    func prakaranForm(req: Request) async throws -> View {
        let prakaran: Prakaran?
        if let prakaranID = req.parameters.get("prakaranID", as: Int.self) {
            prakaran = try await Prakaran.query(on: req.db)
                .filter(\.$id == prakaranID)
                .with(\.$book)
                .first()
        } else {
            prakaran = nil
        }
        
        let books = try await Book.query(on: req.db).sort(\.$bookOrder).all()
        return try await req.view.render("prakarans/form", PrakaranFormContext(
            prakaran: prakaran.map { PrakaranData(from: $0) },
            books: books.map { BookData(from: $0) }
        ))
    }
    
    func prakaranCreate(req: Request) async throws -> Response {
        let formData = try req.content.decode(PrakaranFormData.self)
        
        let maxID = try await Prakaran.query(on: req.db).max(\.$id) ?? -1
        let prakaran = Prakaran(
            id: maxID + 1,
            prakaranOrder: formData.prakaranOrder,
            prakaranName: formData.prakaranName,
            prakaranDetails: formData.prakaranDetails.isEmpty ? nil : formData.prakaranDetails,
            bookID: formData.bookID
        )
        
        try await prakaran.save(on: req.db)
        return req.redirect(to: "/admin/prakarans")
    }
    
    func prakaranEditForm(req: Request) async throws -> View {
        // Get the prakaran ID from the URL parameters
        guard let prakaranID = req.parameters.get("prakaranID", as: Int.self) else {
            throw Abort(.badRequest, reason: "Invalid prakaran ID")
        }
        
        // Fetch the prakaran with its book
        guard prakaranID > 0,
              let prakaran = try await Prakaran.query(on: req.db)
                .filter(\.$id == prakaranID)
                .with(\.$book)
                .first() else {
            // If prakaran is not found or ID is 0, redirect to the new prakaran form
            let books = try await Book.query(on: req.db).sort(\.$bookOrder).all()
            let context = PrakaranFormContext(books: books.map { BookData(from: $0) })
            return try await req.view.render("prakarans/form", context)
        }
        
        // Fetch all books for the form's select dropdown
        let books = try await Book.query(on: req.db).sort(\.$bookOrder).all()
        
        // Create the context with the prakaran and books
        let context = PrakaranFormContext(
            prakaran: PrakaranData(from: prakaran),
            books: books.map { BookData(from: $0) }
        )
        
        // Render the form view
        return try await req.view.render("prakarans/form", context)
    }
    
    func prakaranUpdate(req: Request) async throws -> Response {
        guard let prakaranID = req.parameters.get("prakaranID", as: Int.self),
              let prakaran = try await Prakaran.find(prakaranID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let formData = try req.content.decode(PrakaranFormData.self)
        prakaran.prakaranOrder = formData.prakaranOrder
        prakaran.prakaranName = formData.prakaranName
        prakaran.prakaranDetails = formData.prakaranDetails.isEmpty ? nil : formData.prakaranDetails
        prakaran.$book.id = formData.bookID
        
        try await prakaran.save(on: req.db)
        return req.redirect(to: "/admin/prakarans")
    }
    
    func prakaranDelete(req: Request) async throws -> Response {
        guard let prakaranID = req.parameters.get("prakaranID", as: Int.self),
              let prakaran = try await Prakaran.find(prakaranID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await prakaran.delete(on: req.db)
        return req.redirect(to: "/admin/prakarans")
    }
    
    // MARK: - Chaupais
    func chaupaisIndex(req: Request) async throws -> View {
        var query = Chaupai.query(on: req.db)
            .join(Prakaran.self, on: \Chaupai.$prakaran.$id == \Prakaran.$id)
            .join(Book.self, on: \Prakaran.$book.$id == \Book.$id)
            .with(\.$prakaran) { prakaran in
                prakaran.with(\.$book)
            }
        
        if let prakaranID = req.query[Int.self, at: "prakaranID"] {
            query = query.filter(\.$prakaran.$id == prakaranID)
        }
        
        if let bookID = req.query[Int.self, at: "bookID"] {
            query = query.filter(Prakaran.self, \.$book.$id == bookID)
        }
        
        if let favourite = req.query[Bool.self, at: "favourite"] {
            query = query.filter(\.$favourite == favourite)
        }
        
        if let search = req.query[String.self, at: "search"] {
            query = query.group(.or) { group in
                group.filter(\.$chaupaiName ~~ search)
                group.filter(\.$chaupaiMeaning ~~ search)
            }
        }
        
        let chaupais = try await query.sort(\.$chaupaiNumber).all()
        let books = try await Book.query(on: req.db).sort(\.$bookOrder).all()
        let prakarans = try await Prakaran.query(on: req.db).with(\.$book).sort(\.$prakaranOrder).all()
        
        let context: ChaupaisIndexContext = ChaupaisIndexContext(
            chaupais: chaupais.map { ChaupaiData(from: $0) },
            books: books.map { BookData(from: $0) },
            prakarans: prakarans.map { PrakaranData(from: $0) },
            selectedBookID: req.query[Int.self, at: "bookID"],
            selectedPrakaranID: req.query[Int.self, at: "prakaranID"],
            selectedFavourite: req.query[Bool.self, at: "favourite"],
            search: req.query[String.self, at: "search"]
        )
        
        return try await req.view.render("chaupais/index", context)
    }
    
    func chaupaiForm(req: Request) async throws -> View {
        let chaupai: Chaupai?
        if let chaupaiID = req.parameters.get("chaupaiID", as: Int.self) {
            chaupai = try await Chaupai.query(on: req.db)
                .filter(\.$id == chaupaiID)
                .with(\.$prakaran) { prakaran in
                    prakaran.with(\.$book)
                }
                .first()
        } else {
            chaupai = nil
        }
        
        let books = try await Book.query(on: req.db).sort(\.$bookOrder).all()
        let prakarans = try await Prakaran.query(on: req.db).with(\.$book).sort(\.$prakaranOrder).all()
            
        return try await req.view.render("chaupais/form", ChaupaiFormContext(
            chaupai: chaupai.map { ChaupaiData(from: $0) },
            books: books.map { BookData(from: $0) },
            prakarans: prakarans.map { PrakaranData(from: $0) }
        ))
    }
    
    func chaupaiCreate(req: Request) async throws -> Response {
        let formData = try req.content.decode(ChaupaiFormData.self)
        
        let maxID = try await Chaupai.query(on: req.db).max(\.$id) ?? -1
        let chaupai = Chaupai(
            id: maxID + 1,
            chaupaiNumber: formData.chaupaiNumber,
            chaupaiName: formData.chaupaiName,
            chaupaiMeaning: formData.chaupaiMeaning.isEmpty ? nil : formData.chaupaiMeaning,
            favourite: formData.favourite,
            prakaranID: formData.prakaranID
        )
        
        try await chaupai.save(on: req.db)
        return req.redirect(to: "/admin/chaupais")
    }
    
    func chaupaiEditForm(req: Request) async throws -> View {
        guard let chaupaiID = req.parameters.get("chaupaiID", as: Int.self) else {
            throw Abort(.badRequest)
        }
        
        let chaupai = try await Chaupai.query(on: req.db)
            .filter(\.$id == chaupaiID)
            .with(\.$prakaran) { prakaran in
                prakaran.with(\.$book)
            }
            .first()
        
        guard let chaupai = chaupai else {
            throw Abort(.notFound)
        }
        
        let books = try await Book.query(on: req.db).sort(\.$bookOrder).all()
        let prakarans = try await Prakaran.query(on: req.db).with(\.$book).sort(\.$prakaranOrder).all()
        
        let context: ChaupaiFormContext = ChaupaiFormContext(
            chaupai: ChaupaiData(from: chaupai),
            books: books.map { BookData(from: $0) },
            prakarans: prakarans.map { PrakaranData(from: $0) }
        )
        return try await req.view.render("chaupais/form", context)
    }
    
    func chaupaiUpdate(req: Request) async throws -> Response {
        guard let chaupaiID = req.parameters.get("chaupaiID", as: Int.self),
              let chaupai = try await Chaupai.find(chaupaiID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        let formData = try req.content.decode(ChaupaiFormData.self)
        chaupai.chaupaiNumber = formData.chaupaiNumber
        chaupai.chaupaiName = formData.chaupaiName
        chaupai.chaupaiMeaning = formData.chaupaiMeaning.isEmpty ? nil : formData.chaupaiMeaning
        chaupai.favourite = formData.favourite
        chaupai.$prakaran.id = formData.prakaranID
        
        try await chaupai.save(on: req.db)
        return req.redirect(to: "/admin/chaupais")
    }
    
    func chaupaiDelete(req: Request) async throws -> Response {
        guard let chaupaiID = req.parameters.get("chaupaiID", as: Int.self),
              let chaupai = try await Chaupai.find(chaupaiID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await chaupai.delete(on: req.db)
        return req.redirect(to: "/admin/chaupais")
    }
}

// MARK: - Context Structs
struct DashboardContext: Codable {
    let bookCount: Int
    let prakaranCount: Int
    let chaupaiCount: Int
    let favouriteCount: Int
}

struct BookData: Codable {
    let bookID: Int
    let bookOrder: Int
    let bookName: String
    let prakaranCount: Int?
    
    init(from book: Book, prakaranCount: Int? = nil) {
        self.bookID = book.id!
        self.bookOrder = book.bookOrder
        self.bookName = book.bookName
        self.prakaranCount = prakaranCount
    }
}

struct PrakaranData: Codable {
    let prakaranID: Int
    let prakaranOrder: Int
    let prakaranName: String
    let prakaranDetails: String?
    let bookID: Int
    let bookName: String?
    let chaupaiCount: Int?
    
    init(from prakaran: Prakaran, chaupaiCount: Int? = nil) {
        self.prakaranID = prakaran.id!
        self.prakaranOrder = prakaran.prakaranOrder
        self.prakaranName = prakaran.prakaranName
        self.prakaranDetails = prakaran.prakaranDetails
        self.bookID = prakaran.$book.id
        self.bookName = prakaran.book.bookName
        self.chaupaiCount = chaupaiCount
    }
}

struct ChaupaiData: Codable {
    let chaupaiID: Int
    let chaupaiNumber: Int
    let chaupaiName: String
    let chaupaiMeaning: String?
    let favourite: Bool
    let prakaranID: Int
    let prakaranName: String?
    let bookName: String?
    
    init(from chaupai: Chaupai) {
        self.chaupaiID = chaupai.id!
        self.chaupaiNumber = chaupai.chaupaiNumber
        self.chaupaiName = chaupai.chaupaiName
        self.chaupaiMeaning = chaupai.chaupaiMeaning
        self.favourite = chaupai.favourite
        self.prakaranID = chaupai.$prakaran.id
        self.prakaranName = chaupai.prakaran.prakaranName
        self.bookName = chaupai.prakaran.book.bookName
    }
}

struct BooksIndexContext: Codable {
    let books: [BookData]
    let search: String?
}

struct BookFormContext: Codable {
    let book: BookData?
    
    init(book: BookData? = nil) {
        self.book = book
    }
}

struct BookFormData: Content {
    let bookOrder: Int
    let bookName: String
}

struct PrakaransIndexContext: Codable {
    let prakarans: [PrakaranData]
    let books: [BookData]
    let selectedBookID: Int?
    let search: String?
}

struct PrakaranFormContext: Codable {
    let prakaran: PrakaranData?
    let books: [BookData]
    
    init(prakaran: PrakaranData? = nil, books: [BookData]) {
        self.prakaran = prakaran
        self.books = books
    }
}

struct PrakaranFormData: Content {
    let prakaranOrder: Int
    let prakaranName: String
    let prakaranDetails: String
    let bookID: Int
}

struct ChaupaisIndexContext: Codable {
    let chaupais: [ChaupaiData]
    let books: [BookData]
    let prakarans: [PrakaranData]
    let selectedBookID: Int?
    let selectedPrakaranID: Int?
    let selectedFavourite: Bool?
    let search: String?
}

struct ChaupaiFormContext: Codable {
    let chaupai: ChaupaiData?
    let books: [BookData]
    let prakarans: [PrakaranData]
    
    init(chaupai: ChaupaiData? = nil, books: [BookData], prakarans: [PrakaranData]) {
        self.chaupai = chaupai
        self.books = books
        self.prakarans = prakarans
    }
}

struct ChaupaiFormData: Content {
    let chaupaiNumber: Int
    let chaupaiName: String
    let chaupaiMeaning: String
    let favourite: Bool
    let prakaranID: Int
}
