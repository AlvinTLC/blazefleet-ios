import Foundation

public enum APIError: LocalizedError {
    case invalidURL
    case unauthorized
    case serverError(Int, String)
    case decodingError(Error)
    case networkError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL: return "URL del servidor inválida"
        case .unauthorized: return "Sesión expirada o credenciales incorrectas"
        case .serverError(let code, let msg):
            if code == 401 {
                return "Credenciales incorrectas. Verifica tu correo y contraseña."
            }
            return "Error del servidor (\(code)): \(msg)"
        case .decodingError(let err): return "Error en formato de datos: \(err.localizedDescription)"
        case .networkError(let err): return "Error de red: \(err.localizedDescription)"
        }
    }
}

public final class APIClient: ObservableObject {
    public static let shared = APIClient()
    
    @Published public var baseURL: String {
        didSet {
            UserDefaults.standard.set(baseURL, forKey: "bf_base_url")
        }
    }
    
    private let session: URLSession
    private let keychain = KeychainManager.shared
    private var isRefreshing = false
    private var refreshTasks: [CheckedContinuation<Void, Error>] = []
    
    private init() {
        let storedURL = UserDefaults.standard.string(forKey: "bf_base_url")
        self.baseURL = storedURL ?? "https://fleet.blaze.do"
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15
        config.timeoutIntervalForResource = 30
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Auth Methods
    
    public func login(email: String, password: String) async throws -> LoginResponse {
        let endpoint = "\(baseURL)/api/v1/auth/login"
        guard let url = URL(string: endpoint) else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["email": email, "password": password]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.networkError(URLError(.badServerResponse)) }
        
        if httpResponse.statusCode == 200 {
            do {
                let decoded = try JSONDecoder().decode(LoginResponse.self, from: data)
                keychain.save(key: "access_token", value: decoded.accessToken)
                keychain.save(key: "refresh_token", value: decoded.refreshToken)
                if let tenantId = decoded.tenant?.tenantId {
                    keychain.save(key: "tenant_id", value: tenantId)
                }
                keychain.save(key: "user_email", value: decoded.user.email)
                return decoded
            } catch {
                let raw = String(data: data, encoding: .utf8) ?? "N/A"
                print("[Auth] Decoding LoginResponse error: \(error). Raw: \(raw)")
                throw APIError.decodingError(error)
            }
        } else {
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let detail = json["detail"] as? String {
                throw APIError.serverError(httpResponse.statusCode, detail)
            }
            let errorMsg = String(data: data, encoding: .utf8) ?? "Error en login"
            throw APIError.serverError(httpResponse.statusCode, errorMsg)
        }
    }
    
    public func refreshToken() async throws {
        guard let currentRefresh = keychain.get(key: "refresh_token") else {
            throw APIError.unauthorized
        }
        
        let endpoint = "\(baseURL)/api/v1/auth/refresh"
        guard let url = URL(string: endpoint) else { throw APIError.invalidURL }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["refresh_token": currentRefresh]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await session.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw APIError.unauthorized }
        
        if httpResponse.statusCode == 200 {
            let decoded = try JSONDecoder().decode(RefreshResponse.self, from: data)
            keychain.save(key: "access_token", value: decoded.accessToken)
            keychain.save(key: "refresh_token", value: decoded.refreshToken)
        } else {
            keychain.clearAll()
            throw APIError.unauthorized
        }
    }
    
    // MARK: - Authenticated Request Helper
    
    public func request<T: Decodable>(path: String, method: String = "GET", body: Data? = nil) async throws -> T {
        guard let token = keychain.get(key: "access_token") else {
            throw APIError.unauthorized
        }
        guard let url = URL(string: "\(baseURL)\(path)") else {
            throw APIError.invalidURL
        }
        
        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("BlazeFleet-iOS/1.0", forHTTPHeaderField: "User-Agent")
        req.httpBody = body
        
        let (data, response) = try await session.data(for: req)
        guard let http = response as? HTTPURLResponse else {
            throw APIError.networkError(URLError(.badServerResponse))
        }
        
        if http.statusCode == 401 {
            // Attempt automatic token refresh with 60s grace window
            try await refreshToken()
            return try await request(path: path, method: method, body: body)
        }
        
        guard (200...299).contains(http.statusCode) else {
            let msg = String(data: data, encoding: .utf8) ?? "HTTP Error"
            throw APIError.serverError(http.statusCode, msg)
        }
        
        if data.isEmpty, let empty = () as? T {
            return empty
        }
        
        return try JSONDecoder().decode(T.self, from: data)
    }
    
    // MARK: - Mobile Specific Endpoints
    
    public func getMobileFleetSummary() async throws -> FleetSummaryResponse {
        return try await request(path: "/api/v1/mobile/fleet-summary")
    }
    
    public func getMobileConfig() async throws -> MobileConfigResponse {
        return try await request(path: "/api/v1/mobile/config")
    }
    
    public func registerPushToken(token: String, deviceName: String, appVersion: String) async throws {
        let payload: [String: Any] = [
            "platform": "ios",
            "token": token,
            "device_name": deviceName,
            "app_version": appVersion
        ]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let _: Data = try await request(path: "/api/v1/mobile/push-token", method: "POST", body: body)
    }
    
    public func unregisterPushToken(token: String) async throws {
        let payload = ["token": token]
        let body = try JSONSerialization.data(withJSONObject: payload)
        let _: Data = try await request(path: "/api/v1/mobile/push-token", method: "DELETE", body: body)
    }
    
    public func dispatchCommand(vehicleId: String, command: String, reason: String? = nil) async throws -> RemoteCommandResponse {
        var payload: [String: Any] = ["command": command]
        if let reason = reason {
            payload["reason"] = reason
        }
        let body = try JSONSerialization.data(withJSONObject: payload)
        return try await request(path: "/api/v1/mobile/vehicles/\(vehicleId)/command", method: "POST", body: body)
    }
    
    public func getWSTicket() async throws -> WSTicketResponse {
        return try await request(path: "/api/v1/ws-ticket", method: "POST")
    }
}
