import Foundation

struct Photo: Codable, Equatable {
    let id: String
    let width: Int
    let height: Int
    let color: String?
    let description: String?
    let altDescription: String?
    let urls: PhotoURLs
    let user: User
    
    enum CodingKeys: String, CodingKey {
        case id, width, height, color, description, urls, user
        case altDescription = "alt_description"
    }
}

struct PhotoURLs: Codable, Equatable {
    let raw: String
    let full: String
    let regular: String
    let small: String
    let thumb: String
}

struct User: Codable, Equatable {
    let id: String
    let username: String
    let name: String
    let profileImage: ProfileImage
    
    enum CodingKeys: String, CodingKey {
        case id, username, name
        case profileImage = "profile_image"
    }
}

struct ProfileImage: Codable, Equatable {
    let small: String
    let medium: String
    let large: String
}

struct PhotoResponse: Codable {
    let results: [Photo]
    let total: Int
    let totalPages: Int
    
    enum CodingKeys: String, CodingKey {
        case results, total
        case totalPages = "total_pages"
    }
}
