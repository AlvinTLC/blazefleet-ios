import Foundation

public struct UserDTO: Codable, Identifiable {
    public let id: String
    public let email: String
    public let fullName: String?
    public let locale: String?
    public let role: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case email
        case fullName = "full_name"
        case locale
        case role
    }
}

public struct TenantDTO: Codable, Identifiable {
    public var id: String { tenantId }
    public var name: String { tenantName }
    public var slug: String { tenantSlug ?? "" }
    public let tenantId: String
    public let tenantName: String
    public let tenantSlug: String?
    public let role: String?
    public let tenantStatus: String?
    
    enum CodingKeys: String, CodingKey {
        case tenantId = "tenant_id"
        case tenantName = "tenant_name"
        case tenantSlug = "tenant_slug"
        case role
        case tenantStatus = "tenant_status"
    }
}

public struct LoginResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String?
    public let expiresIn: Int?
    public let expiresAt: String?
    public let refreshExpiresAt: String?
    public let refreshExpiresIn: Int?
    public let user: UserDTO
    public let tenants: [TenantDTO]
    
    public var tenant: TenantDTO? {
        tenants.first
    }
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case refreshExpiresAt = "refresh_expires_at"
        case refreshExpiresIn = "refresh_expires_in"
        case user
        case tenants
    }
}

public struct RefreshResponse: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let tokenType: String?
    public let expiresIn: Int?
    public let expiresAt: String?
    public let refreshExpiresAt: String?
    public let refreshExpiresIn: Int?
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case expiresAt = "expires_at"
        case refreshExpiresAt = "refresh_expires_at"
        case refreshExpiresIn = "refresh_expires_in"
    }
}

public struct WSTicketResponse: Codable {
    public let ticket: String
    public let url: String
}
