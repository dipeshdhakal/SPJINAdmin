import Fluent

struct SeedData: AsyncMigration {
    func prepare(on database: Database) async throws {
        // Sample seed data - you can customize this with your actual data
        
        // Create sample books
        let book1 = Book(id: 0, bookOrder: 1, bookName: "Sample Book 1")
        let book2 = Book(id: 1, bookOrder: 2, bookName: "Sample Book 2")
        
        try await book1.save(on: database)
        try await book2.save(on: database)
        
        // Create sample prakarans
        let prakaran1 = Prakaran(id: 0, prakaranOrder: 1, prakaranName: "Sample Prakaran 1", bookID: 0)
        let prakaran2 = Prakaran(id: 1, prakaranOrder: 2, prakaranName: "Sample Prakaran 2", bookID: 0)
        let prakaran3 = Prakaran(id: 2, prakaranOrder: 1, prakaranName: "Sample Prakaran 3", bookID: 1)
        
        try await prakaran1.save(on: database)
        try await prakaran2.save(on: database)
        try await prakaran3.save(on: database)
        
        // Create sample chaupais
        let chaupai1 = Chaupai(id: 0, chaupaiNumber: 1, chaupaiName: "Sample Chaupai 1", chaupaiMeaning: "Meaning 1", prakaranID: 0)
        let chaupai2 = Chaupai(id: 1, chaupaiNumber: 2, chaupaiName: "Sample Chaupai 2", chaupaiMeaning: "Meaning 2", prakaranID: 0)
        let chaupai3 = Chaupai(id: 2, chaupaiNumber: 1, chaupaiName: "Sample Chaupai 3", chaupaiMeaning: "Meaning 3", favourite: true, prakaranID: 1)
        
        try await chaupai1.save(on: database)
        try await chaupai2.save(on: database)
        try await chaupai3.save(on: database)
    }

    func revert(on database: Database) async throws {
        // Remove seed data in reverse order
        try await Chaupai.query(on: database).delete()
        try await Prakaran.query(on: database).delete()
        try await Book.query(on: database).delete()
    }
}
