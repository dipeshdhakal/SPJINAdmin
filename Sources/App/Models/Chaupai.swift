import Vapor
import Fluent

final class Chaupai: Model, Content {
    static let schema = "chaupais"
    
    @ID(custom: "chaupaiID", generatedBy: .user)
    var id: Int?
    
    @Field(key: "chaupaiNumber")
    var chaupaiNumber: Int
    
    @Field(key: "chaupaiName")
    var chaupaiName: String
    
    @OptionalField(key: "chaupaiMeaning")
    var chaupaiMeaning: String?
    
    @Field(key: "favourite")
    var favourite: Bool
    
    @Parent(key: "prakaranID")
    var prakaran: Prakaran
    
    init() { }
    
    init(id: Int? = nil, chaupaiNumber: Int, chaupaiName: String, chaupaiMeaning: String? = nil, favourite: Bool = false, prakaranID: Int) {
        self.id = id
        self.chaupaiNumber = chaupaiNumber
        self.chaupaiName = chaupaiName
        self.chaupaiMeaning = chaupaiMeaning
        self.favourite = favourite
        self.$prakaran.id = prakaranID
    }
}

// MARK: - API Response Models
extension Chaupai {
    struct Public: Content {
        let chaupaiID: Int
        let chaupaiNumber: Int
        let chaupaiName: String
        let chaupaiMeaning: String?
        let favourite: Bool
        let prakaranID: Int
        
        init(from chaupai: Chaupai) {
            self.chaupaiID = chaupai.id!
            self.chaupaiNumber = chaupai.chaupaiNumber
            self.chaupaiName = chaupai.chaupaiName
            self.chaupaiMeaning = chaupai.chaupaiMeaning
            self.favourite = chaupai.favourite
            self.prakaranID = chaupai.$prakaran.id
        }
    }
    
    struct Create: Content, Validatable {
        let chaupaiNumber: Int
        let chaupaiName: String
        let chaupaiMeaning: String?
        let favourite: Bool?
        let prakaranID: Int
        
        static func validations(_ validations: inout Validations) {
            validations.add("chaupaiName", as: String.self, is: !.empty)
            validations.add("chaupaiNumber", as: Int.self, is: .range(1...))
            validations.add("prakaranID", as: Int.self, is: .range(0...))
        }
    }
    
    struct Update: Content, Validatable {
        let chaupaiNumber: Int?
        let chaupaiName: String?
        let chaupaiMeaning: String?
        let favourite: Bool?
        let prakaranID: Int?
        
        static func validations(_ validations: inout Validations) {
            validations.add("chaupaiName", as: String.self, is: !.empty, required: false)
            validations.add("chaupaiNumber", as: Int.self, is: .range(1...), required: false)
            validations.add("prakaranID", as: Int.self, is: .range(0...), required: false)
        }
    }
}
