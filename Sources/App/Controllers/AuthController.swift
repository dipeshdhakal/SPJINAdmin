import Vapor
import Fluent
import JWT

struct AuthController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let auth = routes.grouped("auth")
        auth.get("login", use: loginPage)
        auth.post("login", use: login)
        auth.post("logout", use: logout)
    }
    
    func loginPage(req: Request) throws -> EventLoopFuture<View> {
        return req.view.render("auth/login")
    }
    
    func login(req: Request) async throws -> Response {
        let credentials = try req.content.decode(UserCredentials.self)
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == credentials.username)
            .first() else {
            throw Abort(.unauthorized, reason: "Invalid username or password")
        }
        
        let isValidPassword = try user.verify(password: credentials.password)
        guard isValidPassword else {
            throw Abort(.unauthorized, reason: "Invalid username or password")
        }
        
        // Create JWT token
        let expiration = ExpirationClaim(value: Date().addingTimeInterval(86400)) // 24 hours
        let userID = try user.requireID()
        let sub = SubjectClaim(value: userID.uuidString)
        let payload = UserToken(exp: expiration, sub: sub, username: user.username)
        
        let token = try req.jwt.sign(payload)
        
        // Set cookie
        let cookie = HTTPCookies.Value(
            string: token,
            expires: Date().addingTimeInterval(86400), // 24 hours
            maxAge: nil,
            domain: nil,
            path: "/",
            isSecure: false,
            isHTTPOnly: true,
            sameSite: HTTPCookies.SameSitePolicy.lax
        )
        
        let response = req.redirect(to: "/admin")
        response.cookies["auth_token"] = cookie
        return response
    }
    
    func logout(req: Request) throws -> Response {
        let response = req.redirect(to: "/auth/login")
        response.cookies["auth_token"] = HTTPCookies.Value(
            string: "",
            expires: Date(timeIntervalSince1970: 0),
            maxAge: 0,
            domain: nil,
            path: "/",
            isSecure: false,
            isHTTPOnly: true,
            sameSite: HTTPCookies.SameSitePolicy.lax
        )
        return response
    }
}
