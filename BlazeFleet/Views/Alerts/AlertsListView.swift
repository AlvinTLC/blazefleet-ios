import SwiftUI

public struct AlertsListView: View {
    @ObservedObject var wsService = WebSocketService.shared
    @State private var alerts: [NotificationItem] = []
    @State private var isLoading = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                BlazeTheme.background.ignoresSafeArea()
                
                if alerts.isEmpty && !isLoading {
                    VStack(spacing: 12) {
                        Image(systemName: "bell.slash.fill")
                            .font(.system(size: 48))
                            .foregroundColor(BlazeTheme.textMuted)
                        Text("No hay alertas recientes")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(BlazeTheme.textSecondary)
                        Text("Las notificaciones de pánico, geocercas y batería aparecerán aquí.")
                            .font(.system(size: 13))
                            .foregroundColor(BlazeTheme.textMuted)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 32)
                    }
                } else {
                    List {
                        ForEach(alerts) { alert in
                            AlertRow(alert: alert)
                                .listRowBackground(BlazeTheme.surface)
                                .listRowSeparatorTint(BlazeTheme.surfaceBorder)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Centro de Alertas")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(wsService.$latestAlert) { newAlert in
                if let alert = newAlert {
                    withAnimation {
                        alerts.insert(alert, at: 0)
                    }
                }
            }
        }
    }
}

struct AlertRow: View {
    let alert: NotificationItem
    
    private var alertColor: Color {
        switch alert.kind {
        case "sos", "panic": return BlazeTheme.danger
        case "geofence_enter", "geofence_exit": return BlazeTheme.primary
        case "speeding": return BlazeTheme.idle
        default: return BlazeTheme.secondary
        }
    }
    
    private var alertIcon: String {
        switch alert.kind {
        case "sos", "panic": return "exclamationmark.octagon.fill"
        case "geofence_enter": return "arrow.down.right.and.arrow.up.left"
        case "geofence_exit": return "arrow.up.left.and.arrow.down.right"
        case "speeding": return "speedometer"
        case "low_battery": return "battery.25"
        case "power_cut": return "powercord.fill"
        default: return "bell.fill"
        }
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(alertColor.opacity(0.15))
                    .frame(width: 38, height: 38)
                Image(systemName: alertIcon)
                    .foregroundColor(alertColor)
                    .font(.system(size: 16, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(alert.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(BlazeTheme.textPrimary)
                
                Text(alert.body)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BlazeTheme.textSecondary)
                    .lineLimit(2)
                
                Text(alert.createdAt)
                    .font(.system(size: 10))
                    .foregroundColor(BlazeTheme.textMuted)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}
