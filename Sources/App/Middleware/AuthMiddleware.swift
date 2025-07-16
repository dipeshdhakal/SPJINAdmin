import Vapor
import JWT
import LeafKit

struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: AsyncResponder) async throws -> Response {
        // Debug logging
        print("AuthMiddleware checking path: \(request.url.path)")
        
        // Check for auth token in cookies
        guard let tokenValue = request.cookies["auth_token"]?.string,
              !tokenValue.isEmpty else {
            print("No auth_token cookie found")
            let originalURL = request.url.string
            return request.redirect(to: "/auth/login?redirect=\(originalURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
        
        do {
            // Verify JWT token
            let payload = try request.jwt.verify(tokenValue, as: UserToken.self)
            
            // Login the user
            request.auth.login(payload)
            
            // After successful authentication, proceed to next responder
            do {
                return try await next.respond(to: request)
            } catch let error as LeafKit.LexerError {
                // Return a custom error response for template rendering issues
                print("Template rendering error occurred: \(error.localizedDescription)")
                return Response(
                    status: .internalServerError,
                    headers: HTTPHeaders(),
                    body: Response.Body(string: "An error occurred while rendering the page. Please try again.")
                )
            } catch {
                print("Other error in next responder: \(error.localizedDescription)")
                throw error
            }
        } catch {
            if error is LeafKit.LexerError {
                // Return a custom error response for template rendering issues
                print("Template rendering error during authentication: \(error.localizedDescription)")
                return Response(
                    status: .internalServerError,
                    headers: HTTPHeaders(),
                    body: Response.Body(string: "An error occurred while rendering the page. Please try again.")
                )
            }
            
            // For auth errors, redirect to login
            print("Authentication error: \(error)")
            let originalURL = request.url.string
            return request.redirect(to: "/auth/login?redirect=\(originalURL.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")")
        }
    }
}
