import Vapor
import Fluent

final class Book: Model, Content {
    static let schema = "books"
    
    @ID(custom: "bookID", generatedBy: .user)
    var id: Int?
    
    @Field(key: "bookOrder")
    var bookOrder: Int
    
    @Field(key: "bookName")
    var bookName: String
    
    @Children(for: \.$book)
    var prakarans: [Prakaran]
    
    init() { }
    
    init(id: Int? = nil, bookOrder: Int, bookName: String) {
        self.id = id
        self.bookOrder = bookOrder
        self.bookName = bookName
    }
}

// MARK: - API Response Models
extension Book {
    struct Public: Content {
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
    
    struct Create: Content, Validatable {
        let bookOrder: Int
        let bookName: String
        
        static func validations(_ validations: inout Validations) {
            validations.add("bookName", as: String.self, is: !.empty)
            validations.add("bookOrder", as: Int.self, is: .range(1...))
        }
    }
    
    struct Update: Content, Validatable {
        let bookOrder: Int?
        let bookName: String?
        
        static func validations(_ validations: inout Validations) {
            validations.add("bookName", as: String.self, is: !.empty, required: false)
            validations.add("bookOrder", as: Int.self, is: .range(1...), required: false)
        }
    }
}
