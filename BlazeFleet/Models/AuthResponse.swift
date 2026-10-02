import Foundation

public struct UserDTO: Codable, Identifiable {
    public let id: String
    public let email: String
    public let fullName: String
    public let role: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case role
    }
}

public struct TenantDTO: Codable, Identifiable {
    public let id: String
    public let name: String
    public let slug: String
}

public struct LoginResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let refreshExpiresAt: String?
    public let user: UserDTO
    public let tenant: TenantDTO
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case refreshExpiresAt = "refresh_expires_at"
        case user
        case tenant
    }
}

public struct RefreshResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int
    public let refreshExpiresAt: String?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case refreshExpiresAt = "refresh_expires_at"
    }
}

public struct WSTicketResponse: Codable {
    public let ticket: String
    public let url: String
}
