import Vapor
import Logging

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)

let app = Application(env)
defer { app.shutdown() }

do {
    try configure(app)
    
    // Run migrations on startup in production
    if env.isRelease {
        try app.autoMigrate().wait()
    }
    
    try app.run()
} catch {
    app.logger.report(error: error)
    throw error
}
