import Vapor
import JWT

struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Check for auth token in cookies
        guard let tokenValue = request.cookies["auth_token"]?.string,
              !tokenValue.isEmpty else {
            return request.redirect(to: "/auth/login")
        }
        
        do {
            // Verify JWT token
            let payload = try request.jwt.verify(tokenValue, as: UserToken.self)
            
            // Check if token is still valid (expiration is checked during verification)
            request.auth.login(payload)
            
            return try await next.respond(to: request)
        } catch {
            return request.redirect(to: "/auth/login")
        }
    }
}
