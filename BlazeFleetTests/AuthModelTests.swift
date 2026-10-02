import XCTest
@testable import BlazeFleet

final class AuthModelTests: XCTestCase {
    
    func testLoginResponseDecoding() throws {
        let json = """
        {
          "access_token": "eyJhbGciOiJIUzI1NiIs...",
          "refresh_token": "eyJhbGciOiJIUzI1NiIsIn...",
          "token_type": "Bearer",
          "expires_in": 900,
          "expires_at": "2026-10-02T16:11:47Z",
          "refresh_expires_at": "2026-11-01T16:11:47Z",
          "refresh_expires_in": 2592000,
          "user": {
            "id": "019ed69f-bd4d-72e3-b0f7-67c5fa6cd5b5",
            "email": "owner@demo.do",
            "full_name": "Demo Admin",
            "locale": "es"
          },
          "tenants": [
            {
              "tenant_id": "019ed69f-bd4d-72e3-b0f7-67c5fa6cd5b5",
              "tenant_name": "Demo Transport SRL",
              "tenant_slug": "demo-transport",
              "role": "owner",
              "tenant_status": "active"
            }
          ]
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(LoginResponse.self, from: json)
        
        XCTAssertEqual(response.accessToken, "eyJhbGciOiJIUzI1NiIs...")
        XCTAssertEqual(response.user.email, "owner@demo.do")
        XCTAssertEqual(response.user.fullName, "Demo Admin")
        XCTAssertEqual(response.tenants.count, 1)
        XCTAssertEqual(response.tenant?.tenantName, "Demo Transport SRL")
        XCTAssertEqual(response.tenant?.role, "owner")
    }
    
    func testRefreshResponseDecoding() throws {
        let json = """
        {
          "access_token": "new-access-token",
          "refresh_token": "new-refresh-token",
          "token_type": "Bearer",
          "expires_in": 900
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(RefreshResponse.self, from: json)
        XCTAssertEqual(response.accessToken, "new-access-token")
        XCTAssertEqual(response.refreshToken, "new-refresh-token")
        XCTAssertEqual(response.expiresIn, 900)
    }
    
    func testWSTicketResponseDecoding() throws {
        let json = """
        {
          "ticket": "f5edd40d-6b7f-499b-ad35-12ce4bc0283c",
          "url": "/ws/v1/live?ticket=f5edd40d-6b7f-499b-ad35-12ce4bc0283c"
        }
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(WSTicketResponse.self, from: json)
        XCTAssertEqual(response.ticket, "f5edd40d-6b7f-499b-ad35-12ce4bc0283c")
        XCTAssertTrue(response.url.contains("ticket="))
    }
}
