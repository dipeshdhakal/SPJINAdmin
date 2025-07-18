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
        let error = req.query[String.self, at: "error"]
        return try await req.view.render("auth/login", ["redirect": redirectURL, "error": error])
    }
    
    func login(req: Request) async throws -> Response {
        let credentials = try req.content.decode(UserCredentials.self)
        req.logger.debug("Login attempt for username: \(credentials.username)")
        
        guard let user = try await User.query(on: req.db)
            .filter(\.$username == credentials.username)
            .first() else {
            req.logger.debug("User not found: \(credentials.username)")
            let errorMessage = "Invalid username or password"
            let redirectURL = credentials.redirect ?? "/admin/dashboard"
            return req.redirect(to: "/auth/login?error=\(errorMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&redirect=\(redirectURL)")
        }
        
        req.logger.debug("User found, verifying password...")
        let isValidPassword = try user.verify(password: credentials.password)
        
        guard isValidPassword else {
            req.logger.debug("Invalid password for user: \(credentials.username)")
            let errorMessage = "Invalid username or password"
            let redirectURL = credentials.redirect ?? "/admin/dashboard"
            return req.redirect(to: "/auth/login?error=\(errorMessage.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&redirect=\(redirectURL)")
        }
        
        req.logger.debug("Password verified successfully")
        
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
        req.logger.debug("JWT token generated successfully")
        
        // Set cookie with proper configuration
        let cookie = HTTPCookies.Value(
            string: token,
            expires: expiration,
            maxAge: 86400,
            domain: nil,
            path: "/",
            isSecure: false,
            isHTTPOnly: true,
            sameSite: .lax
        )
        
        // Create response and set cookie
        let response = req.redirect(to: req.query[String.self, at: "redirect"] ?? "/admin/dashboard")
        response.cookies["auth_token"] = cookie
        req.logger.debug("Login successful, redirecting to dashboard...")
        
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
            sameSite: .lax
        )
        return response
    }
}
