import SwiftUI

public struct AlertsListView: View {
    @StateObject private var alertsVM = AlertsViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ZStack {
                BlazeTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segment Selector
                    Picker("Vista", selection: $alertsVM.selectedSegment) {
                        Text("Eventos GPS (\(alertsVM.events.count))").tag(0)
                        Text("Alertas (\(alertsVM.notifications.count))").tag(1)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(BlazeTheme.surface)
                    
                    if alertsVM.isLoading && alertsVM.events.isEmpty && alertsVM.notifications.isEmpty {
                        Spacer()
                        VStack(spacing: 12) {
                            ProgressView()
                                .tint(BlazeTheme.primary)
                            Text("Cargando actividad de la flota...")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(BlazeTheme.textSecondary)
                        }
                        Spacer()
                    } else if alertsVM.selectedSegment == 0 {
                        // GPS Events List
                        if alertsVM.events.isEmpty {
                            emptyEventsView
                        } else {
                            List {
                                ForEach(alertsVM.events) { event in
                                    EventRow(event: event)
                                        .listRowBackground(BlazeTheme.surface)
                                        .listRowSeparatorTint(BlazeTheme.surfaceBorder)
                                }
                            }
                            .scrollContentBackground(.hidden)
                            .refreshable {
                                await alertsVM.fetchAll()
                            }
                        }
                    } else {
                        // Notifications / System Alerts List
                        if alertsVM.notifications.isEmpty {
                            emptyNotificationsView
                        } else {
                            List {
                                ForEach(alertsVM.notifications) { alert in
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
                                await alertsVM.fetchAll()
                            }
                        }
                    }
                }
            }
            .navigationTitle("Centro de Alertas")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await alertsVM.fetchAll() }
                    } label: {
                        if alertsVM.isLoading {
                            ProgressView()
                                .controlSize(.small)
                                .tint(BlazeTheme.primary)
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(BlazeTheme.primary)
                        }
                    }
                }
            }
            .task {
                await alertsVM.fetchAll()
            }
        }
    }
    
    private var emptyEventsView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "antenna.radiowaves.left.and.right.slash")
                .font(.system(size: 48))
                .foregroundColor(BlazeTheme.textMuted)
            Text("Sin eventos telemáticos recientes")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(BlazeTheme.textSecondary)
            Text("Las igniciones, paradas y novedades de los vehículos aparecerán aquí.")
                .font(.system(size: 13))
                .foregroundColor(BlazeTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
    
    private var emptyNotificationsView: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bell.slash.fill")
                .font(.system(size: 48))
                .foregroundColor(BlazeTheme.textMuted)
            Text("No hay alertas pendientes")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(BlazeTheme.textSecondary)
            Text("Las notificaciones de pánico SOS, exceso de velocidad y desconexión de batería aparecerán aquí.")
                .font(.system(size: 13))
                .foregroundColor(BlazeTheme.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }
}

struct EventRow: View {
    let event: EventItem
    
    private var eventColor: Color {
        switch event.kind {
        case "ignition_on": return BlazeTheme.moving
        case "ignition_off": return BlazeTheme.idle
        case "power_cut": return BlazeTheme.danger
        case "power_restored": return BlazeTheme.moving
        case "speeding": return Color.orange
        case "panic", "sos": return BlazeTheme.danger
        default: return BlazeTheme.primary
        }
    }
    
    private var formattedTime: String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = formatter.date(from: event.time)
        if date == nil {
            formatter.formatOptions = [.withInternetDateTime]
            date = formatter.date(from: event.time)
        }
        guard let d = date else { return event.time }
        
        let relative = RelativeDateTimeFormatter()
        relative.unitsStyle = .abbreviated
        relative.locale = Locale(identifier: "es_DO")
        return relative.localizedString(for: d, relativeTo: Date())
    }
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(eventColor.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: event.iconName)
                    .foregroundColor(eventColor)
                    .font(.system(size: 16, weight: .semibold))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.displayName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(BlazeTheme.textPrimary)
                    
                    Spacer()
                    
                    Text(formattedTime)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BlazeTheme.textMuted)
                }
                
                HStack(spacing: 6) {
                    if let plate = event.plate, !plate.isEmpty {
                        Text(plate)
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(BlazeTheme.surfaceElevated)
                            .foregroundColor(BlazeTheme.textPrimary)
                            .cornerRadius(4)
                    }
                    
                    Text(event.kind)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(BlazeTheme.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
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
