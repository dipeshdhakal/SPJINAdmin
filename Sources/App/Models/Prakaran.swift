import Vapor
import Fluent

final class Prakaran: Model, Content {
    static let schema = "prakarans"
    
    @ID(custom: "prakaranID", generatedBy: .user)
    var id: Int?
    
    @Field(key: "prakaranOrder")
    var prakaranOrder: Int
    
    @Field(key: "prakaranName")
    var prakaranName: String
    
    @OptionalField(key: "prakaranDetails")
    var prakaranDetails: String?
    
    @Parent(key: "bookID")
    var book: Book
    
    @Children(for: \.$prakaran)
    var chaupais: [Chaupai]
    
    init() { }
    
    init(id: Int? = nil, prakaranOrder: Int, prakaranName: String, prakaranDetails: String? = nil, bookID: Int) {
        self.id = id
        self.prakaranOrder = prakaranOrder
        self.prakaranName = prakaranName
        self.prakaranDetails = prakaranDetails
        self.$book.id = bookID
    }
}

// MARK: - API Response Models
extension Prakaran {
    struct Public: Content {
        let prakaranID: Int
        let prakaranOrder: Int
        let prakaranName: String
        let prakaranDetails: String?
        let bookID: Int
        let chaupaiCount: Int?
        
        init(from prakaran: Prakaran, chaupaiCount: Int? = nil) {
            self.prakaranID = prakaran.id!
            self.prakaranOrder = prakaran.prakaranOrder
            self.prakaranName = prakaran.prakaranName
            self.prakaranDetails = prakaran.prakaranDetails
            self.bookID = prakaran.$book.id
            self.chaupaiCount = chaupaiCount
        }
    }
    
    struct Create: Content, Validatable {
        let prakaranOrder: Int
        let prakaranName: String
        let prakaranDetails: String?
        let bookID: Int
        
        static func validations(_ validations: inout Validations) {
            validations.add("prakaranName", as: String.self, is: !.empty)
            validations.add("prakaranOrder", as: Int.self, is: .range(1...))
            validations.add("bookID", as: Int.self, is: .range(0...))
        }
    }
    
    struct Update: Content, Validatable {
        let prakaranOrder: Int?
        let prakaranName: String?
        let prakaranDetails: String?
        let bookID: Int?
        
        static func validations(_ validations: inout Validations) {
            validations.add("prakaranName", as: String.self, is: !.empty, required: false)
            validations.add("prakaranOrder", as: Int.self, is: .range(1...), required: false)
            validations.add("bookID", as: Int.self, is: .range(0...), required: false)
        }
    }
}
