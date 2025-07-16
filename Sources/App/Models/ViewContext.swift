import Vapor

struct ChaupaisContext: Encodable {
    let chaupais: [Chaupai]
    let books: [Book]
    let prakarans: [Prakaran]
    let selectedBookID: Int?
    let selectedPrakaranID: Int?
    let selectedFavourite: Bool?
    let search: String?
    let enableAddDelete: Bool
    
    init(
        chaupais: [Chaupai],
        books: [Book],
        prakarans: [Prakaran],
        selectedBookID: Int?,
        selectedPrakaranID: Int?,
        selectedFavourite: Bool?,
        search: String?,
        enableAddDelete: Bool = AdminConfig.enableAddDelete
    ) {
        self.chaupais = chaupais
        self.books = books
        self.prakarans = prakarans
        self.selectedBookID = selectedBookID
        self.selectedPrakaranID = selectedPrakaranID
        self.selectedFavourite = selectedFavourite
        self.search = search
        self.enableAddDelete = enableAddDelete
    }
}
