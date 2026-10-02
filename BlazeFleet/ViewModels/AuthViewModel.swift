import Foundation
import Combine

@MainActor
public final class AuthViewModel: ObservableObject {
    @Published public var email = ""
    @Published public var password = ""
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var isAuthenticated = false
    @Published public var currentUser: UserDTO?
    @Published public var currentTenant: TenantDTO?
    
    private let api = APIClient.shared
    private let keychain = KeychainManager.shared
    
    public init() {
        checkExistingSession()
    }
    
    public func checkExistingSession() {
        if keychain.get(key: "access_token") != nil {
            self.isAuthenticated = true
        }
    }
    
    public func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            self.errorMessage = "Por favor ingresa correo y contraseña"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let resp = try await api.login(email: email, password: password)
            self.currentUser = resp.user
            self.currentTenant = resp.tenant
            self.isAuthenticated = true
            WebSocketService.shared.connect()
            PushNotificationManager.shared.requestAuthorization()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func logout() {
        WebSocketService.shared.disconnect()
        if let token = PushNotificationManager.shared.deviceTokenString {
            Task {
                try? await api.unregisterPushToken(token: token)
            }
        }
        keychain.clearAll()
        self.isAuthenticated = false
        self.currentUser = nil
        self.currentTenant = nil
    }
}
