import Foundation
import LocalAuthentication

public final class BiometricAuthService {
    public static let shared = BiometricAuthService()
    
    private init() {}
    
    public func authenticateForSensitiveAction(reason: String = "Confirma tu identidad para ejecutar este comando remoto") async -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            return true // Fallback if device has no biometrics set up
        }
        
        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
