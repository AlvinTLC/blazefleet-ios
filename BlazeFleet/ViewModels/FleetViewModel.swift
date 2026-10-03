import Foundation
import Combine
import CoreLocation

public enum FleetFilter: String, CaseIterable, Identifiable {
    case all = "Todos"
    case moving = "En movimiento"
    case idle = "En ralentí"
    case stopped = "Detenidos"
    case offline = "Sin señal"
    
    public var id: String { rawValue }
}

@MainActor
public final class FleetViewModel: ObservableObject {
    @Published public var vehicles: [MobileVehicleSummary] = []
    @Published public var counts: FleetSummaryCounts?
    @Published public var selectedFilter: FleetFilter = .all
    @Published public var searchQuery = ""
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var activeAlertsCount = 0
    @Published public var lastUpdated: Date?
    
    private let api = APIClient.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        setupWebSocketBinding()
    }
    
    public var filteredVehicles: [MobileVehicleSummary] {
        vehicles.filter { v in
            let matchesFilter: Bool
            switch selectedFilter {
            case .all: matchesFilter = true
            case .moving: matchesFilter = v.state == .moving
            case .idle: matchesFilter = v.state == .idle
            case .stopped: matchesFilter = v.state == .stopped
            case .offline: matchesFilter = v.state == .offline
            }
            
            guard matchesFilter else { return false }
            
            if searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return true
            }
            
            let query = searchQuery.lowercased()
            let plateMatches = v.plate.lowercased().contains(query)
            let modelMatches = v.vehicleModel.lowercased().contains(query)
            let driverMatches = v.driverName?.lowercased().contains(query) ?? false
            return plateMatches || modelMatches || driverMatches
        }
    }
    
    public func fetchSummary() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let summary = try await api.getMobileFleetSummary()
            self.vehicles = summary.vehicles
            self.counts = summary.counts
            self.activeAlertsCount = summary.activeAlertsCount
            self.lastUpdated = Date()
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    private func setupWebSocketBinding() {
        WebSocketService.shared.$positions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] liveMap in
                guard let self = self, !liveMap.isEmpty else { return }
                self.mergeLivePositions(liveMap)
            }
            .store(in: &cancellables)
    }
    
    private func mergeLivePositions(_ liveMap: [String: LivePosition]) {
        var updatedList = self.vehicles
        var hasChanges = false
        
        for (index, v) in updatedList.enumerated() {
            let update = liveMap[v.trackerId] ?? (v.vehicleId.isEmpty ? nil : liveMap[v.vehicleId])
            if let update = update {
                let newState = update.state ?? v.state
                
                let newSpeed: Double?
                if let s = update.speedKmh {
                    newSpeed = s
                } else if newState == .stopped || newState == .idle {
                    newSpeed = 0.0
                } else {
                    newSpeed = v.speedKmh
                }
                
                let updated = MobileVehicleSummary(
                    vehicleId: v.vehicleId.isEmpty ? (update.vehicleId ?? "") : v.vehicleId,
                    trackerId: v.trackerId.isEmpty ? update.trackerId : v.trackerId,
                    plate: (update.plate?.isEmpty ?? true) ? v.plate : update.plate!,
                    vehicleModel: (update.vehicleModel?.isEmpty ?? true) ? v.vehicleModel : update.vehicleModel!,
                    driverName: update.driverName ?? v.driverName,
                    driverPhone: v.driverPhone,
                    state: newState,
                    time: update.time ?? v.time,
                    lat: update.lat ?? v.lat,
                    lng: update.lng ?? v.lng,
                    speedKmh: newSpeed,
                    course: update.course ?? v.course,
                    ignition: update.ignition ?? v.ignition,
                    satellites: update.satellites ?? v.satellites,
                    odometerKm: update.odometerKm ?? v.odometerKm,
                    vehicleOdometerKm: update.vehicleOdometerKm ?? v.vehicleOdometerKm,
                    batteryPct: v.batteryPct
                )
                updatedList[index] = updated
                hasChanges = true
            }
        }
        
        if hasChanges {
            self.vehicles = updatedList
            self.lastUpdated = Date()
            
            let moving = updatedList.filter { $0.state == .moving }.count
            let idle = updatedList.filter { $0.state == .idle }.count
            let stopped = updatedList.filter { $0.state == .stopped }.count
            let offline = updatedList.filter { $0.state == .offline }.count
            let sos = updatedList.filter { $0.state == .sos }.count
            self.counts = FleetSummaryCounts(
                total: updatedList.count,
                moving: moving,
                idle: idle,
                stopped: stopped,
                offline: offline,
                sos: sos
            )
        }
    }
}
