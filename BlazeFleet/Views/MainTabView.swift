import SwiftUI

public struct MainTabView: View {
    @ObservedObject var authVM: AuthViewModel
    @StateObject private var fleetVM = FleetViewModel()
    @State private var selectedTab = 0
    
    public init(authVM: AuthViewModel) {
        self.authVM = authVM
    }
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            LiveMapView(fleetVM: fleetVM)
                .tabItem {
                    Label("Mapa en Vivo", systemImage: "map.fill")
                }
                .tag(0)
            
            FleetListView(fleetVM: fleetVM)
                .tabItem {
                    Label("Flota", systemImage: "car.2.fill")
                }
                .tag(1)
            
            AlertsListView()
                .tabItem {
                    Label("Alertas", systemImage: "bell.fill")
                }
                .badge(fleetVM.activeAlertsCount > 0 ? "\(fleetVM.activeAlertsCount)" : nil)
                .tag(2)
            
            SettingsView(authVM: authVM)
                .tabItem {
                    Label("Ajustes", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(BlazeTheme.primary)
    }
}

struct SettingsView: View {
    @ObservedObject var authVM: AuthViewModel
    
    var body: some View {
        NavigationStack {
            ZStack {
                BlazeTheme.background.ignoresSafeArea()
                
                List {
                    Section("Sesión Actual") {
                        HStack {
                            Text("Correo")
                                .foregroundColor(BlazeTheme.textSecondary)
                            Spacer()
                            Text(authVM.currentUser?.email ?? "—")
                                .foregroundColor(BlazeTheme.textPrimary)
                        }
                        HStack {
                            Text("Empresa / Tenant")
                                .foregroundColor(BlazeTheme.textSecondary)
                            Spacer()
                            Text(authVM.currentTenant?.name ?? "—")
                                .foregroundColor(BlazeTheme.textPrimary)
                        }
                    }
                    .listRowBackground(BlazeTheme.surface)
                    
                    Section("Conexión Satelital") {
                        HStack {
                            Text("Servidor API")
                                .foregroundColor(BlazeTheme.textSecondary)
                            Spacer()
                            Text(APIClient.shared.baseURL)
                                .font(.system(size: 13, design: .monospaced))
                                .foregroundColor(BlazeTheme.primary)
                        }
                        HStack {
                            Text("WebSocket Live Stream")
                                .foregroundColor(BlazeTheme.textSecondary)
                            Spacer()
                            HStack(spacing: 6) {
                                Circle()
                                    .fill(WebSocketService.shared.isConnected ? BlazeTheme.moving : BlazeTheme.danger)
                                    .frame(width: 8, height: 8)
                                Text(WebSocketService.shared.isConnected ? "Conectado" : "Desconectado")
                                    .foregroundColor(WebSocketService.shared.isConnected ? BlazeTheme.moving : BlazeTheme.danger)
                            }
                        }
                        if !WebSocketService.shared.isConnected {
                            Button {
                                WebSocketService.shared.connect()
                            } label: {
                                HStack {
                                    Image(systemName: "arrow.triangle.2.circlepath")
                                    Text("Reconectar ahora")
                                }
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(BlazeTheme.primary)
                            }
                        }
                    }
                    .listRowBackground(BlazeTheme.surface)
                    
                    Section("Acerca de") {
                        HStack {
                            Text("Versión de la App")
                                .foregroundColor(BlazeTheme.textSecondary)
                            Spacer()
                            Text("\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0") (\(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"))")
                                .foregroundColor(BlazeTheme.textPrimary)
                        }
                        HStack {
                            Text("Notificaciones Push")
                                .foregroundColor(BlazeTheme.textSecondary)
                            Spacer()
                            Text(PushNotificationManager.shared.hasPermission ? "Activas" : "Inactivas")
                                .foregroundColor(PushNotificationManager.shared.hasPermission ? BlazeTheme.moving : BlazeTheme.textMuted)
                        }
                    }
                    .listRowBackground(BlazeTheme.surface)
                    
                    Section {
                        Button(role: .destructive) {
                            authVM.logout()
                        } label: {
                            HStack {
                                Spacer()
                                Text("Cerrar Sesión")
                                    .fontWeight(.bold)
                                Spacer()
                            }
                        }
                    }
                    .listRowBackground(BlazeTheme.surface)
                }
                .scrollContentBackground(.hidden)
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
