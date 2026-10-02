import SwiftUI

public struct AlertsListView: View {
    @StateObject private var alertsVM = AlertsViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                BlazeTheme.background.ignoresSafeArea()
                
                if alertsVM.isLoading && alertsVM.alerts.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .tint(BlazeTheme.primary)
                        Text("Cargando alertas...")
                            .font(.system(size: 13))
                            .foregroundColor(BlazeTheme.textSecondary)
                    }
                } else if alertsVM.alerts.isEmpty {
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
                        ForEach(alertsVM.alerts) { alert in
                            AlertRow(alert: alert)
                                .listRowBackground(alert.read ? BlazeTheme.surface : BlazeTheme.surfaceElevated)
                                .listRowSeparatorTint(BlazeTheme.surfaceBorder)
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    if !alert.read {
                                        Button {
                                            alertsVM.markAsRead(alert: alert)
                                        } label: {
                                            Label("Leída", systemImage: "envelope.open.fill")
                                        }
                                        .tint(BlazeTheme.primary)
                                    }
                                }
                                .onTapGesture {
                                    if !alert.read {
                                        alertsVM.markAsRead(alert: alert)
                                    }
                                }
                        }
                    }
                    .scrollContentBackground(.hidden)
                    .refreshable {
                        await alertsVM.fetchAlerts()
                    }
                }
            }
            .navigationTitle("Centro de Alertas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await alertsVM.fetchAlerts() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(BlazeTheme.primary)
                    }
                }
            }
            .task {
                await alertsVM.fetchAlerts()
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
        case "billing": return Color.orange
        case "power_cut": return BlazeTheme.danger
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
        case "billing": return "creditcard.fill"
        default: return "bell.fill"
        }
    }
    
    private var formattedDate: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: alert.createdAt)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: alert.createdAt)
        }
        guard let d = date else { return alert.createdAt }
        
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        relative.locale = Locale(identifier: "es_DO")
        return relative.localizedString(for: d, relativeTo: Date())
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(alertColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: alertIcon)
                    .foregroundColor(alertColor)
                    .font(.system(size: 16, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(alert.title)
                        .font(.system(size: 14, weight: alert.read ? .semibold : .bold))
                        .foregroundColor(BlazeTheme.textPrimary)
                    
                    Spacer()
                    
                    if !alert.read {
                        Circle()
                            .fill(BlazeTheme.primary)
                            .frame(width: 7, height: 7)
                    }
                }
                
                Text(alert.body)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(BlazeTheme.textSecondary)
                    .lineLimit(3)
                
                Text(formattedDate)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(BlazeTheme.textMuted)
                    .padding(.top, 2)
            }
        }
        .padding(.vertical, 6)
    }
}
