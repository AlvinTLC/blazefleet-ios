import Foundation
import Combine

@MainActor
public final class AlertsViewModel: ObservableObject {
    @Published public var selectedSegment = 0 // 0: Eventos GPS, 1: Alertas
    @Published public var notifications: [NotificationItem] = []
    @Published public var events: [EventItem] = []
    @Published public var mobileAlerts: [MobileAlertItem] = []
    @Published public var alertCounts: MobileAlertCounts?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    private let api = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupWebSocketBinding()
    }
    
    public func fetchAll() async {
        isLoading = true
        errorMessage = nil
        
        do {
            async let notifTask = api.getNotifications(limit: 50)
            async let eventTask = api.getEvents(limit: 40)
            async let mobileAlertsTask = api.getMobileAlerts(limit: 50)
            
            let (notifs, evs, mAlerts) = try await (notifTask, eventTask, mobileAlertsTask)
            self.notifications = notifs
            self.events = evs
            self.mobileAlerts = mAlerts.items
            self.alertCounts = mAlerts.counts
        } catch {
            self.errorMessage = error.localizedDescription
            // If one fails, try events and mobile alerts
            if let evs = try? await api.getEvents(limit: 30) {
                self.events = evs
            }
            if let mAlerts = try? await api.getMobileAlerts(limit: 30) {
                self.mobileAlerts = mAlerts.items
                self.alertCounts = mAlerts.counts
            }
        }
        
        isLoading = false
    }
    
    public func acknowledgeAlert(id: String, note: String = "Atendida desde app iOS") async {
        do {
            try await api.acknowledgeAlert(id: id, note: note)
            if let index = mobileAlerts.firstIndex(where: { $0.id == id }) {
                let old = mobileAlerts[index]
                mobileAlerts[index] = MobileAlertItem(
                    id: old.id,
                    kind: old.kind,
                    title: old.title,
                    body: old.body,
                    severity: old.severity,
                    vehicleId: old.vehicleId,
                    plate: old.plate,
                    vehicleModel: old.vehicleModel,
                    geofenceId: old.geofenceId,
                    geofenceName: old.geofenceName,
                    speedKmh: old.speedKmh,
                    speedLimitKmh: old.speedLimitKmh,
                    time: old.time,
                    acknowledged: true,
                    acknowledgedAt: ISO8601DateFormatter().string(from: Date()),
                    ackNote: note
                )
            }
        } catch {
            // handle error
        }
    }
    
    public func markAsRead(alert: NotificationItem) {
        guard let index = notifications.firstIndex(where: { $0.id == alert.id }), !notifications[index].read else { return }
        
        notifications[index].read = true
        
        Task {
            try? await api.markNotificationRead(id: alert.id)
        }
    }
    
    private func setupWebSocketBinding() {
        WebSocketService.shared.$latestAlert
            .receive(on: DispatchQueue.main)
            .compactMap { $0 }
            .sink { [weak self] newAlert in
                guard let self = self else { return }
                if !self.notifications.contains(where: { $0.id == newAlert.id }) {
                    self.notifications.insert(newAlert, at: 0)
                }
            }
            .store(in: &cancellables)
    }
}
