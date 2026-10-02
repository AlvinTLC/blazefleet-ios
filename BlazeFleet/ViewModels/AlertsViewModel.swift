import Foundation
import Combine

@MainActor
public final class AlertsViewModel: ObservableObject {
    @Published public var alerts: [NotificationItem] = []
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    private let api = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupWebSocketBinding()
    }
    
    public func fetchAlerts() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let items = try await api.getNotifications(limit: 50)
            self.alerts = items
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    public func markAsRead(alert: NotificationItem) {
        guard let index = alerts.firstIndex(where: { $0.id == alert.id }), !alerts[index].read else { return }
        
        alerts[index].read = true
        
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
                // Avoid duplicate if already received
                if !self.alerts.contains(where: { $0.id == newAlert.id }) {
                    self.alerts.insert(newAlert, at: 0)
                }
            }
            .store(in: &cancellables)
    }
}
