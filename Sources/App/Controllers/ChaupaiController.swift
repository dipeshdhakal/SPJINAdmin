import Vapor
import Fluent

struct ChaupaiController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let chaupais = routes.grouped("chaupais")
        
        chaupais.get(use: index)
        chaupais.get(":chaupaiID", use: show)
        if AdminConfig.enableAddDelete {
            chaupais.post(use: create)
            chaupais.delete(":chaupaiID", use: delete)
        }
        chaupais.put(":chaupaiID", use: update)
        
        // Favourites endpoint
        chaupais.get("favourites", use: favourites)
        chaupais.put(":chaupaiID", "favourite", use: toggleFavourite)
    }
    
    func index(req: Request) async throws -> View {
        let books = try await Book.query(on: req.db).all()
        let prakarans = try await Prakaran.query(on: req.db)
            .with(\.$book)
            .all()
        
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
        
        if let favourite = req.query[Bool.self, at: "favourite"] {
            query = query.filter(\.$favourite == favourite)
        }
        
        if let search = req.query[String.self, at: "search"]?.trimmingCharacters(in: .whitespaces), !search.isEmpty {
            query = query.group(.or) { group in
                group.filter(\.$chaupaiName ~~ search)
                    .filter(\.$chaupaiMeaning ~~ search)
            }
        }
        
        let chaupais = try await query.all()
        
        let context = ChaupaisContext(
            chaupais: chaupais,
            books: books,
            prakarans: prakarans,
            selectedBookID: req.query[Int.self, at: "bookID"],
            selectedPrakaranID: req.query[Int.self, at: "prakaranID"],
            selectedFavourite: req.query[Bool.self, at: "favourite"],
            search: req.query[String.self, at: "search"],
            enableAddDelete: AdminConfig.enableAddDelete  // Add this parameter
        )
        
        return try await req.view.render("chaupais/index", context)
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
            favourite: create.favourite ?? false,
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
        guard let chaupaiID = req.parameters.get("chaupaiID", as: Int.self),
              let chaupai = try await Chaupai.find(chaupaiID, on: req.db) else {
            throw Abort(.notFound)
        }
        
        try await chaupai.delete(on: req.db)
        return .noContent
    }
     func favourites(req: Request) async throws -> [Chaupai.Public] {
        let chaupais = try await Chaupai.query(on: req.db)
            .filter(\.$favourite == true)
            .sort(\.$chaupaiNumber)
            .with(\.$prakaran)
            .all()

        return chaupais.map(Chaupai.Public.init)
    }
    
    func toggleFavourite(req: Request) async throws -> Chaupai.Public {
        guard let chaupaiID = req.parameters.get("chaupaiID", as: Int.self),
              let chaupai = try await Chaupai.query(on: req.db)
                .filter(\.$id == chaupaiID)
                .with(\.$prakaran)
                .first() else {
            throw Abort(.notFound)
        }
        
        chaupai.favourite.toggle()
        try await chaupai.save(on: req.db)
        
        return Chaupai.Public(from: chaupai)
    }
}
