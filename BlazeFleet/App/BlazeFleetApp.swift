import SwiftUI

@main
struct BlazeFleetApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var authVM = AuthViewModel()
    
    init() {
        // Configure dark navigation bar appearance matching BlazeTheme
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(BlazeTheme.surface)
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        
        // Configure tab bar appearance
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(BlazeTheme.surface)
        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance
    }
    
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            Group {
                if authVM.isAuthenticated {
                    MainTabView(authVM: authVM)
                } else {
                    LoginView(authVM: authVM)
                }
            }
            .preferredColorScheme(.dark)
            .onChange(of: scenePhase) { oldPhase, newPhase in
                if newPhase == .active && authVM.isAuthenticated {
                    if !WebSocketService.shared.isConnected {
                        WebSocketService.shared.connect()
                    }
                }
            }
        }
    }
}
