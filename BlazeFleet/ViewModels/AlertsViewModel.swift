import Foundation
import Combine

@MainActor
public final class AlertsViewModel: ObservableObject {
    @Published public var selectedSegment = 0 // 0: Eventos GPS, 1: Alertas
    @Published public var notifications: [NotificationItem] = []
    @Published public var events: [EventItem] = []
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
            
            let (notifs, evs) = try await (notifTask, eventTask)
            self.notifications = notifs
            self.events = evs
        } catch {
            self.errorMessage = error.localizedDescription
            // If one fails, try events alone
            if let evs = try? await api.getEvents(limit: 30) {
                self.events = evs
            }
        }
        
        isLoading = false
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
