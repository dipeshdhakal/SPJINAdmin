import Vapor
import Fluent

struct ExportController: RouteCollection {
    func boot(routes: RoutesBuilder) throws {
        let exportRoutes = routes.grouped("export")
        exportRoutes.get("books", "sql", use: exportBooksSQL)
        exportRoutes.get("prakarans", "sql", use: exportPrakaransSQL)
        exportRoutes.get("chaupais", "sql", use: exportChaupaisSQL)
        exportRoutes.get("all", "sql", use: exportAllDataSQL)
        
        // Import routes
        exportRoutes.get("import", use: showImportForm)
        exportRoutes.post("import", use: handleImport)
    }
    
    func exportBooksSQL(req: Request) async throws -> Response {
        let books = try await Book.query(on: req.db).all()
        
        var sqlContent = "-- Books Export\n"
        sqlContent += "-- Generated on \(Date())\n\n"
        sqlContent += "CREATE TABLE IF NOT EXISTS books (\n"
        sqlContent += "\tbookID INTEGER PRIMARY KEY,\n"
        sqlContent += "\tbookOrder INTEGER,\n"
        sqlContent += "\tbookName TEXT NOT NULL\n"
        sqlContent += ");\n\n"
        
        if !books.isEmpty {
            sqlContent += "INSERT INTO \"books\" (\"bookID\",\"bookOrder\",\"bookName\") VALUES\n"
            
            let values = books.enumerated().map { index, book in
                let id = book.id?.description ?? "NULL"
                let bookName = book.bookName.replacingOccurrences(of: "\"", with: "\"\"")
                
                let isLast = index == books.count - 1
                return "(\(id),\(book.bookOrder),\"\(bookName)\")\(isLast ? ";" : ",")"
            }
            
            sqlContent += values.joined(separator: "\n")
            sqlContent += "\n\n"
        }
        
        let response = Response()
        response.headers.contentType = .init(type: "application", subType: "sql")
        response.headers.add(name: .contentDisposition, value: "attachment; filename=\"books.sql\"")
        response.body = .init(string: sqlContent)
        
        return response
    }
    
    func exportPrakaransSQL(req: Request) async throws -> Response {
        let prakarans = try await Prakaran.query(on: req.db)
            .with(\.$book)
            .all()
        
        var sqlContent = "-- Prakarans Export\n"
        sqlContent += "-- Generated on \(Date())\n\n"
        sqlContent += "CREATE TABLE IF NOT EXISTS prakarans (\n"
        sqlContent += "\tprakaranID INTEGER PRIMARY KEY,\n"
        sqlContent += "\tprakaranOrder INTEGER,\n"
        sqlContent += "\tprakaranName TEXT NOT NULL,\n"
        sqlContent += "\tbookID INTEGER NOT NULL, prakaranDetails TEXT,\n"
        sqlContent += "\tFOREIGN KEY(bookID) REFERENCES books(bookID) ON DELETE CASCADE\n"
        sqlContent += ");\n\n"
        
        if !prakarans.isEmpty {
            sqlContent += "INSERT INTO \"prakarans\" (\"prakaranID\",\"prakaranOrder\",\"prakaranName\",\"bookID\",\"prakaranDetails\") VALUES\n"
            
            let values = prakarans.enumerated().map { index, prakaran in
                let id = prakaran.id?.description ?? "NULL"
                let prakaranName = prakaran.prakaranName.replacingOccurrences(of: "\"", with: "\"\"")
                let prakaranDetails = prakaran.prakaranDetails?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                let bookId = prakaran.$book.id.description
                
                let isLast = index == prakarans.count - 1
                return "(\(id),\(prakaran.prakaranOrder),\"\(prakaranName)\",\(bookId),\"\(prakaranDetails)\")\(isLast ? ";" : ",")"
            }
            
            sqlContent += values.joined(separator: "\n")
            sqlContent += "\n\n"
        }
        
        let response = Response()
        response.headers.contentType = .init(type: "application", subType: "sql")
        response.headers.add(name: .contentDisposition, value: "attachment; filename=\"prakarans.sql\"")
        response.body = .init(string: sqlContent)
        
        return response
    }
    
    func exportChaupaisSQL(req: Request) async throws -> Response {
        let chaupais = try await Chaupai.query(on: req.db)
            .with(\.$prakaran)
            .all()
        
        var sqlContent = "-- Chaupais Export\n"
        sqlContent += "-- Generated on \(Date())\n\n"
        sqlContent += "CREATE TABLE IF NOT EXISTS chaupais (\n"
        sqlContent += "\tchaupaiID INTEGER PRIMARY KEY,\n"
        sqlContent += "\tchaupaiNumber INTEGER,\n"
        sqlContent += "\tchaupaiName TEXT NOT NULL,\n"
        sqlContent += "\tchaupaiMeaning TEXT,\n"
        sqlContent += "\tprakaranID INTEGER NOT NULL,\n"
        sqlContent += "\tFOREIGN KEY(prakaranID) REFERENCES prakarans(prakaranID) ON DELETE CASCADE\n"
        sqlContent += ");\n\n"
        
        if !chaupais.isEmpty {
            sqlContent += "INSERT INTO \"chaupais\" (\"chaupaiID\",\"chaupaiNumber\",\"chaupaiName\",\"chaupaiMeaning\",\"prakaranID\") VALUES\n"
            
            let values = chaupais.enumerated().map { index, chaupai in
                let id = chaupai.id?.description ?? "NULL"
                let chaupaiName = chaupai.chaupaiName.replacingOccurrences(of: "\"", with: "\"\"")
                let chaupaiMeaning = chaupai.chaupaiMeaning?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                let prakaranId = chaupai.$prakaran.id.description
                
                let isLast = index == chaupais.count - 1
                return "(\(id),\(chaupai.chaupaiNumber),\"\(chaupaiName)\",\"\(chaupaiMeaning)\",\(prakaranId))\(isLast ? ";" : ",")"
            }
            
            sqlContent += values.joined(separator: "\n")
            sqlContent += "\n\n"
        }
        
        let response = Response()
        response.headers.contentType = .init(type: "application", subType: "sql")
        response.headers.add(name: .contentDisposition, value: "attachment; filename=\"chaupais.sql\"")
        response.body = .init(string: sqlContent)
        
        return response
    }
    
    func exportAllDataSQL(req: Request) async throws -> Response {
        // Get all data
        async let booksQuery = Book.query(on: req.db).all()
        async let prakaransQuery = Prakaran.query(on: req.db).with(\.$book).all()
        async let chaupaisQuery = Chaupai.query(on: req.db).with(\.$prakaran).all()
        
        let (books, prakarans, chaupais) = try await (booksQuery, prakaransQuery, chaupaisQuery)
        
        var sqlContent = "-- Complete Database Export\n"
        sqlContent += "-- Generated on \(Date())\n\n"
        
        // Drop tables in reverse order (foreign key constraints)
        sqlContent += "-- Drop existing tables\n"
        sqlContent += "DROP TABLE IF EXISTS chaupais;\n"
        sqlContent += "DROP TABLE IF EXISTS prakarans;\n"
        sqlContent += "DROP TABLE IF EXISTS books;\n\n"
        
        // Create tables
        sqlContent += "-- Create tables\n"
        sqlContent += "CREATE TABLE IF NOT EXISTS books (\n"
        sqlContent += "\tbookID INTEGER PRIMARY KEY,\n"
        sqlContent += "\tbookOrder INTEGER,\n"
        sqlContent += "\tbookName TEXT NOT NULL\n"
        sqlContent += ");\n"
        sqlContent += "CREATE TABLE IF NOT EXISTS prakarans (\n"
        sqlContent += "\tprakaranID INTEGER PRIMARY KEY,\n"
        sqlContent += "\tprakaranOrder INTEGER,\n"
        sqlContent += "\tprakaranName TEXT NOT NULL,\n"
        sqlContent += "\tbookID INTEGER NOT NULL, prakaranDetails TEXT,\n"
        sqlContent += "\tFOREIGN KEY(bookID) REFERENCES books(bookID) ON DELETE CASCADE\n"
        sqlContent += ");\n"
        sqlContent += "CREATE TABLE IF NOT EXISTS chaupais (\n"
        sqlContent += "\tchaupaiID INTEGER PRIMARY KEY,\n"
        sqlContent += "\tchaupaiNumber INTEGER,\n"
        sqlContent += "\tchaupaiName TEXT NOT NULL,\n"
        sqlContent += "\tchaupaiMeaning TEXT,\n"
        sqlContent += "\tprakaranID INTEGER NOT NULL,\n"
        sqlContent += "\tFOREIGN KEY(prakaranID) REFERENCES prakarans(prakaranID) ON DELETE CASCADE\n"
        sqlContent += ");\n\n"
        
        // Insert data in correct order (respecting foreign keys)
        
        // Books first
        if !books.isEmpty {
            sqlContent += "-- Insert Books\n"
            sqlContent += "INSERT INTO \"books\" (\"bookID\",\"bookOrder\",\"bookName\") VALUES\n"
            
            let bookValues = books.enumerated().map { index, book in
                let id = book.id?.description ?? "NULL"
                let bookName = book.bookName.replacingOccurrences(of: "\"", with: "\"\"")
                
                let isLast = index == books.count - 1
                return "(\(id),\(book.bookOrder),\"\(bookName)\")\(isLast ? ";" : ",")"
            }
            
            sqlContent += bookValues.joined(separator: "\n")
            sqlContent += "\n\n"
        }
        
        // Prakarans second
        if !prakarans.isEmpty {
            sqlContent += "-- Insert Prakarans\n"
            sqlContent += "INSERT INTO \"prakarans\" (\"prakaranID\",\"prakaranOrder\",\"prakaranName\",\"bookID\",\"prakaranDetails\") VALUES\n"
            
            let prakaranValues = prakarans.enumerated().map { index, prakaran in
                let id = prakaran.id?.description ?? "NULL"
                let prakaranName = prakaran.prakaranName.replacingOccurrences(of: "\"", with: "\"\"")
                let prakaranDetailsValue: String
                if let details = prakaran.prakaranDetails {
                    prakaranDetailsValue = "\"\(details.replacingOccurrences(of: "\"", with: "\"\""))\""
                } else {
                    prakaranDetailsValue = "NULL"
                }
                let bookId = prakaran.$book.id.description
                
                let isLast = index == prakarans.count - 1
                return "(\(id),\(prakaran.prakaranOrder),\"\(prakaranName)\",\(bookId),\(prakaranDetailsValue))\(isLast ? ";" : ",")"
            }
            
            sqlContent += prakaranValues.joined(separator: "\n")
            sqlContent += "\n\n"
        }
        
        // Chaupais last
        if !chaupais.isEmpty {
            sqlContent += "-- Insert Chaupais\n"
            sqlContent += "INSERT INTO \"chaupais\" (\"chaupaiID\",\"chaupaiNumber\",\"chaupaiName\",\"chaupaiMeaning\",\"prakaranID\") VALUES\n"
            
            let chaupaiValues = chaupais.enumerated().map { index, chaupai in
                let id = chaupai.id?.description ?? "NULL"
                let chaupaiName = chaupai.chaupaiName.replacingOccurrences(of: "\"", with: "\"\"")
                let chaupaiMeaning = chaupai.chaupaiMeaning?.replacingOccurrences(of: "\"", with: "\"\"") ?? ""
                let prakaranId = chaupai.$prakaran.id.description
                
                let isLast = index == chaupais.count - 1
                return "(\(id),\(chaupai.chaupaiNumber),\"\(chaupaiName)\",\"\(chaupaiMeaning)\",\(prakaranId))\(isLast ? ";" : ",")"
            }
            
            sqlContent += chaupaiValues.joined(separator: "\n")
            sqlContent += "\n\n"
        }
        
        sqlContent += "-- Export completed\n"
        
        let response = Response()
        response.headers.contentType = .init(type: "application", subType: "sql")
        response.headers.add(name: .contentDisposition, value: "attachment; filename=\"complete_database.sql\"")
        response.body = .init(string: sqlContent)
        
        return response
    }
    
    // MARK: - Import Functionality
    
    func showImportForm(req: Request) async throws -> View {
        struct ImportContext: Encodable {
            let title = "Import Data"
            let error: String?
        }
        
        // Get and clear session error message
        let errorMessage = req.session.data["error"]
        req.session.data["error"] = nil
        
        let context = ImportContext(error: errorMessage)
        return try await req.view.render("admin/import", context)
    }
    
    func handleImport(req: Request) async throws -> Response {
        struct ImportRequest: Content {
            let sqlFile: File
        }
        
        let importRequest = try req.content.decode(ImportRequest.self)
        let sqlContent = String(buffer: importRequest.sqlFile.data)
        
        // Basic validation
        guard !sqlContent.isEmpty else {
            throw Abort(.badRequest, reason: "SQL file is empty")
        }
        
        do {
            try await importSQLData(sqlContent: sqlContent, db: req.db)
            
            req.session.data["success"] = "Data imported successfully!"
            return req.redirect(to: "/admin/dashboard")
            
        } catch {
            req.session.data["error"] = "Import failed: \(error.localizedDescription)"
            return req.redirect(to: "/admin/export/import")
        }
    }
    
    private func importSQLData(sqlContent: String, db: Database) async throws {
        // First, delete all existing data in the correct order (respecting foreign keys)
        try await deleteAllExistingData(db: db)
        
        // Then parse and execute INSERT statements
        let lines = sqlContent.components(separatedBy: .newlines)
        var currentStatement = ""
        
        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Skip comments and empty lines
            if trimmedLine.isEmpty || trimmedLine.hasPrefix("--") || trimmedLine.hasPrefix("DROP") || trimmedLine.hasPrefix("CREATE") {
                continue
            }
            
            currentStatement += trimmedLine + " "
            
            // Execute when we hit a semicolon
            if trimmedLine.hasSuffix(";") {
                let statement = currentStatement.trimmingCharacters(in: .whitespacesAndNewlines)
                if statement.hasPrefix("INSERT") {
                    do {
                        try await executeInsertStatement(statement, db: db)
                    } catch {
                        throw error
                    }
                }
                currentStatement = ""
            }
        }
    }
    
    private func deleteAllExistingData(db: Database) async throws {
        // Delete in reverse order of foreign key dependencies
        // Chaupais first (references prakarans)
        try await Chaupai.query(on: db).delete()
        
        // Prakarans second (references books)
        try await Prakaran.query(on: db).delete()
        
        // Books last (no dependencies)
        try await Book.query(on: db).delete()
    }
    
    private func executeInsertStatement(_ statement: String, db: Database) async throws {
        // Parse the INSERT statement and convert to model operations
        
        if statement.contains("INSERT INTO \"books\"") {
            try await importBooks(from: statement, db: db)
        } else if statement.contains("INSERT INTO \"prakarans\"") {
            try await importPrakarans(from: statement, db: db)
        } else if statement.contains("INSERT INTO \"chaupais\"") {
            try await importChaupais(from: statement, db: db)
        }
    }
    
    private func importBooks(from statement: String, db: Database) async throws {
        // Extract VALUES part
        guard let valuesRange = statement.range(of: "VALUES") else { return }
        let valuesString = String(statement[valuesRange.upperBound...])
        
        // Parse individual value tuples
        let valuesTuples = extractValueTuples(from: valuesString)
        
        for tuple in valuesTuples {
            let values = parseValues(from: tuple)
            if values.count >= 3 {
                let book = Book(
                    id: Int(values[0]) ?? nil,
                    bookOrder: Int(values[1]) ?? 1,
                    bookName: values[2]
                )
                try await book.save(on: db)
            }
        }
    }
    
    private func importPrakarans(from statement: String, db: Database) async throws {
        guard let valuesRange = statement.range(of: "VALUES") else { return }
        let valuesString = String(statement[valuesRange.upperBound...])
        
        let valuesTuples = extractValueTuples(from: valuesString)
        
        for tuple in valuesTuples {
            let values = parseValues(from: tuple)
            if values.count >= 4 { // At minimum need: prakaranID, prakaranOrder, prakaranName, bookID
                // Column order: prakaranID, prakaranOrder, prakaranName, bookID, prakaranDetails (optional)
                let bookID = Int(values[3]) ?? 1
                let bookExists = try await Book.find(bookID, on: db) != nil
                
                if !bookExists {
                    continue // Skip this prakaran if book doesn't exist
                }
                
                // Handle optional prakaranDetails
                let prakaranDetails: String?
                if values.count >= 5 && !values[4].isEmpty && values[4] != "NULL" {
                    prakaranDetails = values[4]
                } else {
                    prakaranDetails = nil
                }
                
                let prakaran = Prakaran(
                    id: Int(values[0]) ?? nil,
                    prakaranOrder: Int(values[1]) ?? 1,
                    prakaranName: values[2],
                    prakaranDetails: prakaranDetails,
                    bookID: bookID
                )
                try await prakaran.save(on: db)
            }
        }
    }
    
    private func importChaupais(from statement: String, db: Database) async throws {
        guard let valuesRange = statement.range(of: "VALUES") else { return }
        let valuesString = String(statement[valuesRange.upperBound...])
        
        let valuesTuples = extractValueTuples(from: valuesString)
        
        for tuple in valuesTuples {
            let values = parseValues(from: tuple)
            if values.count >= 5 {
                // Ensure the referenced prakaran exists before creating chaupai
                let prakaranID = Int(values[4]) ?? 1
                let prakaranExists = try await Prakaran.find(prakaranID, on: db) != nil
                
                if !prakaranExists {
                    continue // Skip this chaupai if prakaran doesn't exist
                }
                
                let chaupai = Chaupai(
                    id: Int(values[0]) ?? nil,
                    chaupaiNumber: Int(values[1]) ?? 1,
                    chaupaiName: values[2],
                    chaupaiMeaning: values[3].isEmpty ? nil : values[3],
                    prakaranID: prakaranID
                )
                try await chaupai.save(on: db)
            }
        }
    }
    
    private func extractValueTuples(from valuesString: String) -> [String] {
        var tuples: [String] = []
        var currentTuple = ""
        var parenCount = 0
        var inQuotes = false
        
        for char in valuesString {
            if char == "\"" && !inQuotes {
                inQuotes = true
            } else if char == "\"" && inQuotes {
                inQuotes = false
            } else if char == "(" && !inQuotes {
                parenCount += 1
                if parenCount == 1 {
                    currentTuple = ""
                    continue
                }
            } else if char == ")" && !inQuotes {
                parenCount -= 1
                if parenCount == 0 {
                    tuples.append(currentTuple)
                    continue
                }
            }
            
            if parenCount > 0 {
                currentTuple.append(char)
            }
        }
        
        return tuples
    }
    
    private func parseValues(from tuple: String) -> [String] {
        var values: [String] = []
        var currentValue = ""
        var inQuotes = false
        var escapeNext = false
        
        for char in tuple {
            if escapeNext {
                currentValue.append(char)
                escapeNext = false
            } else if char == "\"" && inQuotes {
                // Check if this is an escaped quote
                inQuotes = false
            } else if char == "\"" && !inQuotes {
                inQuotes = true
            } else if char == "," && !inQuotes {
                // Trim and remove quotes if they exist
                var value = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
                if value.hasPrefix("\"") && value.hasSuffix("\"") {
                    value = String(value.dropFirst().dropLast())
                    // Handle escaped quotes within the string
                    value = value.replacingOccurrences(of: "\"\"", with: "\"")
                }
                values.append(value)
                currentValue = ""
            } else {
                currentValue.append(char)
            }
        }
        
        // Add the last value
        if !currentValue.isEmpty {
            var value = currentValue.trimmingCharacters(in: .whitespacesAndNewlines)
            if value.hasPrefix("\"") && value.hasSuffix("\"") {
                value = String(value.dropFirst().dropLast())
                // Handle escaped quotes within the string
                value = value.replacingOccurrences(of: "\"\"", with: "\"")
            }
            values.append(value)
        }
        
        return values
    }
}
