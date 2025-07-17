import Vapor
import Fluent

struct APIChaupaiController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let chaupais = routes.grouped("chaupais")
        
        chaupais.get(use: index)
        chaupais.get(":chaupaiID", use: show)
        chaupais.post(use: create)
        chaupais.put(":chaupaiID", use: update)
        chaupais.delete(":chaupaiID", use: delete)
    }
    
    func index(req: Request) async throws -> [Chaupai.Public] {
        var query = Chaupai.query(on: req.db)
            .with(\.$prakaran) { prakaran in
                prakaran.with(\.$book)
            }
        
        // Apply filters
        if let bookID = req.query[Int.self, at: "bookID"] {
            query = query.join(Prakaran.self, on: \Chaupai.$prakaran.$id == \Prakaran.$id)
                .join(Book.self, on: \Prakaran.$book.$id == \Book.$id)
                .filter(Book.self, \.$id == bookID)
        }
        
        if let prakaranID = req.query[Int.self, at: "prakaranID"] {
            query = query.filter(\.$prakaran.$id == prakaranID)
        }
        
        if let search = req.query[String.self, at: "search"]?.trimmingCharacters(in: .whitespaces), !search.isEmpty {
            query = query.group(.or) { group in
                group.filter(\.$chaupaiName ~~ search)
                    .filter(\.$chaupaiMeaning ~~ search)
            }
        }
        
        let chaupais = try await query.sort(\.$chaupaiNumber).all()
        return chaupais.map { Chaupai.Public(from: $0) }
    }
    
    func show(req: Request) async throws -> Chaupai.Public {
        guard let chaupaiID = req.parameters.get("chaupaiID", as: Int.self),
              let chaupai = try await Chaupai.query(on: req.db)
                .filter(\.$id == chaupaiID)
                .with(\.$prakaran)
                .first() else {
            throw Abort(.notFound)
        }
        
        return Chaupai.Public(from: chaupai)
    }
    
    func create(req: Request) async throws -> Chaupai.Public {
        try Chaupai.Create.validate(content: req)
        let create = try req.content.decode(Chaupai.Create.self)
        
        // Verify prakaran exists
        guard let _ = try await Prakaran.find(create.prakaranID, on: req.db) else {
            throw Abort(.badRequest, reason: "Prakaran not found")
        }
        
        // Find next available ID
        let maxID = try await Chaupai.query(on: req.db)
            .max(\.$id) ?? -1
        
        let chaupai = Chaupai(
            id: maxID + 1,
            chaupaiNumber: create.chaupaiNumber,
            chaupaiName: create.chaupaiName,
            chaupaiMeaning: create.chaupaiMeaning,
            prakaranID: create.prakaranID
        )
        
        try await chaupai.save(on: req.db)
        
        // Reload with prakaran relationship for response
        guard let savedChaupai = try await Chaupai.query(on: req.db)
            .filter(\.$id == chaupai.id!)
            .with(\.$prakaran)
            .first() else {
            throw Abort(.internalServerError, reason: "Failed to reload saved chaupai")
        }
        
        return Chaupai.Public(from: savedChaupai)
    }
    
    func update(req: Request) async throws -> Chaupai.Public {
        try Chaupai.Update.validate(content: req)
        let update = try req.content.decode(Chaupai.Update.self)
        
        guard let chaupaiID = req.parameters.get("chaupaiID", as: Int.self),
              let chaupai = try await Chaupai.query(on: req.db)
                .filter(\.$id == chaupaiID)
                .with(\.$prakaran)
                .first() else {
            throw Abort(.notFound)
        }
        
        if let chaupaiNumber = update.chaupaiNumber {
            chaupai.chaupaiNumber = chaupaiNumber
        }
        if let chaupaiName = update.chaupaiName {
            chaupai.chaupaiName = chaupaiName
        }
        if let chaupaiMeaning = update.chaupaiMeaning {
            chaupai.chaupaiMeaning = chaupaiMeaning
        }
        if let prakaranID = update.prakaranID {
            // Verify prakaran exists
            guard let _ = try await Prakaran.find(prakaranID, on: req.db) else {
                throw Abort(.badRequest, reason: "Prakaran not found")
            }
            chaupai.$prakaran.id = prakaranID
        }
        
        try await chaupai.save(on: req.db)
        return Chaupai.Public(from: chaupai)
    }
    
    func delete(req: Request) async throws -> HTTPStatus {
        guard let chaupaiID = req.parameters.get("chaupaiID", as: Int.self),
              let chaupai = try await Chaupai.find(chaupaiID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await chaupai.delete(on: req.db)
        return .noContent
    }
}
