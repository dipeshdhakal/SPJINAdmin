import Vapor

struct AdminConfig {
    // Controls whether add/delete functionality is enabled in the admin interface
    // Change this value and redeploy to enable/disable add/delete buttons
    static let enableAddDelete: Bool = false
}

struct IndexContext<T: Encodable>: Encodable {
    let items: [T]
    let search: String?
    let enableAddDelete: Bool
    
    init(items: [T], search: String?, enableAddDelete: Bool = AdminConfig.enableAddDelete) {
        self.items = items
        self.search = search
        self.enableAddDelete = enableAddDelete
    }
}

