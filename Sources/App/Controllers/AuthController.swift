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
    
    func loginPage(req: Request) async throws -> View {
        let redirectURL = req.query[String.self, at: "redirect"]
        return try await req.view.render("auth/login", ["redirect": redirectURL])
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
        
        // Create JWT token with 24 hour expiration
        let expiration = Date().addingTimeInterval(86400)
        let userID = try user.requireID()
        let payload = UserToken(
            exp: ExpirationClaim(value: expiration),
            sub: SubjectClaim(value: userID.uuidString),
            username: user.username
        )
        
        // Sign the token
        let token = try req.jwt.sign(payload)
        print("Generated JWT token: \(token.prefix(50))...")
        
        // Set cookie with proper configuration
        let cookie = HTTPCookies.Value(
            string: token,
            expires: expiration,
            maxAge: 86400,
            domain: nil,
            path: "/",
            isSecure: false, // Set to true in production with HTTPS
            isHTTPOnly: true,
            sameSite: .lax
        )
        
        // Create response with redirect
        let redirectURL = credentials.redirect?.isEmpty == false ? credentials.redirect! : "/admin"
        let response = req.redirect(to: redirectURL)
        
        // Set the cookie
        response.cookies["auth_token"] = cookie
        response.headers.add(name: .cacheControl, value: "no-cache, private")
        
        print("Login successful for user: \(user.username)")
        print("Setting auth_token cookie. Token length: \(token.count)")
        print("Redirecting to: \(redirectURL)")
        
        return response
    }
    
    func logout(req: Request) throws -> Response {
        print("Logging out user")
        let response = req.redirect(to: "/auth/login")
        response.cookies["auth_token"] = HTTPCookies.Value(
            string: "",
            expires: Date(timeIntervalSince1970: 0),
            maxAge: 0,
            domain: nil,
            path: "/",
            isSecure: false,
            isHTTPOnly: true,
            sameSite: .lax
        )
        print("Auth token cookie cleared")
        return response
    }
}
