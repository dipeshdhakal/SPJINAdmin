import Fluent
import Vapor
@preconcurrency import JWT

final class User: Model, Content {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Field(key: "created_at")
    var createdAt: Date
    
    @Field(key: "updated_at")
    var updatedAt: Date
    
    init() { }
    
    init(id: UUID? = nil, username: String, passwordHash: String) {
        self.id = id
        self.username = username
        self.passwordHash = passwordHash
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    func verify(password: String) throws -> Bool {
        let result = try Bcrypt.verify(password, created: passwordHash)
        return result
    }
}

// User Token for JWT authentication
struct UserToken: Content, Authenticatable, JWTPayload {
    // Token expiration time
    var exp: ExpirationClaim
    
    // User ID
    var sub: SubjectClaim
    
    // Username for display
    var username: String
    
    func verify(using signer: JWTSigner) throws {
        try self.exp.verifyNotExpired()
    }
}

// Authentication credentials
struct UserCredentials: Content {
    var username: String
    var password: String
    var redirect: String?
}

// User Authentication
extension User: ModelAuthenticatable {
    static let usernameKey = \User.$username
    static let passwordHashKey = \User.$passwordHash
}
