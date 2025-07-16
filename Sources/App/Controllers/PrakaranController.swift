import Vapor
import Fluent

struct PrakaranController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let prakarans = routes.grouped("prakarans")
        
        prakarans.get(use: index)
        prakarans.get(":prakaranID", use: show)
        prakarans.post(use: create)
        prakarans.put(":prakaranID", use: update)
        prakarans.delete(":prakaranID", use: delete)
        
        // Get chaupais for a prakaran
        prakarans.get(":prakaranID", "chaupais", use: getChaupais)
    }
    
    func index(req: Request) async throws -> [Prakaran.Public] {
        var query = Prakaran.query(on: req.db)
            .with(\.$chaupais)
            .with(\.$book)
        
        // Apply filters
        if let bookID = req.query[Int.self, at: "bookID"] {
            query = query.filter(\.$book.$id == bookID)
        }
        
        if let search = req.query[String.self, at: "search"] {
            query = query.group(.or) { group in
                group.filter(\.$prakaranName ~~ search)
                group.filter(\.$prakaranDetails ~~ search)
            }
        }
        
        let prakarans = try await query
            .sort(\.$prakaranOrder)
            .all()
        
        return prakarans.map { prakaran in
            Prakaran.Public(from: prakaran, chaupaiCount: prakaran.chaupais.count)
        }
    }
    
    func show(req: Request) async throws -> Prakaran.Public {
        guard let prakaranID = req.parameters.get("prakaranID", as: Int.self),
              let prakaran = try await Prakaran.query(on: req.db)
                .filter(\.$id == prakaranID)
                .with(\.$chaupais)
                .with(\.$book)
                .first() else {
            throw Abort(.notFound)
        }
        
        return Prakaran.Public(from: prakaran, chaupaiCount: prakaran.chaupais.count)
    }
    
    func create(req: Request) async throws -> Prakaran.Public {
        try Prakaran.Create.validate(content: req)
        let create = try req.content.decode(Prakaran.Create.self)
        
        // Verify book exists
        guard let _ = try await Book.find(create.bookID, on: req.db) else {
            throw Abort(.badRequest, reason: "Book not found")
        }
        
        // Find next available ID
        let maxID = try await Prakaran.query(on: req.db)
            .max(\.$id) ?? -1
        
        let prakaran = Prakaran(
            id: maxID + 1,
            prakaranOrder: create.prakaranOrder,
            prakaranName: create.prakaranName,
            prakaranDetails: create.prakaranDetails,
            bookID: create.bookID
        )
        
        try await prakaran.save(on: req.db)
        
        // Reload with book relationship for response
        guard let savedPrakaran = try await Prakaran.query(on: req.db)
            .filter(\.$id == prakaran.id!)
            .with(\.$book)
            .first() else {
            throw Abort(.internalServerError, reason: "Failed to reload saved prakaran")
        }
        
        return Prakaran.Public(from: savedPrakaran)
    }
    
    func update(req: Request) async throws -> Prakaran.Public {
        try Prakaran.Update.validate(content: req)
        let update = try req.content.decode(Prakaran.Update.self)
        
        guard let prakaranID = req.parameters.get("prakaranID", as: Int.self),
              let prakaran = try await Prakaran.query(on: req.db)
                .filter(\.$id == prakaranID)
                .with(\.$book)
                .first() else {
            throw Abort(.notFound)
        }
        
        if let prakaranOrder = update.prakaranOrder {
            prakaran.prakaranOrder = prakaranOrder
        }
        if let prakaranName = update.prakaranName {
            prakaran.prakaranName = prakaranName
        }
        if let prakaranDetails = update.prakaranDetails {
            prakaran.prakaranDetails = prakaranDetails
        }
        if let bookID = update.bookID {
            // Verify book exists
            guard let _ = try await Book.find(bookID, on: req.db) else {
                throw Abort(.badRequest, reason: "Book not found")
            }
            prakaran.$book.id = bookID
        }
        
        try await prakaran.save(on: req.db)
        return Prakaran.Public(from: prakaran)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let prakaranID = req.parameters.get("prakaranID", as: Int.self),
              let prakaran = try await Prakaran.find(prakaranID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await prakaran.delete(on: req.db)
        return .noContent
    }
    
    func getChaupais(req: Request) async throws -> [Chaupai.Public] {
        guard let prakaranID = req.parameters.get("prakaranID", as: Int.self),
              let prakaran = try await Prakaran.find(prakaranID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        var query = prakaran.$chaupais.query(on: req.db)
        
        // Apply filters
        if let favourite = req.query[Bool.self, at: "favourite"] {
            query = query.filter(\.$favourite == favourite)
        }
        
        if let search = req.query[String.self, at: "search"] {
            query = query.group(.or) { group in
                group.filter(\.$chaupaiName ~~ search)
                if let meaning = req.query[String.self, at: "searchMeaning"], meaning.lowercased() == "true" {
                    group.filter(\.$chaupaiMeaning ~~ search)
                }
            }
        }
         let chaupais = try await query
            .sort(\.$chaupaiNumber)
            .with(\.$prakaran)
            .all()

        return chaupais.map(Chaupai.Public.init)
    }
}
