import Foundation
import UserNotifications
import UIKit

public final class PushNotificationManager: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    public static let shared = PushNotificationManager()
    
    @Published public var deviceTokenString: String?
    @Published public var hasPermission = false
    
    private override init() {
        super.init()
    }
    
    public func requestAuthorization() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { [weak self] granted, _ in
            DispatchQueue.main.async {
                self?.hasPermission = granted
                if granted {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    public func handleDeviceTokenRegistration(deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        self.deviceTokenString = token
        
        let deviceName = UIDevice.current.name
        let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        
        Task {
            do {
                try await APIClient.shared.registerPushToken(token: token, deviceName: deviceName, appVersion: appVersion)
                print("[Push] Successfully registered APNs token with BlazeFleet backend")
            } catch {
                print("[Push] Failed to register token: \(error.localizedDescription)")
            }
        }
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show banner even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let vehicleId = userInfo["entity_id"] as? String {
            NotificationCenter.default.post(name: Notification.Name("OpenVehicleDetail"), object: vehicleId)
        }
        completionHandler()
    }
}
