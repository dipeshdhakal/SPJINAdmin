import Vapor
import Fluent

struct ChaupaiController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let chaupais = routes.grouped("chaupais")
        
        chaupais.get(use: index)
        chaupais.get(":chaupaiID", use: show)
        chaupais.post(use: create)
        chaupais.put(":chaupaiID", use: update)
        chaupais.delete(":chaupaiID", use: delete)
        
        // Favourites endpoint
        chaupais.get("favourites", use: favourites)
        chaupais.put(":chaupaiID", "favourite", use: toggleFavourite)
    }
    
    func index(req: Request) async throws -> [Chaupai.Public] {
        var query = Chaupai.query(on: req.db)
        
        // Apply filters
        if let prakaranID = req.query[Int.self, at: "prakaranID"] {
            query = query.filter(\.$prakaran.$id == prakaranID)
        }
        
        if let bookID = req.query[Int.self, at: "bookID"] {
            query = query.join(Prakaran.self, on: \Chaupai.$prakaran.$id == \Prakaran.$id)
                .filter(Prakaran.self, \.$book.$id == bookID)
        }
        
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
        
        // Pagination
        let page = req.query[Int.self, at: "page"] ?? 1
        let limit = req.query[Int.self, at: "limit"] ?? 50
        let offset = (page - 1) * limit
        
        let chaupais = try await query
            .sort(\.$chaupaiNumber)
            .offset(offset)
            .limit(limit)
            .all()
        
        return chaupais.map(Chaupai.Public.init)
    }
    
    func show(req: Request) async throws -> Chaupai.Public {
        guard let chaupai = try await Chaupai.find(req.parameters.get("chaupaiID"), on: req.db) else {
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
            favourite: create.favourite ?? false,
            prakaranID: create.prakaranID
        )
        
        try await chaupai.save(on: req.db)
        return Chaupai.Public(from: chaupai)
    }
    
    func update(req: Request) async throws -> Chaupai.Public {
        try Chaupai.Update.validate(content: req)
        let update = try req.content.decode(Chaupai.Update.self)
        
        guard let chaupai = try await Chaupai.find(req.parameters.get("chaupaiID"), on: req.db) else {
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
        if let favourite = update.favourite {
            chaupai.favourite = favourite
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
        guard let chaupai = try await Chaupai.find(req.parameters.get("chaupaiID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await chaupai.delete(on: req.db)
        return .noContent
    }
    
    func favourites(req: Request) async throws -> [Chaupai.Public] {
        let chaupais = try await Chaupai.query(on: req.db)
            .filter(\.$favourite == true)
            .sort(\.$chaupaiNumber)
            .all()
        
        return chaupais.map(Chaupai.Public.init)
    }
    
    func toggleFavourite(req: Request) async throws -> Chaupai.Public {
        guard let chaupai = try await Chaupai.find(req.parameters.get("chaupaiID"), on: req.db) else {
            throw Abort(.notFound)
        }
        
        chaupai.favourite.toggle()
        try await chaupai.save(on: req.db)
        
        return Chaupai.Public(from: chaupai)
    }
}
