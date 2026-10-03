import Foundation
import Combine

@MainActor
public final class VehicleDetailViewModel: ObservableObject {
    @Published public var vehicle: MobileVehicleSummary
    @Published public var recentEvents: [EventItem] = []
    @Published public var isLoadingEvents = false
    @Published public var isExecutingCommand = false
    @Published public var commandSuccessMessage: String?
    @Published public var commandErrorMessage: String?
    @Published public var showCommandConfirmation = false
    @Published public var pendingCommand: String?
    
    private let api = APIClient.shared
    private let biometricAuth = BiometricAuthService.shared
    private var cancellables = Set<AnyCancellable>()
    
    public init(vehicle: MobileVehicleSummary) {
        self.vehicle = vehicle
        bindWebSocket()
    }
    
    public func fetchRecentEvents() async {
        guard !vehicle.vehicleId.isEmpty else { return }
        isLoadingEvents = true
        do {
            let events = try await api.getEvents(vehicleId: vehicle.vehicleId, limit: 15)
            self.recentEvents = events
        } catch {
            print("[Events] Error fetching events for vehicle \(vehicle.plate): \(error.localizedDescription)")
        }
        isLoadingEvents = false
    }
    
    private func bindWebSocket() {
        WebSocketService.shared.$positions
            .receive(on: DispatchQueue.main)
            .compactMap { [weak self] (dict: [String: LivePosition]) -> LivePosition? in
                guard let self = self else { return nil }
                return dict[self.vehicle.trackerId] ?? (self.vehicle.vehicleId.isEmpty ? nil : dict[self.vehicle.vehicleId])
            }
            .sink { [weak self] (update: LivePosition) in
                guard let self = self else { return }
                let newState = update.state ?? self.vehicle.state
                let newSpeed: Double?
                if let s = update.speedKmh {
                    newSpeed = s
                } else if newState == .stopped || newState == .idle {
                    newSpeed = 0.0
                } else {
                    newSpeed = self.vehicle.speedKmh
                }
                
                self.vehicle = MobileVehicleSummary(
                    vehicleId: self.vehicle.vehicleId.isEmpty ? (update.vehicleId ?? "") : self.vehicle.vehicleId,
                    trackerId: self.vehicle.trackerId.isEmpty ? update.trackerId : self.vehicle.trackerId,
                    plate: (update.plate?.isEmpty ?? true) ? self.vehicle.plate : update.plate!,
                    vehicleModel: (update.vehicleModel?.isEmpty ?? true) ? self.vehicle.vehicleModel : update.vehicleModel!,
                    driverName: update.driverName ?? self.vehicle.driverName,
                    driverPhone: self.vehicle.driverPhone,
                    state: newState,
                    time: update.time ?? self.vehicle.time,
                    lat: update.lat ?? self.vehicle.lat,
                    lng: update.lng ?? self.vehicle.lng,
                    speedKmh: newSpeed,
                    course: update.course ?? self.vehicle.course,
                    ignition: update.ignition ?? self.vehicle.ignition,
                    satellites: update.satellites ?? self.vehicle.satellites,
                    odometerKm: update.odometerKm ?? self.vehicle.odometerKm,
                    vehicleOdometerKm: update.vehicleOdometerKm ?? self.vehicle.vehicleOdometerKm,
                    batteryPct: self.vehicle.batteryPct,
                    speedLimitKmh: self.vehicle.speedLimitKmh,
                    currentGeofence: self.vehicle.currentGeofence,
                    todayAlertsCount: self.vehicle.todayAlertsCount
                )
            }
            .store(in: &cancellables)
    }
    
    public func promptCommand(command: String) {
        self.pendingCommand = command
        self.showCommandConfirmation = true
    }
    
    public func confirmAndExecuteCommand() async {
        guard let command = pendingCommand else { return }
        
        // If command is critical (engine shutoff), require biometric FaceID/TouchID
        if command == "engine_stop" {
            let authenticated = await biometricAuth.authenticateForSensitiveAction(
                reason: "Confirma con Face ID / Touch ID para apagar el motor remotamente"
            )
            guard authenticated else {
                self.commandErrorMessage = "Autenticación biométrica requerida para apagar motor."
                return
            }
        }
        
        isExecutingCommand = true
        commandErrorMessage = nil
        commandSuccessMessage = nil
        
        do {
            let resp = try await api.dispatchCommand(
                vehicleId: vehicle.vehicleId,
                command: command,
                reason: "Comando móvil desde app iOS"
            )
            self.commandSuccessMessage = "Comando '\(resp.command)' enviado exitosamente (ID: \(resp.commandId.prefix(8)))"
            // Re-fetch events after a command dispatch
            Task { await self.fetchRecentEvents() }
        } catch {
            self.commandErrorMessage = "Error ejecutando comando: \(error.localizedDescription)"
        }
        
        isExecutingCommand = false
        pendingCommand = nil
    }
    
    public func createShareLink(durationMinutes: Int = 120) async -> String? {
        do {
            let resp = try await api.createVehicleShareLink(vehicleId: vehicle.vehicleId, durationMinutes: durationMinutes)
            return resp.shareUrl
        } catch {
            self.commandErrorMessage = "Error generando enlace de rastreo: \(error.localizedDescription)"
            return nil
        }
    }
}
