import Foundation

struct Photo: Codable, Equatable {
    let id: String
    let width: Int
    let height: Int
    let description: String?
    let altDescription: String?
    let urls: PhotoURLs
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case id, width, height, description, urls, user
        case altDescription = "alt_description"
    }
}

struct PhotoURLs: Codable, Equatable {
    let regular: String
    let small: String
}

struct User: Codable, Equatable {
    let name: String
}

struct PhotoResponse: Codable {
    let results: [Photo]
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case results
        case totalPages = "total_pages"
    }
}
